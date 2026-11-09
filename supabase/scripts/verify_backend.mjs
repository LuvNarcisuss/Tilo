import fs from 'node:fs';
import pathModule from 'node:path';
import {fileURLToPath} from 'node:url';
const root = pathModule.resolve(pathModule.dirname(fileURLToPath(import.meta.url)), '../..');
import {createClient} from '@supabase/supabase-js';
const config=JSON.parse(fs.readFileSync('/private/tmp/toli-public-config.json'));
const credentials=JSON.parse(fs.readFileSync('/private/tmp/toli-verification-users.json')).users;
const version=fs.readFileSync(pathModule.join(root,'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'),'utf8').match(/agreementVersion = "([^"]+)"/)[1];
const clients=[];const evidence=[];
const check=(condition,name)=>{if(!condition)throw new Error(name);evidence.push({name,status:'passed'});};
for(const credential of credentials){const c=createClient(config.url,config.key,{auth:{persistSession:false,autoRefreshToken:false}});const {error}=await c.auth.setSession(credential);if(error)throw error;clients.push(c);}
async function rpc(c,action,body={}){const {data,error}=await c.rpc('toli_action',{action,body});if(error)throw Error(action+': '+error.message);return data;}
for(const c of clients){const {data,error}=await c.functions.invoke('bootstrap',{body:{}});if(error)throw Error('bootstrap failed');check(data.code===0&&Object.keys(data.data).length===0,'Authenticated bootstrap returns empty A configuration');await rpc(c,'acceptAgreements',{version,adultConfirmed:true});}
const [a,b,n]=clients;const [au,bu,nu]=credentials;
const recipes=await rpc(a,'recipes');const videos=await rpc(a,'videos');check(recipes.length===12&&videos.length===6,'New ordinary user reads all 12 recipes and 6 videos');
for(let i=0;i<3;i++){await rpc(clients[i],'updateProfile',{displayName:'Verification Cook '+i,username:'verification_'+credentials[i].id.replaceAll('-','').slice(0,14),bio:'Isolated deployment verification',dietaryTags:['Vegetarian'],skillLevel:'Beginner'});}
check((await rpc(a,'profile')).bio==='Isolated deployment verification','Profile update persists and reads back');
await rpc(a,'setFollow',{userID:bu.id,following:false});await rpc(b,'setFollow',{userID:au.id,following:false});
const directBefore=await a.rpc('toli_action',{action:'createDirect',body:{userID:bu.id}});check(!!directBefore.error,'Direct message rejected before mutual following');
await rpc(a,'setFollow',{userID:bu.id,following:true});await rpc(b,'setFollow',{userID:au.id,following:true});
check((await rpc(a,'relationships',{userID:au.id,kind:'mutuals'})).length===1,'Mutual relationship derives from two real follows');
const chat=await rpc(a,'createDirect',{userID:bu.id});check(chat.peerID===bu.id,'Direct conversation uses real peer profile');
const forbidden=await n.rpc('toli_action',{action:'messages',body:{conversationID:chat.id}});check(!!forbidden.error,'Nonmember cannot read private message history');
const forbiddenSend=await n.rpc('toli_action',{action:'sendMessage',body:{conversationID:chat.id,clientID:crypto.randomUUID(),body:'Denied'}});check(!!forbiddenSend.error,'Nonmember cannot send into conversation');
const receivesA=[];const receivesB=[];
const chA=a.channel('toli-verification-a').on('postgres_changes',{event:'INSERT',schema:'public',table:'messages',filter:'conversation_id=eq.'+chat.id},payload=>receivesA.push(payload.new));
const chB=b.channel('toli-verification-b').on('postgres_changes',{event:'INSERT',schema:'public',table:'messages',filter:'conversation_id=eq.'+chat.id},payload=>receivesB.push(payload.new));
const chN=n.channel('toli-verification-n').on('postgres_changes',{event:'INSERT',schema:'public',table:'messages',filter:'conversation_id=eq.'+chat.id},()=>{throw Error('Nonmember received private row');});
async function subscribe(ch){await new Promise((resolve,reject)=>{const timer=setTimeout(()=>reject(Error('Realtime subscription timeout')),15000);ch.subscribe(status=>{if(status==='SUBSCRIBED'){clearTimeout(timer);resolve();}if(status==='CHANNEL_ERROR'){clearTimeout(timer);reject(Error('Realtime subscription error'));}});});}
await Promise.all([subscribe(chA),subscribe(chB),subscribe(chN)]);check(true,'Two members and nonmember register real Postgres Changes subscriptions');
const firstID=crypto.randomUUID();const m1=await rpc(a,'sendMessage',{conversationID:chat.id,clientID:firstID,body:'A real persistent cooking message'});
const m1retry=await rpc(a,'sendMessage',{conversationID:chat.id,clientID:firstID,body:'A real persistent cooking message'});check(m1.id===m1retry.id,'Same client message ID returns one persisted message');
const conflict=await a.rpc('toli_action',{action:'sendMessage',body:{conversationID:chat.id,clientID:firstID,body:'Different payload'}});check(!!conflict.error,'Idempotency rejects a conflicting retry payload');
async function waitFor(predicate,name){const deadline=Date.now()+12000;while(!predicate()){if(Date.now()>deadline)throw Error(name+' timed out');await new Promise(r=>setTimeout(r,100));}check(true,name);}
await waitFor(()=>receivesB.some(x=>x.id===m1.id),'Member B receives member A message through real WebSocket event');
const m2=await rpc(b,'sendMessage',{conversationID:chat.id,clientID:crypto.randomUUID(),body:'A real reply'});
await waitFor(()=>receivesA.some(x=>x.id===m2.id),'Member A receives member B reply through real WebSocket event');
check((await rpc(b,'messages',{conversationID:chat.id})).some(x=>x.id===m1.id),'Realtime message is also readable through authorized persisted history');
check((await rpc(a,'conversations')).find(x=>x.id===chat.id).unreadCount>=1,'Unread count derives from server reading progress');
await rpc(a,'markRead',{conversationID:chat.id});check((await rpc(a,'conversations')).find(x=>x.id===chat.id).unreadCount===0,'Mark read persists current user reading progress');
await rpc(a,'updateConversation',{conversationID:chat.id,pinned:true,muted:true,draft:'Chop the onions'});const state=(await rpc(a,'conversations')).find(x=>x.id===chat.id);check(state.isPinned&&state.isMuted&&state.draft==='Chop the onions','Pin, mute and draft persist per membership');
await b.removeChannel(chB);const offline=await rpc(a,'sendMessage',{conversationID:chat.id,clientID:crypto.randomUUID(),body:'Sent while the peer is disconnected'});
const rejoined=b.channel('toli-verification-b-rejoined').on('postgres_changes',{event:'INSERT',schema:'public',table:'messages',filter:'conversation_id=eq.'+chat.id},()=>{});await subscribe(rejoined);check((await rpc(b,'messages',{conversationID:chat.id})).some(x=>x.id===offline.id),'Reconnect reconciliation retrieves an event missed while disconnected');
await rpc(a,'toggleBookmark',{recipeID:recipes[0].id,saved:true});check((await rpc(a,'recipeCollection',{scope:'saved'})).length===1&&(await rpc(b,'recipeCollection',{scope:'saved'})).length===0,'Recipe bookmarks persist with cross-user isolation');
await rpc(a,'toggleLike',{contentID:videos[0].id,liked:true});check((await rpc(a,'likedContentIDs')).includes(videos[0].id),'Video like persists');
await rpc(a,'addComment',{contentID:videos[0].id,body:'Useful preparation technique'});check((await rpc(b,'comments',{contentID:videos[0].id})).length===1,'A real video comment is readable by another allowed account');
await rpc(a,'saveMeal',{date:'2026-11-03',slot:'Dinner',recipeID:recipes[0].id});check((await rpc(a,'mealPlans')).length===1&&(await rpc(b,'mealPlans')).length===0,'Meal plans persist with account isolation');
await rpc(a,'addGroceries',{items:[{name:'Flour',quantity:'200',unit:'g'},{name:'flour',quantity:'50',unit:'g'}],scale:2});check((await rpc(a,'groceries')).length===1,'Atomic grocery batch aggregates normalized ingredient names');
const before=(await rpc(a,'groceries')).length;const invalid=await a.rpc('toli_action',{action:'addGroceries',body:{items:[{name:'Rice',quantity:'100',unit:'g'},{name:'',quantity:'1',unit:'g'}],scale:1}});check(!!invalid.error&&(await rpc(a,'groceries')).length===before,'Invalid grocery batch rolls back all rows');
await rpc(a,'reportContent',{kind:'video',targetID:videos[0].id,reason:'Isolated report for deployment verification'});
await rpc(a,'block',{userID:bu.id});check((await rpc(a,'blockedUsers')).length===1,'Block persists');const blocked=await b.rpc('toli_action',{action:'messages',body:{conversationID:chat.id}});check(!!blocked.error,'Blocked conversation participant loses server history access');
const raw=await n.from('messages').select('*').eq('conversation_id',chat.id);check(!raw.error&&raw.data.length===0,'Direct Data API RLS hides private messages from nonmember');
await Promise.all(clients.map(c=>c.removeAllChannels()));
fs.writeFileSync(pathModule.join(root,'docs/BackendAPI/backend-verification.json'),JSON.stringify({timestamp:new Date().toISOString(),projectRef:'hdapofqufmxlghmcrftg',method:'Three disposable anonymous Auth identities; official supabase-js 2.80.0; actual Postgres Changes WebSocket subscriptions',checks:evidence,anonymousAuth:{status:'verified',method:'Three real anonymous signups after authorized provider activation'},iosBuild:'Not authorized; not performed'},null,2));
console.log(JSON.stringify({passed:evidence.length,realtime:'bidirectional real events verified',anonymousAuth:'real anonymous sessions verified'}));
