import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomUUID} from 'node:crypto';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const source=fs.readFileSync(path.join(root,'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'),'utf8');
const origin=source.match(/projectURL = URL\(string: "([^"]+)"/)[1];
const key=source.match(/publishableKey = "([^"]+)"/)[1];
const version=source.match(/agreementVersion = "([^"]+)"/)[1];
if(origin!=='https://hdapofqufmxlghmcrftg.supabase.co') throw Error('Unexpected project');
const sessions=[],checks=[];
const check=(ok,name)=>{if(!ok)throw Error(name);checks.push(name);};
async function request(route,body,session) {
 const r=await fetch(origin+route,{method:'POST',headers:{apikey:key,'Content-Type':'application/json',...(session?{Authorization:'Bearer '+session.access_token}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
 return {ok:r.ok,status:r.status,data:await r.json().catch(()=>null)};
}
async function call(route,body,session) {const r=await request(route,body,session);if(!r.ok)throw Error('HTTP '+r.status+' '+route+' '+(r.data?.message??''));return r.data;}
const rpc=(s,action,body={})=>call('/rest/v1/rpc/toli_action',{action,body},s);
async function denied(s,action,body,label) {const r=await request('/rest/v1/rpc/toli_action',{action,body},s);check(!r.ok,label);}
async function create() {
 const s=await call('/auth/v1/signup',{});sessions.push(s);
 await call('/functions/v1/bootstrap',{},s);
 await rpc(s,'acceptAgreements',{version,adultConfirmed:true});return s;
}
try {
 const a=await create(),b=await create();
 const recipes=await rpc(a,'recipes'),videos=await rpc(a,'videos');
 check(recipes.length===12&&recipes.every(x=>x.publisher?.id&&x.publisher.isEditorial),'All twelve recipe avatars resolve real editorial publisher IDs');
 check(videos.length===6&&videos.every(x=>x.publisher?.id&&x.publisher.isEditorial),'All six replay avatars resolve real editorial publisher IDs');
 const publisher=recipes[0].publisher;
 const p=await rpc(a,'profile',{userID:publisher.id});
 check(p.id===publisher.id&&p.avatarURL===publisher.avatarURL,'Card and profile share stable publisher identity and portrait');
 check(Object.values(p.displayBaseline).every(x=>x>=12&&x<=26),'Illustrative baselines remain in authorized small range');
 check(JSON.stringify(p.displayBaseline)===JSON.stringify((await rpc(a,'profile',{userID:publisher.id})).displayBaseline),'Refresh does not randomize baselines');
 check((await rpc(a,'relationships',{userID:publisher.id,kind:'following'})).length===0,'Illustrative following creates no fabricated follow rows');
 const mine=await rpc(a,'profile');
 check(!mine.isEditorial&&mine.displayBaseline===null&&mine.likesCount===0&&mine.savesCount===0&&mine.followingCount===0,'Ordinary new members have actual zero statistics');
 await rpc(a,'updateProfile',{displayName:'Profile verification cook',username:mine.username,bio:'',dietaryTags:[],skillLevel:'',publisher_key:'forged',display_baseline:{likes:20,saves:20,following:20,followers:20}});
 check(!(await rpc(a,'profile')).isEditorial&&(await rpc(a,'profile')).displayBaseline===null,'Member profile RPC cannot grant editorial baselines');
 await denied(a,'createDirect',{userID:b.user.id},'Direct conversation rejected before following');
 await rpc(a,'setFollow',{userID:b.user.id,following:true});
 check((await rpc(a,'relationships',{kind:'mutuals'})).length===0,'One-way follow remains separate from mutual friends');
 const conversation=await rpc(a,'createDirect',{userID:b.user.id});
 check(!!conversation.id,'One-way follow can create direct conversation');
 const messageBody={conversationID:conversation.id,clientID:randomUUID(),body:'Publisher flow verification'};
 const sent=await rpc(a,'sendMessage',messageBody);
 check(!!sent.id,'One-way follower can send a real persisted message');
 check((await rpc(a,'sendMessage',messageBody)).id===sent.id,'Retried direct send remains idempotent');
 check((await rpc(b,'messages',{conversationID:conversation.id})).some(x=>x.id===sent.id),'Recipient reads actual incoming history without following back');
 await denied(b,'sendMessage',{conversationID:conversation.id,clientID:randomUUID(),body:'Must follow first'},'Recipient cannot reply until following sender');
 const groupDenied=await request('/rest/v1/rpc/toli_action',{action:'createGroup',body:{title:'Unauthorized group',memberIDs:[b.user.id,publisher.id]}},a);
 check(!groupDenied.ok&&groupDenied.data?.message==='Invite mutual followers only','Group invitations retain mutual-follow requirement');
 await rpc(b,'setFollow',{userID:a.user.id,following:true});
 check(!!(await rpc(b,'sendMessage',{conversationID:conversation.id,clientID:randomUUID(),body:'Following sender permits reply'})).id,'Following sender enables recipient reply');
 await rpc(a,'setFollow',{userID:b.user.id,following:false});
 await denied(a,'sendMessage',{conversationID:conversation.id,clientID:randomUUID(),body:'Unfollowed'},'Unfollowing revokes new sends in existing conversation');
 check((await rpc(a,'messages',{conversationID:conversation.id})).length===2,'Authorized history survives unfollow');
 await rpc(a,'setFollow',{userID:publisher.id,following:true});
 const updated=await rpc(a,'profile',{userID:publisher.id});
 check(updated.followersCount===p.followersCount+1&&JSON.stringify(updated.displayBaseline)===JSON.stringify(p.displayBaseline),'Actual follower increment is separate from stable illustrative baseline');
 await rpc(a,'setFollow',{userID:publisher.id,following:false});
 await rpc(a,'block',{userID:publisher.id});
 check(!(await rpc(a,'recipes')).some(x=>x.publisher?.id===publisher.id),'Blocking publisher removes their recipe cards');
 check(!(await rpc(a,'videos')).some(x=>x.publisher?.id===publisher.id),'Blocking publisher removes their replay cards');
 await denied(a,'profile',{userID:publisher.id},'Blocked publisher profile is inaccessible');
 await rpc(a,'unblock',{userID:publisher.id});
 check((await rpc(a,'recipes')).length===12,'Unblock restores editorial catalog without changing content IDs');
 await rpc(a,'block',{userID:b.user.id});
 await denied(a,'messages',{conversationID:conversation.id},'Blocking participant revokes private history access');
 await denied(b,'sendMessage',{conversationID:conversation.id,clientID:randomUUID(),body:'Blocked'},'Blocked participant cannot send');
 check((await rpc(a,'recipes',{query:'Tilo Pasta Table'})).length===3,'Publisher search queries actual recipe ownership');
} finally {
 for(const session of sessions) await call('/functions/v1/delete-account',{},session);
}
const result={project:'hdapofqufmxlghmcrftg',date:new Date().toISOString(),passed:checks.length,checks,cleanup:'Both disposable verification Auth identities deleted; editorial publishers retained.'};
fs.writeFileSync(process.env.TILO_ACCEPTANCE_OUTPUT ?? path.join(root,'docs/BackendAPI/publisher-profile-verification.json'),JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify(result));
