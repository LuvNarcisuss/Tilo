-- Toli A: account-scoped cooking, social data, and persistent IM.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null default 'Home Cook' check(length(display_name) between 1 and 60),
 username text not null unique check(username ~ '^[a-z0-9_]{3,30}$'),
 bio text not null default '' check(length(bio)<=300), avatar_url text,
 dietary_tags text[] not null default '{}', skill_level text not null default 'Beginner', created_at timestamptz not null default now()
);
create table public.blocks (user_id uuid references public.profiles on delete cascade, target_id uuid references public.profiles on delete cascade, primary key(user_id,target_id),check(user_id<>target_id));
create index blocks_target on public.blocks(target_id);
create table public.follows (user_id uuid references public.profiles on delete cascade, target_id uuid references public.profiles on delete cascade, created_at timestamptz not null default now(),primary key(user_id,target_id),check(user_id<>target_id));
create index follows_target on public.follows(target_id);
create table public.reports (id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,target_id uuid references public.profiles on delete set null,reason text not null check(length(reason) between 3 and 1000),created_at timestamptz not null default now());
create table public.recipes (id text primary key,title text not null,category text not null,image_url text,payload jsonb not null,owner_id uuid references public.profiles on delete cascade,published boolean not null default true,created_at timestamptz not null default now());
create index recipes_category on public.recipes(category,created_at desc,id);
create index recipes_owner on public.recipes(owner_id);
create table public.cooking_videos (id text primary key,title text not null,category text not null,image_url text,video_url text,payload jsonb not null,published boolean not null default true,created_at timestamptz not null default now());
create table public.bookmarks(user_id uuid references public.profiles on delete cascade,recipe_id text references public.recipes on delete cascade,created_at timestamptz not null default now(),primary key(user_id,recipe_id));
create index bookmarks_recipe on public.bookmarks(recipe_id);
create table public.content_likes(user_id uuid references public.profiles on delete cascade,content_id text not null,created_at timestamptz not null default now(),primary key(user_id,content_id));
create index likes_content on public.content_likes(content_id);
create table public.content_comments(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,content_id text not null,body text not null check(length(body) between 1 and 2000),created_at timestamptz not null default now());
create index comments_content on public.content_comments(content_id,created_at desc,id);
create table public.meal_plans(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,meal_date date not null,slot text not null check(slot in ('Breakfast','Lunch','Dinner','Snack')),recipe_id text not null references public.recipes on delete cascade,unique(user_id,meal_date,slot));
create table public.groceries(id uuid primary key default gen_random_uuid(),user_id uuid not null references public.profiles on delete cascade,name text not null check(length(name) between 1 and 100),quantity text not null default '',checked boolean not null default false,created_at timestamptz not null default now());
create index groceries_owner on public.groceries(user_id,created_at,id);
create table public.conversations(id uuid primary key default gen_random_uuid(),title text not null default '',is_group boolean not null default false,owner_id uuid not null references public.profiles on delete cascade,direct_key text unique,updated_at timestamptz not null default now());
create index conversations_owner on public.conversations(owner_id);
create table public.conversation_members(conversation_id uuid references public.conversations on delete cascade,user_id uuid references public.profiles on delete cascade,last_read_at timestamptz not null default '-infinity',is_pinned boolean not null default false,is_muted boolean not null default false,draft text not null default '',hidden_at timestamptz,joined_at timestamptz not null default now(),primary key(conversation_id,user_id));
create index conversation_members_user on public.conversation_members(user_id,conversation_id);
create table public.messages(id uuid primary key default gen_random_uuid(),conversation_id uuid not null references public.conversations on delete cascade,sender_id uuid not null references public.profiles on delete cascade,client_id uuid not null,body text not null check(length(body) between 1 and 5000),image_path text,created_at timestamptz not null default clock_timestamp(),unique(conversation_id,sender_id,client_id));
create index messages_history on public.messages(conversation_id,created_at desc,id);
create index messages_sender on public.messages(sender_id);

create function private.not_blocked(a uuid,b uuid) returns boolean language sql stable security definer set search_path='' as $$ select not exists(select 1 from public.blocks where (user_id=a and target_id=b) or (user_id=b and target_id=a)); $$;
create function private.member_of(cid uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.conversation_members m join public.profiles p on p.id=m.user_id where m.conversation_id=cid and m.user_id=(select auth.uid())) and not exists(select 1 from public.conversation_members m where m.conversation_id=cid and not private.not_blocked((select auth.uid()),m.user_id)); $$;
revoke all on function private.not_blocked(uuid,uuid),private.member_of(uuid) from public,anon;
grant execute on function private.not_blocked(uuid,uuid),private.member_of(uuid) to authenticated;

