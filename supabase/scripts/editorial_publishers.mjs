import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {randomInt} from 'node:crypto';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const source=fs.readFileSync(path.join(root,'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'),'utf8');
const origin=source.match(/projectURL = URL\(string: "([^"]+)"/)[1];
const key=source.match(/publishableKey = "([^"]+)"/)[1];
const version=source.match(/agreementVersion = "([^"]+)"/)[1];
if(origin!=='https://hdapofqufmxlghmcrftg.supabase.co') throw Error('Unexpected project');
const journal='/private/tmp/tilo-editorial-provisioning.json';
const publicFile=path.join(root,'docs/BackendAPI/editorial-publishers.json');
const definitions=[
 ['pasta','Tilo Pasta Table','Pasta, pizza and a little Italian inspiration.',['recipe-01','recipe-04','recipe-10'],['cooking-01']],
 ['breakfast','Tilo Breakfast Club','Slow mornings and favorite breakfasts.',['recipe-02','recipe-11'],['cooking-02']],
 ['home','Tilo Home Kitchen','Comforting dinners for the everyday table.',['recipe-03','recipe-06','recipe-09'],['cooking-04']],
 ['oven','Tilo Oven Stories','Good things from a warm oven.',['recipe-12'],['cooking-05']],
 ['green','Tilo Green Kitchen','Fresh vegetables, herbs and colorful plates.',['recipe-05','recipe-07','recipe-08'],['cooking-03','cooking-06']]
];
async function request(route,body,session) {
 const response=await fetch(origin+route,{method:'POST',headers:{apikey:key,'Content-Type':'application/json',...(session?{Authorization:'Bearer '+session.access_token}:{})},body:JSON.stringify(body),signal:AbortSignal.timeout(20000)});
 const data=await response.json().catch(()=>null);
 if(!response.ok) throw Error('Provisioning request failed: '+route+' HTTP '+response.status);
 return data;
}
const command=process.argv[2];
if(command==='create') {
 if(fs.existsSync(publicFile)) throw Error('Publishers already recorded; inspect before provisioning');
 const entries=fs.existsSync(journal)?JSON.parse(fs.readFileSync(journal)):[];
 for(let i=0;i<definitions.length;i++) {
  let entry=entries[i];
  if(!entry) {
   const session=await request('/auth/v1/signup',{});
   entry={session}; entries.push(entry);
   fs.writeFileSync(journal,JSON.stringify(entries),{mode:0o600});
  }
  await request('/functions/v1/bootstrap',{},entry.session);
  await request('/rest/v1/rpc/toli_action',{action:'acceptAgreements',body:{version,adultConfirmed:true}},entry.session);
  if(!entry.publisher) {
   const [key,name,bio,recipes,videos]=definitions[i];
   entry.publisher={id:entry.session.user.id,key:'editorial-'+key,name,username:'tilo_'+key,
    bio,
    avatarURL:origin+'/storage/v1/object/public/toli-catalog/chef-0'+(i+1)+'.jpg',
    baseline:{likes:randomInt(12,27),saves:randomInt(12,27),following:randomInt(12,27),followers:randomInt(12,27)},recipes,videos};
   fs.writeFileSync(journal,JSON.stringify(entries),{mode:0o600});
  }
 }
 fs.writeFileSync('/private/tmp/tilo-editorial-public.json',JSON.stringify(entries.map(x=>x.publisher),null,2)+'\n');
 console.log(JSON.stringify({created:entries.length,ids:entries.map(x=>x.publisher.id)}));
} else if(command==='finalize') {
 const entries=JSON.parse(fs.readFileSync(journal));
 for(const entry of entries) await request('/auth/v1/logout?scope=global',{},entry.session);
 fs.copyFileSync('/private/tmp/tilo-editorial-public.json',publicFile);
 fs.unlinkSync(journal);
 fs.unlinkSync('/private/tmp/tilo-editorial-public.json');
 console.log('Publisher sessions revoked; public inventory saved.');
} else throw Error('Expected create or finalize');
