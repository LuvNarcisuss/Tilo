import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomUUID} from 'node:crypto';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const source = fs.readFileSync(path.join(root,'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'),'utf8');
const origin = source.match(/projectURL = URL\(string: "([^"]+)"/)[1];
const key = source.match(/publishableKey = "([^"]+)"/)[1];
const version = source.match(/agreementVersion = "([^"]+)"/)[1];
if (origin !== 'https://hdapofqufmxlghmcrftg.supabase.co') throw Error('Unexpected project');
const privateFile = '/private/tmp/tilo-content-safety-fixture.json';
const checks = [];
const check = (condition,name) => { if(!condition) throw Error(name); checks.push(name); };
async function request(route, body, session, method='POST') {
    const response = await fetch(origin+route,{method,headers:{apikey:key,'Content-Type':'application/json',...(session?{Authorization:'Bearer '+session.access_token}:{})},body:method==='GET'?undefined:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
    const data = await response.json().catch(()=>null);
    return {ok:response.ok,data,status:response.status};
}
async function call(session,route,body) { const result=await request(route,body,session); if(!result.ok) throw Error('Verification request failed: '+route+' HTTP '+result.status+' '+(result.data?.code??'')+' '+(result.data?.message??'')); return result.data; }
const rpc = (s,action,body={})=>call(s,'/rest/v1/rpc/toli_action',{action,body});
const safety = (s,action,body={})=>call(s,'/rest/v1/rpc/toli_safety',{action,body});
async function create() {
    const session = await call(null,'/auth/v1/signup',{});
    await call(session,'/functions/v1/bootstrap',{});
    await rpc(session,'acceptAgreements',{version,adultConfirmed:true});
    return session;
}
async function publish(session,title) {
    const recipe=(await rpc(session,'recipes'))[0];
    const photo=await fetch(recipe.imageURL,{signal:AbortSignal.timeout(20000)});
    if(!photo.ok) throw Error('Real cooking photo unavailable');
    const object=session.user.id+'/'+randomUUID()+'.jpg';
    const upload=await fetch(origin+'/storage/v1/object/recipe-photos/'+object,{method:'POST',headers:{apikey:key,Authorization:'Bearer '+session.access_token,'Content-Type':'image/jpeg'},body:await photo.arrayBuffer(),signal:AbortSignal.timeout(20000)});
    if(!upload.ok) throw Error('Owned cooking photo upload failed');
    return rpc(session,'publishRecipe',{id:randomUUID(),title,category:recipe.category,imageURL:origin+'/storage/v1/object/public/recipe-photos/'+object,payload:recipe.payload});
}
async function remove(session) { await call(session,'/functions/v1/delete-account',{}); }
const command=process.argv[2]??'verify';
if(command==='verify') {
    const sessions=[];
    try {
        const a=await create(); sessions.push(a);
        const b=await create(); sessions.push(b);
        const base=(await rpc(a,'recipes'))[0], video=(await rpc(a,'videos'))[0];
        check(!!(await safety(a,'context',{kind:'recipe',id:base.id})).authorID,'Editorial recipe resolves its authorized publisher');
        const own=await publish(b,'Content safety verification recipe');
        const context=await safety(a,'context',{kind:'recipe',id:own.id});
        check(context.authorID===b.user.id&&!context.isOwn,'Member recipe resolves the actual publisher');
        check((await safety(b,'context',{kind:'recipe',id:own.id})).isOwn,'Owner context is explicit');
        const selfBlock=await request('/rest/v1/rpc/toli_safety',{action:'blockAuthor',body:{kind:'recipe',id:own.id}},b);
        check(!selfBlock.ok,'Self-blocking rejected');
        await rpc(b,'addComment',{contentID:base.id,body:'Content safety verification note'});
        const comment=(await rpc(a,'comments',{contentID:base.id})).find(x=>x.userID===b.user.id);
        check((await safety(a,'context',{kind:'comment',id:comment.id})).authorID===b.user.id,'Comment resolves the actual author');
        for(const [kind,id] of [['recipe',own.id],['comment',comment.id],['profile',b.user.id],['video',video.id]]) {
            await safety(a,'report',{kind,id,reason:'Isolated content safety verification'});
        }
        const reports=await request('/rest/v1/reports?select=content_kind,content_id',null,a,'GET');
        check(reports.ok&&reports.data.length===4,'Recipe, replay, comment and profile reports persist');
        for(const [kind,item,action] of [['recipe',base,'recipes'],['video',video,'videos']]) {
            await safety(a,'hide',{kind,id:item.id});
            check(!(await rpc(a,action)).some(x=>x.id===item.id),'Hidden '+kind+' removed from RPC discovery');
            const table=kind==='recipe'?'recipes':'cooking_videos';
            const direct=await request('/rest/v1/'+table+'?select=id&id=eq.'+item.id,null,a,'GET');
            check(direct.ok&&direct.data.length===0,'Hidden '+kind+' excluded by RLS');
            check((await rpc(b,action)).some(x=>x.id===item.id),'Hidden '+kind+' does not affect another account');
            if(kind==='video') {
                const denied=await request('/rest/v1/room_reactions',{id:randomUUID(),user_id:a.user.id,content_id:item.id},a);
                check(!denied.ok,'Hidden replay cannot receive a room reaction');
            }
            check((await safety(a,'hidden')).some(x=>x.id===item.id),'Hidden '+kind+' can be managed');
            await safety(a,'unhide',{kind,id:item.id});
            check((await rpc(a,action)).some(x=>x.id===item.id),'Restored '+kind+' reappears');
        }
        const fake=await request('/rest/v1/rpc/toli_safety',{action:'report',body:{kind:'recipe',id:'unavailable-safety-content',reason:'Rejected target'}},a);
        check(!fake.ok,'Missing report target rejected');
        const unauthenticated=await request('/rest/v1/rpc/toli_safety',{action:'hidden',body:{}},null);
        check(!unauthenticated.ok,'Unauthenticated safety calls rejected');
        const forged=await request('/rest/v1/content_hides',{user_id:b.user.id,kind:'recipe',content_id:base.id},a);
        check(!forged.ok,'Direct forged preference write rejected');
        await rpc(a,'toggleLike',{contentID:own.id,liked:true});
        await rpc(a,'toggleBookmark',{recipeID:own.id,saved:true});
        await rpc(a,'setFollow',{userID:b.user.id,following:true});
        await rpc(b,'setFollow',{userID:a.user.id,following:true});
        const conversation=await rpc(a,'createDirect',{userID:b.user.id});
        await safety(a,'blockAuthor',{kind:'recipe',id:own.id});
        check(!(await rpc(a,'recipes')).some(x=>x.id===own.id),'Blocked author disappears from discovery');
        for(const scope of ['saved','liked']) check(!(await rpc(a,'recipeCollection',{scope})).some(x=>x.id===own.id),'Blocked author disappears from '+scope);
        check(!(await rpc(a,'comments',{contentID:base.id})).some(x=>x.userID===b.user.id),'Blocked comments disappear');
        const denied=await request('/rest/v1/rpc/toli_action',{action:'messages',body:{conversationID:conversation.id}},a);
        check(!denied.ok,'Content-author block revokes chat access');
        check(!(await rpc(a,'relationships',{userID:a.user.id,kind:'following'})).some(x=>x.id===b.user.id),'Content-author block removes follows');
        await rpc(a,'unblock',{userID:b.user.id});
        check((await rpc(a,'recipeCollection',{scope:'liked'})).some(x=>x.id===own.id),'Unblocking preserves the prior recipe favorite');
        check((await rpc(a,'recipeCollection',{scope:'saved'})).some(x=>x.id===own.id),'Unblocking preserves the prior recipe save');
    } finally { for(const session of sessions) { await remove(session); check(true,'Disposable verification account deleted'); } }
    fs.writeFileSync(process.env.TILO_ACCEPTANCE_OUTPUT ?? path.join(root,'docs/BackendAPI/content-safety-verification.json'),JSON.stringify({date:new Date().toISOString(),project:'hdapofqufmxlghmcrftg',passed:checks.length,checks},null,2)+'\n');
    console.log(JSON.stringify({passed:checks.length}));
} else if(command==='verify-replay') {
    const fixture=JSON.parse(fs.readFileSync(privateFile));
    const session=await create();
    try {
        const body={kind:'video',id:'safety-acceptance-replay'};
        const context=await safety(session,'context',body);
        check(context.authorID===fixture.session.user.id,'Replay resolves the real publisher');
        await safety(session,'report',{...body,reason:'Isolated member replay safety verification'});
        check(true,'Member-owned replay report acknowledged');
        await safety(session,'blockAuthor',body);
        check(!(await rpc(session,'videos')).some(x=>x.id===body.id),'Blocked publisher replay removed from discovery');
        const direct=await request('/rest/v1/cooking_videos?select=id&id=eq.'+body.id,null,session,'GET');
        check(direct.ok&&direct.data.length===0,'Blocked publisher replay excluded by RLS');
        const reaction=await request('/rest/v1/room_reactions',{id:randomUUID(),user_id:session.user.id,content_id:body.id},session);
        check(!reaction.ok,'Blocked replay refuses applause');
        check(!(await rpc(session,'recipes')).some(x=>x.id===fixture.recipeID),'Replay publisher block also filters their recipes');
        await rpc(session,'unblock',{userID:fixture.session.user.id});
        check((await rpc(session,'videos')).some(x=>x.id===body.id),'Unblocked publisher replay restored');
    } finally { await remove(session); check(true,'Replay verification account deleted'); }
    const target=path.join(root,'docs/BackendAPI/content-safety-verification.json');
    const prior=JSON.parse(fs.readFileSync(target)); prior.checks.push(...checks); prior.passed=prior.checks.length; prior.date=new Date().toISOString();
    fs.writeFileSync(target,JSON.stringify(prior,null,2)+'\n');
    console.log(JSON.stringify({additionalPassed:checks.length,totalPassed:prior.passed}));
} else if(command==='prepare') {
    if(fs.existsSync(privateFile)) throw Error('A fixture already exists; reuse or clean it explicitly');
    const session=await create();
    fs.writeFileSync(privateFile,JSON.stringify({session}),{mode:0o600,flag:'wx'});
    await rpc(session,'updateProfile',{displayName:'Safety Acceptance Cook',username:'safety_'+session.user.id.replaceAll('-','').slice(0,15),bio:'Isolated safety acceptance account',dietaryTags:[],skillLevel:'Beginner'});
    const recipe=await publish(session,'Safety acceptance recipe');
    await rpc(session,'addComment',{contentID:'recipe-01',body:'Safety acceptance recipe note'});
    await rpc(session,'addComment',{contentID:'cooking-01',body:'Safety acceptance room note'});
    fs.writeFileSync(privateFile,JSON.stringify({session,recipeID:recipe.id}),{mode:0o600});
    console.log(JSON.stringify({publisherID:session.user.id,recipeID:recipe.id}));
} else if(command==='cleanup') {
    if((fs.statSync(privateFile).mode&0o077)!==0) throw Error('Fixture permissions must be private');
    const fixture=JSON.parse(fs.readFileSync(privateFile));
    await remove(fixture.session); fs.unlinkSync(privateFile);
    console.log(JSON.stringify({disposablePublisherDeleted:true}));
} else throw Error('Unsupported finite verification command');