alter table public.profiles enable row level security;
create policy profiles_read on public.profiles for select to authenticated using(private.not_blocked((select auth.uid()),id));
alter table public.blocks enable row level security;
create policy blocks_read on public.blocks for select to authenticated using(user_id=(select auth.uid()));
alter table public.follows enable row level security;
create policy follows_read on public.follows for select to authenticated using(private.not_blocked((select auth.uid()),user_id) and private.not_blocked((select auth.uid()),target_id));
alter table public.reports enable row level security;
create policy reports_read on public.reports for select to authenticated using(user_id=(select auth.uid()));
alter table public.recipes enable row level security;
create policy recipes_read on public.recipes for select to authenticated using((published or owner_id=(select auth.uid())) and (owner_id is null or private.not_blocked((select auth.uid()),owner_id)));
alter table public.cooking_videos enable row level security;
create policy videos_read on public.cooking_videos for select to authenticated using(published);
alter table public.bookmarks enable row level security;
create policy bookmarks_read on public.bookmarks for select to authenticated using(user_id=(select auth.uid()));
alter table public.content_likes enable row level security;
create policy likes_read on public.content_likes for select to authenticated using(user_id=(select auth.uid()));
alter table public.content_comments enable row level security;
create policy comments_read on public.content_comments for select to authenticated using(private.not_blocked((select auth.uid()),user_id));
alter table public.meal_plans enable row level security;
create policy meals_read on public.meal_plans for select to authenticated using(user_id=(select auth.uid()));
alter table public.groceries enable row level security;
create policy groceries_read on public.groceries for select to authenticated using(user_id=(select auth.uid()));
alter table public.conversations enable row level security;
create policy conversations_read on public.conversations for select to authenticated using(private.member_of(id));
alter table public.conversation_members enable row level security;
create policy members_read on public.conversation_members for select to authenticated using(private.member_of(conversation_id));
alter table public.messages enable row level security;
create policy messages_read on public.messages for select to authenticated using(private.member_of(conversation_id));
revoke all on all tables in schema public from anon;
revoke all on public.profiles,public.blocks,public.follows,public.reports,public.recipes,public.cooking_videos,public.bookmarks,public.content_likes,public.content_comments,public.meal_plans,public.groceries,public.conversations,public.conversation_members,public.messages from authenticated;
grant select on public.profiles,public.blocks,public.follows,public.reports,public.recipes,public.cooking_videos,public.bookmarks,public.content_likes,public.content_comments,public.meal_plans,public.groceries,public.conversations,public.conversation_members,public.messages to authenticated;

create function private.profile_json(p public.profiles) returns jsonb language sql stable set search_path='' as $$
select jsonb_build_object('id',p.id,'displayName',p.display_name,'username',p.username,'bio',p.bio,'avatarURL',p.avatar_url,'dietaryTags',p.dietary_tags,'skillLevel',p.skill_level,
'worksCount',(select count(*) from public.recipes r where r.owner_id=p.id and r.published),'followersCount',(select count(*) from public.follows f where f.target_id=p.id),'followingCount',(select count(*) from public.follows f where f.user_id=p.id),
'likesCount',(select count(*) from public.content_likes l join public.recipes r on r.id=l.content_id where r.owner_id=p.id),'savesCount',(select count(*) from public.bookmarks b join public.recipes r on r.id=b.recipe_id where r.owner_id=p.id)); $$;
create function private.recipe_json(r public.recipes) returns jsonb language sql immutable set search_path='' as $$ select jsonb_build_object('id',r.id,'title',r.title,'category',r.category,'imageURL',r.image_url,'payload',r.payload); $$;
create function private.conversation_json(c public.conversations,u uuid) returns jsonb language sql stable set search_path='' as $$
select jsonb_build_object('id',c.id,'title',case when c.is_group then c.title else coalesce((select p.display_name from public.conversation_members cm join public.profiles p on p.id=cm.user_id where cm.conversation_id=c.id and cm.user_id<>u limit 1),'Conversation') end,
'isGroup',c.is_group,'ownerID',c.owner_id,'updatedAt',c.updated_at,'lastMessage',(select body from public.messages where conversation_id=c.id order by created_at desc,id desc limit 1),
'unreadCount',(select count(*) from public.messages msg where msg.conversation_id=c.id and msg.sender_id<>u and msg.created_at>m.last_read_at),'isPinned',m.is_pinned,'isMuted',m.is_muted,'draft',m.draft)
from public.conversation_members m where m.conversation_id=c.id and m.user_id=u; $$;
create function private.message_json(m public.messages) returns jsonb language sql immutable set search_path='' as $$ select jsonb_build_object('id',m.id,'conversationID',m.conversation_id,'senderID',m.sender_id,'clientID',m.client_id,'body',m.body,'createdAt',m.created_at,'imagePath',m.image_path); $$;

