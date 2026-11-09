create or replace function private.merge_quantity(a text,b text) returns text language plpgsql immutable set search_path='' as $$
declare am text[];bm text[];
begin
 am:=regexp_match(a,'^([0-9]+([.][0-9]+)?) +(.*)$');bm:=regexp_match(b,'^([0-9]+([.][0-9]+)?) +(.*)$');
 if am is not null and bm is not null and lower(am[3])=lower(bm[3]) then return regexp_replace(trim(to_char(am[1]::numeric+bm[1]::numeric,'FM999999990.999')),'[.]$','')||' '||am[3];end if;
 if btrim(a)='' then return b;end if;if btrim(b)='' then return a;end if;return a||' + '||b;
end; $$;
revoke all on function private.merge_quantity(text,text) from public,anon,authenticated;
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
  if toli_action.body->>'version'<>'2026-11-03-ecd0a3abea14' or coalesce((toli_action.body->>'adultConfirmed')::boolean,false)=false then raise exception 'Current agreements and adulthood must be confirmed';end if;
  insert into public.agreement_consents(user_id,version,adult_confirmed) values(u,toli_action.body->>'version',true) on conflict(user_id,version) do nothing;
 elsif action='reportContent' then
  if toli_action.body->>'kind' not in ('profile','recipe','video') then raise exception 'Unsupported report type';end if;
  insert into public.reports(user_id,target_id,content_kind,content_id,reason) values(u,case when toli_action.body->>'kind'='profile' then (toli_action.body->>'targetID')::uuid else null end,toli_action.body->>'kind',toli_action.body->>'targetID',toli_action.body->>'reason');
 elsif action='profile' then
  select private.profile_json(p) into result from public.profiles p where p.id=coalesce(target,u) and private.not_blocked(u,p.id); if result is null then raise exception 'Profile unavailable'; end if; return result;
 elsif action='updateProfile' then
  if toli_action.body ? 'avatarURL' and toli_action.body->>'avatarURL' is not null and toli_action.body->>'avatarURL' not like 'https://lyotjdrnsdoernrcwwfd.supabase.co/storage/v1/object/public/avatars/'||u::text||'/%' then raise exception 'Avatar must belong to your account'; end if;
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
  insert into public.recipes(id,title,category,image_url,payload,owner_id) values(toli_action.body->>'id',toli_action.body->>'title',toli_action.body->>'category',toli_action.body->>'imageURL',toli_action.body->'payload',u)
  on conflict(id) do update set title=excluded.title,category=excluded.category,image_url=excluded.image_url,payload=excluded.payload where public.recipes.owner_id=u;
  if not found then raise exception 'Recipe does not belong to you';end if;
  return private.toli_action('recipe',jsonb_build_object('id',toli_action.body->>'id'));
 elsif action='deleteRecipe' then delete from public.recipes where id=toli_action.body->>'id' and owner_id=u;
 elsif action='videos' then select coalesce(jsonb_agg(jsonb_build_object('id',v.id,'title',v.title,'category',v.category,'imageURL',v.image_url,'videoURL',v.video_url,'payload',v.payload)),'[]') into result from (select * from public.cooking_videos where published order by created_at,id limit 100) v;return result;
 elsif action='toggleBookmark' then
  if (toli_action.body->>'saved')::boolean then insert into public.bookmarks values(u,toli_action.body->>'recipeID',now()) on conflict do nothing;else delete from public.bookmarks where user_id=u and recipe_id=toli_action.body->>'recipeID';end if;
 elsif action='toggleLike' then
  value:=toli_action.body->>'contentID';if not exists(select 1 from public.recipes where id=value and published) and not exists(select 1 from public.cooking_videos where id=value and published) then raise exception 'Content unavailable';end if;
  if (toli_action.body->>'liked')::boolean then insert into public.content_likes values(u,value,now()) on conflict do nothing;else delete from public.content_likes where user_id=u and content_id=value;end if;
 elsif action='likedContentIDs' then select coalesce(jsonb_agg(content_id),'[]') into result from public.content_likes where user_id=u;return result;
 elsif action='comments' then
  select coalesce(jsonb_agg(jsonb_build_object('id',cm.id,'contentID',cm.content_id,'userID',cm.user_id,'displayName',p.display_name,'avatarURL',p.avatar_url,'body',cm.body,'createdAt',cm.created_at)),'[]') into result from (select * from public.content_comments where content_id=toli_action.body->>'contentID' and private.not_blocked(u,user_id) order by created_at desc,id desc limit 100) cm join public.profiles p on p.id=cm.user_id;return result;
 elsif action='addComment' then
  value:=toli_action.body->>'contentID';if not exists(select 1 from public.recipes where id=value and published) and not exists(select 1 from public.cooking_videos where id=value and published) then raise exception 'Content unavailable';end if;
  insert into public.content_comments(user_id,content_id,body) values(u,value,btrim(toli_action.body->>'body'));
 elsif action='mealPlans' then
  select coalesce(jsonb_agg(jsonb_build_object('id',m.id,'date',m.meal_date,'slot',m.slot,'recipeID',r.id,'recipeTitle',r.title,'imageURL',r.image_url) order by m.meal_date,m.slot),'[]') into result from public.meal_plans m join public.recipes r on r.id=m.recipe_id where m.user_id=u;return result;
 elsif action='saveMeal' then insert into public.meal_plans(user_id,meal_date,slot,recipe_id) values(u,(toli_action.body->>'date')::date,toli_action.body->>'slot',toli_action.body->>'recipeID') on conflict(user_id,meal_date,slot) do update set recipe_id=excluded.recipe_id;
 elsif action='removeMeal' then delete from public.meal_plans where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='groceries' then select coalesce(jsonb_agg(jsonb_build_object('id',g.id,'name',g.name,'quantity',g.quantity,'checked',g.checked) order by g.created_at,g.id),'[]') into result from public.groceries g where g.user_id=u;return result;
 elsif action='addGrocery' then insert into public.groceries(user_id,name,quantity) values(u,btrim(toli_action.body->>'name'),toli_action.body->>'quantity') on conflict(user_id,(lower(btrim(name)))) do update set quantity=private.merge_quantity(public.groceries.quantity,excluded.quantity),checked=false;
 elsif action='updateGrocery' then update public.groceries set checked=(toli_action.body->>'checked')::boolean where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='removeGrocery' then delete from public.groceries where id=(toli_action.body->>'id')::uuid and user_id=u;
 elsif action='conversations' then
  select coalesce(jsonb_agg(private.conversation_json(c,u) order by m.is_pinned desc,c.updated_at desc),'[]') into result from public.conversations c join public.conversation_members m on m.conversation_id=c.id and m.user_id=u where private.member_of(c.id) and (m.hidden_at is null or c.updated_at>m.hidden_at);return result;
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
   select * into existing from public.messages where conversation_id=cid and sender_id=u and client_id=(toli_action.body->>'clientID')::uuid;
   if found then if existing.body<>btrim(toli_action.body->>'body') or existing.image_path is distinct from toli_action.body->>'imagePath' then raise exception 'Message retry differs from original';end if;return private.message_json(existing);end if;
   if toli_action.body->>'imagePath' is not null and toli_action.body->>'imagePath' not like cid::text||'/'||u::text||'/%' then raise exception 'Invalid attachment owner';end if;
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
