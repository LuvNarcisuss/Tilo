import fs from 'node:fs';
import {createClient} from '@supabase/supabase-js';

const config = JSON.parse(fs.readFileSync('/private/tmp/toli-public-config.json'));
const version = fs.readFileSync('TiloApp/Tilo/Backend/TiloBackendConfiguration.swift', 'utf8').match(/agreementVersion = "([^"]+)"/)[1];
const clients = [];
const checks = [];
function check(value, name) { if (!value) throw new Error(name); checks.push(name); }
function create() { return createClient(config.url, config.key, {auth:{persistSession:false, autoRefreshToken:false}}); }
async function rpc(client, action, body = {}) {
    const result = await client.rpc('toli_action', {action, body});
    if (result.error) throw new Error('Verification RPC failed: ' + action);
    return result.data;
}
try {
    for (let index = 0; index < 2; index++) {
        const client = create();
        const login = await client.auth.signInAnonymously();
        if (login.error) throw new Error('Isolated anonymous login failed');
        clients.push({client, id:login.data.user.id});
        const bootstrap = await client.functions.invoke('bootstrap', {body:{}});
        check(!bootstrap.error && bootstrap.data.code === 0, 'Isolated member bootstrap ' + index);
        await rpc(client, 'acceptAgreements', {version, adultConfirmed:true});
    }
    const [a,b] = clients;
    const videos = await rpc(a.client, 'videos');
    const content = videos[0].id;
    const before = await rpc(a.client, 'recipeCollection', {scope:'liked'});
    const ids = [crypto.randomUUID(), crypto.randomUUID()];
    for (const id of ids) {
        const inserted = await a.client.from('room_reactions').insert({id,user_id:a.id,content_id:content}).select('id');
        check(!inserted.error && inserted.data?.[0]?.id === id, 'Distinct applause has its own returned receipt');
    }
    const own = await a.client.from('room_reactions').select('id');
    check(!own.error && own.data.length === 2, 'Repeated applause persists separately');
    const other = await b.client.from('room_reactions').select('id').eq('user_id',a.id);
    check(!other.error && other.data.length === 0, 'Another member cannot read private reaction rows');
    const forged = await b.client.from('room_reactions').insert({id:crypto.randomUUID(),user_id:a.id,content_id:content});
    check(!!forged.error, 'Another member cannot forge the sender');
    const duplicate = await a.client.from('room_reactions').insert({id:ids[0],user_id:a.id,content_id:content});
    check(!!duplicate.error, 'The same event UUID cannot create a second row');
    const missing = await a.client.from('room_reactions').insert({id:crypto.randomUUID(),user_id:a.id,content_id:'acceptance-unavailable-room'});
    check(!!missing.error, 'Unavailable room cannot receive applause');
    const changed = await a.client.from('room_reactions').update({content_id:content}).eq('id',ids[0]);
    check(!!changed.error, 'Clients cannot rewrite acknowledged applause');
    const removed = await a.client.from('room_reactions').delete().eq('id',ids[0]);
    check(!!removed.error, 'Clients cannot delete acknowledged applause');
    const anon = await create().from('room_reactions').insert({id:crypto.randomUUID(),user_id:a.id,content_id:content});
    check(!!anon.error, 'Unauthenticated insertion is denied');
    const after = await rpc(a.client, 'recipeCollection', {scope:'liked'});
    check(JSON.stringify(before) === JSON.stringify(after), 'Room applause does not change liked recipes');
} finally {
    for (const {client} of clients) {
        const result = await client.functions.invoke('delete-account', {body:{}});
        check(!result.error, 'Isolated verification account deleted through the actual endpoint');
    }
}
const evidence = {date:new Date().toISOString(), project:'hdapofqufmxlghmcrftg', checks, passed:checks.length};
fs.writeFileSync('docs/BackendAPI/room-reactions-verification.json', JSON.stringify(evidence,null,2)+'\n');
console.log(JSON.stringify({passed:checks.length, disposableAccountsDeleted:clients.length}));