create table public.agreement_consents(user_id uuid references public.profiles on delete cascade,version text not null,adult_confirmed boolean not null check(adult_confirmed),accepted_at timestamptz not null default now(),primary key(user_id,version));
alter table public.agreement_consents enable row level security;
create policy consent_read on public.agreement_consents for select to authenticated using(user_id=(select auth.uid()));
revoke all on public.agreement_consents from anon,authenticated;
grant select on public.agreement_consents to authenticated;
alter table public.reports add column content_kind text not null default 'profile',add column content_id text;
create or replace function private.conversation_json(c public.conversations,u uuid) returns jsonb language sql stable set search_path='' as $$
select jsonb_build_object('id',c.id,'title',case when c.is_group then c.title else coalesce((select p.display_name from public.conversation_members cm join public.profiles p on p.id=cm.user_id where cm.conversation_id=c.id and cm.user_id<>u limit 1),'Conversation') end,
'peerID',case when not c.is_group then (select user_id from public.conversation_members where conversation_id=c.id and user_id<>u limit 1) else null end,'avatarURL',case when not c.is_group then (select p.avatar_url from public.profiles p join public.conversation_members cm on cm.user_id=p.id where cm.conversation_id=c.id and cm.user_id<>u limit 1) else null end,'isGroup',c.is_group,'ownerID',c.owner_id,'updatedAt',c.updated_at,'lastMessage',(select body from public.messages where conversation_id=c.id order by created_at desc,id desc limit 1),
'unreadCount',(select count(*) from public.messages msg where msg.conversation_id=c.id and msg.sender_id<>u and msg.created_at>m.last_read_at),'isPinned',m.is_pinned,'isMuted',m.is_muted,'draft',m.draft)
from public.conversation_members m where m.conversation_id=c.id and m.user_id=u; $$;
create unique index groceries_name_unique on public.groceries(user_id,(lower(btrim(name))));
create or replace function private.merge_quantity(a text,b text) returns text language plpgsql immutable set search_path='' as $$
declare am text[];bm text[];
begin
 am:=regexp_match(a,'^([0-9]+([.][0-9]+)?) +(.*)$');bm:=regexp_match(b,'^([0-9]+([.][0-9]+)?) +(.*)$');
 if am is not null and bm is not null and lower(am[3])=lower(bm[3]) then return regexp_replace(trim(to_char(am[1]::numeric+bm[1]::numeric,'FM999999990.999')),'[.]$','')||' '||am[3];end if;
 if btrim(a)='' then return b;end if;if btrim(b)='' then return a;end if;return a||' + '||b;
