-- Content preferences complement account blocks without inventing editorial accounts.
alter table public.cooking_videos add column owner_id uuid references public.profiles(id) on delete cascade;
create index cooking_videos_owner_idx on public.cooking_videos(owner_id);
create table public.content_hides (
    user_id uuid not null references public.profiles(id) on delete cascade,
    kind text not null check (kind in ('recipe','video')),
    content_id text not null,
    created_at timestamptz not null default now(),
    primary key (user_id, kind, content_id)
);
alter table public.content_hides enable row level security;
revoke all on public.content_hides from public, anon, authenticated;
grant select on public.content_hides to authenticated;
create policy content_hides_read_own on public.content_hides for select to authenticated
    using (user_id=(select auth.uid()));

create or replace function private.recipe_visible(content text,viewer uuid) returns boolean
language sql stable security definer set search_path='' as $$
select exists(select 1 from public.recipes r where r.id=content and (r.published or r.owner_id=viewer)
    and (r.owner_id is null or private.not_blocked(viewer,r.owner_id))
    and not exists(select 1 from public.content_hides h where h.user_id=viewer and h.kind='recipe' and h.content_id=r.id));
$$;
create function private.video_visible(content text,viewer uuid) returns boolean
language sql stable security definer set search_path='' as $$
select exists(select 1 from public.cooking_videos v where v.id=content and v.published
    and (v.owner_id is null or private.not_blocked(viewer,v.owner_id))
    and not exists(select 1 from public.content_hides h where h.user_id=viewer and h.kind='video' and h.content_id=v.id));
$$;
create or replace function private.content_visible(content text,viewer uuid) returns boolean
language sql stable security definer set search_path='' as $$
select private.recipe_visible(content,viewer) or private.video_visible(content,viewer);
$$;
revoke all on function private.video_visible(text,uuid) from public,anon,authenticated;

alter policy recipes_read on public.recipes to authenticated using (
    (published or owner_id=(select auth.uid())) and (owner_id is null or private.not_blocked((select auth.uid()),owner_id))
    and not exists(select 1 from public.content_hides h where h.user_id=(select auth.uid()) and h.kind='recipe' and h.content_id=recipes.id)
);
alter policy videos_read on public.cooking_videos to authenticated using (
    published and (owner_id is null or private.not_blocked((select auth.uid()),owner_id))
    and not exists(select 1 from public.content_hides h where h.user_id=(select auth.uid()) and h.kind='video' and h.content_id=cooking_videos.id)
);
alter policy comments_read on public.content_comments to authenticated using (
    private.not_blocked((select auth.uid()),user_id) and (
        exists(select 1 from public.recipes r where r.id=content_comments.content_id)
        or exists(select 1 from public.cooking_videos v where v.id=content_comments.content_id)
    )
);

-- Preserve every current action, including the owner-updated agreement version.
do $patch$
declare source text; old_recipes text := 'where (r.published or r.owner_id=u) and (r.owner_id is null or private.not_blocked(u,r.owner_id)) and';
    old_videos text := 'where published order by created_at,id limit 100';
begin
    select pg_get_functiondef('private.toli_action(text,jsonb)'::regprocedure) into source;
    if (length(source)-length(replace(source,old_recipes,'')))/length(old_recipes)<>1
        or (length(source)-length(replace(source,old_videos,'')))/length(old_videos)<>1 then
        raise exception 'Current catalog action differs; inspect before applying safety filters';
    end if;
    source := replace(source,old_recipes,'where private.recipe_visible(r.id,u) and');
    source := replace(source,old_videos,'where private.video_visible(id,u) order by created_at,id limit 100');
    execute source;
end;
$patch$;

create function private.toli_safety(action text,body jsonb default '{}') returns jsonb
language plpgsql security definer set search_path='' as $$
declare viewer uuid := auth.uid(); kind text := body->>'kind'; content text := body->>'id';
    author uuid; heading text; author_name text; parent text; note text; result jsonb;
begin
    if viewer is null or not exists(select 1 from auth.users where id=viewer)
        or not exists(select 1 from public.profiles where id=viewer) then
        raise exception 'Authentication required' using errcode='42501';
    end if;
    if action='hidden' then
        select coalesce(jsonb_agg(jsonb_build_object('kind',h.kind,'id',h.content_id,'title',
            coalesce(r.title,v.title,'Unavailable content')) order by h.created_at desc,h.content_id),'[]') into result
        from public.content_hides h left join public.recipes r on h.kind='recipe' and r.id=h.content_id
        left join public.cooking_videos v on h.kind='video' and v.id=h.content_id where h.user_id=viewer;
        return result;
    elsif action='unhide' then
        delete from public.content_hides h where h.user_id=viewer and h.kind=toli_safety.kind and h.content_id=content;
        return '{}'::jsonb;
    end if;
    if kind='recipe' and private.recipe_visible(content,viewer) then
        select owner_id,title into author,heading from public.recipes where id=content;
    elsif kind='video' and private.video_visible(content,viewer) then
        select owner_id,title into author,heading from public.cooking_videos where id=content;
    elsif kind='comment' then
        select cm.user_id,cm.body,cm.content_id into author,heading,parent from public.content_comments cm
        where cm.id::text=content and private.not_blocked(viewer,cm.user_id);
        if not private.content_visible(parent,viewer) then author:=null; heading:=null; end if;
    elsif kind='profile' then
        select id,display_name into author,heading from public.profiles where id::text=content and private.not_blocked(viewer,id);
    end if;
    if heading is null then raise exception 'Content unavailable' using errcode='42501'; end if;
    select display_name into author_name from public.profiles where id=author;
    if action='context' then
        return jsonb_build_object('kind',kind,'id',content,'title',heading,'authorID',author,'authorName',author_name,'isOwn',coalesce(author=viewer,false));
    end if;
    if author=viewer then raise exception 'You cannot report or block your own content'; end if;
    if action='report' then
        note:=btrim(body->>'reason');
        if note is null or length(note) not between 3 and 1000 then raise exception 'Invalid report reason'; end if;
        insert into public.reports(user_id,target_id,content_kind,content_id,reason)
        values(viewer,case when kind='profile' then author else null end,kind,content,note);
    elsif action='blockAuthor' then
        if author is null then raise exception 'This editorial source is not a member account'; end if;
        perform private.toli_action('block',jsonb_build_object('userID',author));
    elsif action='hide' and kind in ('recipe','video') then
        insert into public.content_hides(user_id,kind,content_id) values(viewer,kind,content) on conflict do nothing;
    else raise exception 'Unsupported safety action';
    end if;
    return '{}'::jsonb;
end;
$$;
revoke all on function private.toli_safety(text,jsonb) from public,anon,authenticated;
create function public.toli_safety(action text,body jsonb default '{}') returns jsonb
language sql security invoker set search_path='' as $$ select private.toli_safety(action,body); $$;
grant execute on function private.toli_safety(text,jsonb) to authenticated;
revoke all on function public.toli_safety(text,jsonb) from public,anon;
grant execute on function public.toli_safety(text,jsonb) to authenticated;
