-- Repeatable room applause is separate from recipe collection membership.
create table public.room_reactions (
    id uuid primary key,
    user_id uuid not null references public.profiles(id) on delete cascade,
    content_id text not null references public.cooking_videos(id) on delete cascade,
    created_at timestamptz not null default now()
);

create index room_reactions_user_created_idx on public.room_reactions(user_id, created_at);
create index room_reactions_content_idx on public.room_reactions(content_id);
alter table public.room_reactions enable row level security;
revoke all on public.room_reactions from public, anon, authenticated;
grant select, insert on public.room_reactions to authenticated;

create policy room_reactions_read_own on public.room_reactions
    for select to authenticated using (user_id = (select auth.uid()));
create policy room_reactions_add_own on public.room_reactions
    for insert to authenticated with check (
        user_id = (select auth.uid())
        and exists (select 1 from public.cooking_videos v where v.id = content_id and v.published)
    );

comment on table public.room_reactions is 'Append-only, individually acknowledged cooking-room applause; never recipe likes or saved collection entries.';