end; $$;
revoke all on function private.merge_quantity(text,text) from public,anon,authenticated;
drop policy members_read on public.conversation_members;
create policy members_read on public.conversation_members for select to authenticated using(user_id=(select auth.uid()) and private.member_of(conversation_id));
create function private.recipe_visible(content text,viewer uuid) returns boolean language sql stable security definer set search_path='' as $$ select exists(select 1 from public.recipes r where r.id=content and (r.published or r.owner_id=viewer) and (r.owner_id is null or private.not_blocked(viewer,r.owner_id))); $$;
create function private.content_visible(content text,viewer uuid) returns boolean language sql stable security definer set search_path='' as $$ select private.recipe_visible(content,viewer) or exists(select 1 from public.cooking_videos v where v.id=content and v.published); $$;
create function private.validate_recipe(doc jsonb,viewer uuid) returns void language plpgsql security definer set search_path='' as $$
declare p jsonb:=doc->'payload';v jsonb;k text;n numeric;url text:=doc->>'imageURL';prefix text:='https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/recipe-photos/';
begin
 if jsonb_typeof(doc->'title')<>'string' or length(btrim(doc->>'title')) not between 1 and 120 or jsonb_typeof(doc->'category')<>'string' or length(doc->>'category') not between 1 and 40 or jsonb_typeof(doc->'id')<>'string' or length(doc->>'id') not between 1 and 100 then raise exception 'Invalid recipe fields';end if;
 if p is null or jsonb_typeof(p)<>'object' then raise exception 'Invalid recipe details';end if;
 foreach k in array array['summary','difficulty'] loop if jsonb_typeof(p->k) is distinct from 'string' or length(p->>k)>2000 then raise exception 'Invalid recipe text';end if;end loop;
 foreach k in array array['prepMinutes','cookMinutes','servings','calories','protein','carbs','fat'] loop
  if jsonb_typeof(p->k) is distinct from 'number' or (p->>k)!~'^[0-9]+$' then raise exception 'Recipe numbers must be nonnegative integers';end if;n:=(p->>k)::numeric;
  if n>100000 or (k in ('prepMinutes','cookMinutes') and n>1440) or (k='servings' and n not between 1 and 1000) then raise exception 'Recipe number outside allowed range';end if;
 end loop;
 if jsonb_typeof(p->'ingredients') is distinct from 'array' or jsonb_array_length(p->'ingredients') not between 1 and 100 or jsonb_typeof(p->'steps') is distinct from 'array' or jsonb_array_length(p->'steps') not between 1 and 100 or jsonb_typeof(p->'tags') is distinct from 'array' or jsonb_array_length(p->'tags')>30 then raise exception 'Invalid recipe lists';end if;
 for v in select * from jsonb_array_elements(p->'ingredients') loop
  if jsonb_typeof(v)<>'object' then raise exception 'Invalid ingredient';end if;
  foreach k in array array['name','quantity','unit'] loop if jsonb_typeof(v->k) is distinct from 'string' or length(v->>k)>100 then raise exception 'Invalid ingredient text';end if;end loop;
  if length(btrim(v->>'name'))=0 then raise exception 'Ingredient name required';end if;
 end loop;
 for v in select * from jsonb_array_elements(p->'steps') loop if jsonb_typeof(v)<>'string' or length(v#>>'{}') not between 1 and 3000 then raise exception 'Invalid recipe step';end if;end loop;
 for v in select * from jsonb_array_elements(p->'tags') loop if jsonb_typeof(v)<>'string' or length(v#>>'{}') not between 1 and 60 then raise exception 'Invalid recipe tag';end if;end loop;
 if url is null or url not like prefix||viewer::text||'/%' or not exists(select 1 from storage.objects where bucket_id='recipe-photos' and name=substring(url from length(prefix)+1)) then raise exception 'Upload your recipe photo before publishing';end if;
end; $$;
revoke all on function private.recipe_visible(text,uuid),private.content_visible(text,uuid),private.validate_recipe(jsonb,uuid) from public,anon,authenticated;
create or replace function private.toli_action(action text,body jsonb default '{}') returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=auth.uid(); target uuid; cid uuid; c public.conversations; msg public.messages; existing public.messages; result jsonb; value text; ids uuid[]; item uuid;
begin
 if u is null or not exists(select 1 from auth.users where id=u) then raise exception 'Authentication required' using errcode='42501'; end if;
 if action='bootstrap' then
  insert into public.profiles(id,username) values(u,'cook_'||substr(replace(u::text,'-',''),1,20)) on conflict(id) do nothing;
  return jsonb_build_object('code',0,'message','ok','data','{}'::jsonb);
 end if;
 if not exists(select 1 from public.profiles where id=u) then raise exception 'Profile setup required'; end if;
 target:=nullif(toli_action.body->>'userID','')::uuid;
 cid:=nullif(toli_action.body->>'conversationID','')::uuid;
 if action='addGroceries' then
  if jsonb_array_length(toli_action.body->'items')>100 or coalesce((toli_action.body->>'scale')::numeric,0)<=0 or (toli_action.body->>'scale')::numeric>100 then raise exception 'Invalid ingredient batch';end if;
  for result in select * from jsonb_array_elements(toli_action.body->'items') loop
   if length(btrim(result->>'name')) not between 1 and 100 then raise exception 'Invalid ingredient name';end if;
   if result->>'quantity' ~ '^[0-9]+([.][0-9]+)?$' then value:=regexp_replace(trim(to_char((result->>'quantity')::numeric*(toli_action.body->>'scale')::numeric,'FM999999990.999')),'[.]$','')||' '||coalesce(result->>'unit','');
   else value:=coalesce(result->>'quantity','')||' '||coalesce(result->>'unit','');end if;
   insert into public.groceries(user_id,name,quantity) values(u,btrim(result->>'name'),btrim(value)) on conflict(user_id,(lower(btrim(name)))) do update set quantity=private.merge_quantity(public.groceries.quantity,excluded.quantity),checked=false;
  end loop;
 elsif action='acceptAgreements' then
  if toli_action.body->>'version'<>'2026-11-03-24e387172fe8' or coalesce((toli_action.body->>'adultConfirmed')::boolean,false)=false then raise exception 'Current agreements and adulthood must be confirmed';end if;
  insert into public.agreement_consents(user_id,version,adult_confirmed) values(u,toli_action.body->>'version',true) on conflict(user_id,version) do nothing;
 elsif action='reportContent' then
  if toli_action.body->>'kind' not in ('profile','recipe','video') then raise exception 'Unsupported report type';end if;
  insert into public.reports(user_id,target_id,content_kind,content_id,reason) values(u,case when toli_action.body->>'kind'='profile' then (toli_action.body->>'targetID')::uuid else null end,toli_action.body->>'kind',toli_action.body->>'targetID',toli_action.body->>'reason');
 elsif action='profile' then
  select private.profile_json(p) into result from public.profiles p where p.id=coalesce(target,u) and private.not_blocked(u,p.id); if result is null then raise exception 'Profile unavailable'; end if; return result;
 elsif action='updateProfile' then
  if toli_action.body ? 'avatarURL' and toli_action.body->>'avatarURL' is not null and toli_action.body->>'avatarURL' not like 'https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/avatars/'||u::text||'/%' then raise exception 'Avatar must belong to your account'; end if;
  update public.profiles set display_name=toli_action.body->>'displayName',username=lower(toli_action.body->>'username'),bio=toli_action.body->>'bio',dietary_tags=coalesce(array(select jsonb_array_elements_text(toli_action.body->'dietaryTags')),'{}'),skill_level=toli_action.body->>'skillLevel',avatar_url=case when toli_action.body ? 'avatarURL' then toli_action.body->>'avatarURL' else avatar_url end where id=u;
  return private.toli_action('profile','{}');
 elsif action='searchUsers' then
  select coalesce(jsonb_agg(private.profile_json(p)),'[]') into result from (select * from public.profiles where id<>u and private.not_blocked(u,id) and (display_name ilike '%'||left(toli_action.body->>'query',80)||'%' or username ilike '%'||left(toli_action.body->>'query',80)||'%') order by display_name,id limit 50) p;return result;
 elsif action='relationships' then
  target:=coalesce(target,u);
  if not private.not_blocked(u,target) then raise exception 'Profile unavailable'; end if;
  select coalesce(jsonb_agg(private.profile_json(p)),'[]') into result from public.profiles p where private.not_blocked(u,p.id) and
   case toli_action.body->>'kind' when 'followers' then exists(select 1 from public.follows where user_id=p.id and target_id=target) when 'following' then exists(select 1 from public.follows where user_id=target and target_id=p.id) when 'mutuals' then exists(select 1 from public.follows where user_id=target and target_id=p.id) and exists(select 1 from public.follows where user_id=p.id and target_id=target) else false end;return result;
 elsif action='setFollow' then
  if target=u or not private.not_blocked(u,target) then raise exception 'Unable to follow this cook'; end if;
  if (toli_action.body->>'following')::boolean then insert into public.follows values(u,target,now()) on conflict do nothing; else delete from public.follows where user_id=u and target_id=target;end if;
 elsif action='blockedUsers' then
  select coalesce(jsonb_agg(private.profile_json(p)),'[]') into result from public.profiles p join public.blocks b on b.target_id=p.id where b.user_id=u;return result;
 elsif action='block' then
  if target=u then raise exception 'Cannot block yourself'; end if;
  insert into public.blocks values(u,target) on conflict do nothing;
  delete from public.follows where (user_id=u and target_id=target) or (user_id=target and target_id=u);
 elsif action='unblock' then delete from public.blocks where user_id=u and target_id=target;
 elsif action='report' then insert into public.reports(user_id,target_id,reason) values(u,target,toli_action.body->>'reason');
 elsif action='recipes' or action='recipe' or action='recipeCollection' then
  select coalesce(jsonb_agg(private.recipe_json(r)),'[]') into result from (select r.* from public.recipes r where (r.published or r.owner_id=u) and (r.owner_id is null or private.not_blocked(u,r.owner_id)) and
  (action<>'recipe' or r.id=toli_action.body->>'id') and (action<>'recipes' or ((nullif(toli_action.body->>'category','') is null or r.category=toli_action.body->>'category') and (nullif(toli_action.body->>'query','') is null or r.title ilike '%'||left(toli_action.body->>'query',100)||'%'))) and
  (action<>'recipeCollection' or case toli_action.body->>'scope' when 'saved' then coalesce(target,u)=u and exists(select 1 from public.bookmarks b where b.user_id=u and b.recipe_id=r.id) when 'liked' then coalesce(target,u)=u and exists(select 1 from public.content_likes l where l.user_id=u and l.content_id=r.id) when 'works' then r.owner_id=coalesce(target,u) else false end)
  order by r.created_at desc,r.id limit 100 offset least(greatest(coalesce((toli_action.body->>'offset')::integer,0),0),10000)) r;
  if action='recipe' then if jsonb_array_length(result)=0 then raise exception 'Recipe unavailable'; end if;return result->0;end if;return result;
 elsif action='publishRecipe' then
  perform private.validate_recipe(toli_action.body,u);
  insert into public.recipes(id,title,category,image_url,payload,owner_id) values(toli_action.body->>'id',toli_action.body->>'title',toli_action.body->>'category',toli_action.body->>'imageURL',toli_action.body->'payload',u)
  on conflict(id) do update set title=excluded.title,category=excluded.category,image_url=excluded.image_url,payload=excluded.payload where public.recipes.owner_id=u;
  if not found then raise exception 'Recipe does not belong to you';end if;
  return private.toli_action('recipe',jsonb_build_object('id',toli_action.body->>'id'));
 elsif action='deleteRecipe' then delete from public.recipes where id=toli_action.body->>'id' and owner_id=u;
 elsif action='videos' then select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'category',v.category,'imageURL',v.image_url,'videoURL',v.video_url,'payload',v.payload)),'[]') into result from (select * from public.cooking_videos where published order by created_at,id limit 100) v;return result;
 elsif action='toggleBookmark' then
  if (toli_action.body->>'saved')::boolean then
   if not private.recipe_visible(toli_action.body->>'recipeID',u) then raise exception 'Content unavailable';end if;
   insert into public.bookmarks values(u,toli_action.body->>'recipeID',now()) on conflict do nothing;else delete from public.bookmarks where user_id=u and recipe_id=toli_action.body->>'recipeID';end if;
 elsif action='toggleLike' then
  value:=toli_action.body->>'contentID';if not private.content_visible(value,u) then raise exception 'Content unavailable';end if;
  if (toli_action.body->>'liked')::boolean then insert into public.content_likes values(u,value,now()) on conflict do nothing;else delete from public.content_likes where user_id=u and content_id=value;end if;
 elsif action='likedContentIDs' then select coalesce(jsonb_agg(content_id),'[]') into result from public.content_likes where user_id=u and private.content_visible(content_id,u);return result;
 elsif action='comments' then
  if not private.content_visible(toli_action.body->>'contentID',u) then raise exception 'Content unavailable';end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',cm.id,'contentID',cm.content_id,'userID',cm.user_id,'displayName',p.display_name,'avatarURL',p.avatar_url,'body',cm.body,'createdAt',cm.created_at)),'[]') into result from (select * from public.content_comments where content_id=toli_action.body->>'contentID' and private.not_blocked(u,user_id) order by created_at desc,id desc limit 100) cm join public.profiles p on p.id=cm.user_id;return result;
 elsif action='addComment' then
  value:=toli_action.body->>'contentID';if not private.content_visible(value,u) then raise exception 'Content unavailable';end if;
  insert into public.content_comments(user_id,content_id,body) values(u,value,btrim(toli_action.body->>'body'));
 elsif action='mealPlans' then
  select coalesce(jsonb_agg(jsonb_build_object('id',m.id,'date',m.meal_date,'slot',m.slot,'recipeID',r.id,'recipeTitle',r.title,'imageURL',r.image_url) order by m.meal_date,m.slot),'[]') into result from public.meal_plans m join public.recipes r on r.id=m.recipe_id where m.user_id=u and private.recipe_visible(m.recipe_id,u);return result;
 elsif action='saveMeal' then
  if not private.recipe_visible(toli_action.body->>'recipeID',u) then raise exception 'Content unavailable';end if;
  insert into public.meal_plans(user_id,meal_date,slot,recipe_id) values(u,(toli_action.body->>'date')::date,toli_action.body->>'slot',toli_action.body->>'recipeID') on conflict(user_id,meal_date,slot) do update set recipe_id=excluded.recipe_id;
 elsif action='removeMeal' then delete from public.meal_plans where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='groceries' then select coalesce(jsonb_agg(jsonb_build_object('id',g.id,'name',g.name,'quantity',g.quantity,'checked',g.checked) order by g.created_at,g.id),'[]') into result from public.groceries g where g.user_id=u;return result;
 elsif action='addGrocery' then insert into public.groceries(user_id,name,quantity) values(u,btrim(toli_action.body->>'name'),toli_action.body->>'quantity') on conflict(user_id,(lower(btrim(name)))) do update set quantity=private.merge_quantity(public.groceries.quantity,excluded.quantity),checked=false;
 elsif action='updateGrocery' then update public.groceries set checked=(toli_action.body->>'checked')::boolean where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='removeGrocery' then delete from public.groceries where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='conversations' then
  select coalesce(jsonb_agg(private.conversation_json(conv,u) order by m.is_pinned desc,conv.updated_at desc),'[]') into result from public.conversations conv join public.conversation_members m on m.conversation_id=conv.id and m.user_id=u where private.member_of(conv.id) and (m.hidden_at is null or conv.updated_at>m.hidden_at);return result;
 elsif action='createDirect' then
  if target=u or not private.not_blocked(u,target) or not exists(select 1 from public.follows where user_id=u and target_id=target) or not exists(select 1 from public.follows where user_id=target and target_id=u) then raise exception 'Direct messages require a mutual follow';end if;
  value:=least(u::text,target::text)||':'||greatest(u::text,target::text);
  insert into public.conversations(owner_id,direct_key) values(u,value) on conflict(direct_key) do update set direct_key=excluded.direct_key returning * into c;
  insert into public.conversation_members(conversation_id,user_id) values(c.id,u),(c.id,target) on conflict do nothing;
  update public.conversation_members set hidden_at=null where conversation_id=c.id and user_id=u;return private.conversation_json(c,u);
 elsif action='createGroup' then
  if length(btrim(toli_action.body->>'title')) not between 1 and 60 then raise exception 'Use a group name between 1 and 60 characters';end if;
  ids:=array(select distinct x::uuid from jsonb_array_elements_text(toli_action.body->'memberIDs') x where x::uuid<>u);
  if cardinality(ids)>30 or cardinality(ids)<2 then raise exception 'Choose between 2 and 30 cooks';end if;
  foreach item in array ids loop if item<>u and (not private.not_blocked(u,item) or not exists(select 1 from public.follows where user_id=u and target_id=item) or not exists(select 1 from public.follows where user_id=item and target_id=u)) then raise exception 'Invite mutual followers only';end if;end loop;
  insert into public.conversations(title,is_group,owner_id) values(btrim(toli_action.body->>'title'),true,u) returning * into c;
  insert into public.conversation_members(conversation_id,user_id) values(c.id,u);
  insert into public.conversation_members(conversation_id,user_id) select c.id,unnest(ids) on conflict do nothing;return private.conversation_json(c,u);
 elsif action in ('messages','sendMessage','markRead','updateConversation','deleteConversation','conversationMembers','changeMember','leaveGroup') then
  if not private.member_of(cid) then raise exception 'Conversation access denied' using errcode='42501';end if;
  select * into c from public.conversations where id=cid for update;
  if action='messages' then
   select coalesce(jsonb_agg(private.message_json(mm) order by mm.created_at,mm.id),'[]') into result from (select * from public.messages where conversation_id=cid and (nullif(toli_action.body->>'before','') is null or created_at<(toli_action.body->>'before')::timestamptz) order by created_at desc,id desc limit 100) mm;return result;
  elsif action='sendMessage' then
   if not c.is_group and exists(select 1 from public.conversation_members cm where cm.conversation_id=cid and cm.user_id<>u and (not exists(select 1 from public.follows f where f.user_id=u and f.target_id=cm.user_id) or not exists(select 1 from public.follows f where f.user_id=cm.user_id and f.target_id=u))) then raise exception 'Direct messages require a mutual follow';end if;
   select * into existing from public.messages where conversation_id=cid and sender_id=u and client_id=(toli_action.body->>'clientID')::uuid;
   if found then if existing.body<>btrim(toli_action.body->>'body') or existing.image_path is distinct from toli_action.body->>'imagePath' then raise exception 'Message retry differs from original';end if;return private.message_json(existing);end if;
   if toli_action.body->>'imagePath' is not null and (toli_action.body->>'imagePath' not like cid::text||'/'||u::text||'/%' or not exists(select 1 from storage.objects where bucket_id='chat-images' and name=toli_action.body->>'imagePath')) then raise exception 'Invalid attachment owner';end if;
   insert into public.messages(conversation_id,sender_id,client_id,body,image_path) values(cid,u,(toli_action.body->>'clientID')::uuid,btrim(toli_action.body->>'body'),toli_action.body->>'imagePath') returning * into msg;
   update public.conversations set updated_at=msg.created_at where id=cid;
   update public.conversation_members set draft='',last_read_at=greatest(last_read_at,msg.created_at),hidden_at=null where conversation_id=cid and user_id=u;return private.message_json(msg);
  elsif action='markRead' then update public.conversation_members set last_read_at=greatest(last_read_at,coalesce((select max(created_at) from public.messages where conversation_id=cid),now())) where conversation_id=cid and user_id=u;
  elsif action='updateConversation' then update public.conversation_members set is_pinned=coalesce((toli_action.body->>'pinned')::boolean,is_pinned),is_muted=coalesce((toli_action.body->>'muted')::boolean,is_muted),draft=coalesce(toli_action.body->>'draft',draft) where conversation_id=cid and user_id=u;
  elsif action='deleteConversation' then update public.conversation_members set hidden_at=clock_timestamp() where conversation_id=cid and user_id=u;
  elsif action='conversationMembers' then select coalesce(jsonb_agg(private.profile_json(p)),'[]') into result from public.profiles p join public.conversation_members m on m.user_id=p.id where m.conversation_id=cid;return result;
  elsif action='leaveGroup' then
   if not c.is_group then raise exception 'Use Delete Conversation for direct messages';end if;
   if c.owner_id=u and (select count(*) from public.conversation_members where conversation_id=cid)>1 then raise exception 'Remove other members before leaving your group';end if;
   delete from public.conversation_members where conversation_id=cid and user_id=u;
   if c.owner_id=u then delete from public.conversations where id=cid;end if;
  elsif action='changeMember' then
   if not c.is_group or c.owner_id<>u or target=u then raise exception 'Only the group owner can manage other members';end if;
   if (toli_action.body->>'remove')::boolean then delete from public.conversation_members where conversation_id=cid and user_id=target;
   else
    if not private.not_blocked(u,target) or not exists(select 1 from public.follows where user_id=u and target_id=target) or not exists(select 1 from public.follows where user_id=target and target_id=u) then raise exception 'Invite mutual followers only';end if;
    insert into public.conversation_members(conversation_id,user_id) values(cid,target) on conflict do nothing;
   end if;
  end if;
 else raise exception 'Unknown action';
 end if;
 return '{}'::jsonb;
