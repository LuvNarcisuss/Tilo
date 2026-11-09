import fs from 'node:fs';
import pathModule from 'node:path';
import {fileURLToPath} from 'node:url';
const root = pathModule.resolve(pathModule.dirname(fileURLToPath(import.meta.url)), '../..');
import {createClient} from '@supabase/supabase-js';
const c=JSON.parse(fs.readFileSync('/private/tmp/toli-public-config.json'));
const sessions=JSON.parse(fs.readFileSync('/private/tmp/toli-verification-users.json')).users;
const version=fs.readFileSync(pathModule.join(root,'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'),'utf8').match(/agreementVersion = "([^"]+)"/)[1];
const result=[];const check=(ok,name)=>{if(!ok)throw Error(name);result.push({name,status:'passed'});};
const a=createClient(c.url,c.key,{auth:{persistSession:false,autoRefreshToken:false}});await a.auth.setSession(sessions[0]);
let r=await a.rpc('toli_action',{action:'acceptAgreements',body:{version,adultConfirmed:true}});check(!r.error,'Exact content-derived agreement version accepted');
r=await a.rpc('toli_action',{action:'acceptAgreements',body:{version:'2026-11-03',adultConfirmed:true}});check(!!r.error,'Outdated date-only agreement version rejected');
r=await a.rpc('toli_action',{action:'acceptAgreements',body:{version,adultConfirmed:false}});check(!!r.error,'Adult confirmation false rejected');
const unauth=await fetch(c.url+'/functions/v1/delete-account',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});check(unauth.status===401,'Delete-account rejects a request without a user session');
for(const credential of [...sessions].reverse()){
 const request=await fetch(c.url+'/functions/v1/delete-account',{method:'POST',headers:{apikey:c.key,Authorization:'Bearer '+credential.access_token,'Content-Type':'application/json'},body:'{}'});
 check(request.ok,'Account deletion removes isolated account '+(sessions.indexOf(credential)+1));
 const old=createClient(c.url,c.key,{auth:{persistSession:false,autoRefreshToken:false},global:{headers:{Authorization:'Bearer '+credential.access_token}}});
 const probe=await old.rpc('toli_action',{action:'profile',body:{}});check(!!probe.error,'Deleted account token cannot perform guarded business operations');
}
const path=pathModule.join(root,'docs/BackendAPI/backend-verification.json');const report=JSON.parse(fs.readFileSync(path));report.checks.push(...result);report.cleanup={status:'Three disposable accounts deleted through the real delete-account endpoint; database and owned media cleanup verified separately'};report.completedAt=new Date().toISOString();fs.writeFileSync(path,JSON.stringify(report,null,2));console.log(JSON.stringify({additionalPassed:result.length,totalPassed:report.checks.length,disposableAccountsDeleted:3}));
await a.removeAllChannels();