end; $$;
revoke all on all functions in schema private from public,anon;
grant execute on function private.toli_action(text,jsonb),private.not_blocked(uuid,uuid),private.member_of(uuid) to authenticated;
create function public.toli_action(action text,body jsonb default '{}') returns jsonb language sql security invoker set search_path='' as $$ select private.toli_action(action,body); $$;
revoke all on function public.toli_action(text,jsonb) from public,anon;
grant execute on function public.toli_action(text,jsonb) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('catalog','catalog',true,104857600,array['image/jpeg','image/png','video/mp4']),
('legal','legal',true,10485760,array['application/pdf']),
('avatars','avatars',true,5242880,array['image/jpeg','image/png']),
('chat-images','chat-images',false,10485760,array['image/jpeg','image/png']) on conflict(id) do nothing;
create policy avatar_read on storage.objects for select to authenticated using(bucket_id='avatars');
create policy avatar_insert on storage.objects for insert to authenticated with check(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy avatar_update on storage.objects for update to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy avatar_delete on storage.objects for delete to authenticated using(bucket_id='avatars' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy chat_image_read on storage.objects for select to authenticated using(bucket_id='chat-images' and private.member_of(((storage.foldername(name))[1])::uuid));
create policy chat_image_insert on storage.objects for insert to authenticated with check(bucket_id='chat-images' and (storage.foldername(name))[2]=(select auth.uid())::text and private.member_of(((storage.foldername(name))[1])::uuid));
create policy chat_image_delete on storage.objects for delete to authenticated using(bucket_id='chat-images' and (storage.foldername(name))[2]=(select auth.uid())::text);

do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='messages') then alter publication supabase_realtime add table public.messages;end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='conversation_members') then alter publication supabase_realtime add table public.conversation_members;end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='conversations') then alter publication supabase_realtime add table public.conversations;end if;
end; $$;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('toli-catalog','toli-catalog',true,104857600,array['image/jpeg','image/png','video/mp4']),('recipe-photos','recipe-photos',true,10485760,array['image/jpeg','image/png']) on conflict(id) do nothing;
create policy recipe_photo_insert on storage.objects for insert to authenticated with check(bucket_id='recipe-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy recipe_photo_delete on storage.objects for delete to authenticated using(bucket_id='recipe-photos' and (storage.foldername(name))[1]=(select auth.uid())::text);
