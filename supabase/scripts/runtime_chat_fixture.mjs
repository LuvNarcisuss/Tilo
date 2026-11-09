import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { createHash, randomUUID } from 'node:crypto';

// Uses one disposable public anonymous identity. Never supplies an admin key.
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const config = fs.readFileSync(path.join(root, 'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'), 'utf8');
const origin = config.match(/projectURL = URL\(string: "([^"]+)"/)[1];
const apiKey = config.match(/publishableKey = "([^"]+)"/)[1];
const version = config.match(/agreementVersion = "([^"]+)"/)[1];
if (origin !== 'https://hdapofqufmxlghmcrftg.supabase.co') throw Error('Unexpected project');
const partnerSlot = process.env.TOLI_ACCEPTANCE_PARTNER ?? 'primary';
if (!['primary', 'secondary'].includes(partnerSlot)) throw Error('Only primary and secondary acceptance partners are allowed');
const privateFile = partnerSlot === 'primary' ? '/private/tmp/toli-runtime-chat-partner.json' : '/private/tmp/toli-runtime-chat-partner-secondary.json';
const evidenceFile = process.env.TOLI_ACCEPTANCE_EVIDENCE
  ? path.resolve(process.env.TOLI_ACCEPTANCE_EVIDENCE)
  : path.join(root, 'docs/runtime-acceptance/chat-service-evidence.json');
const [command, ...args] = process.argv.slice(2);
let fixture;

function savePrivate() {
  const temporary = `${privateFile}.${process.pid}`;
  fs.writeFileSync(temporary, JSON.stringify(fixture), { mode: 0o600, flag: 'wx' });
  fs.renameSync(temporary, privateFile);
  fs.chmodSync(privateFile, 0o600);
}

function record(name, details = {}) {
  const evidence = fs.existsSync(evidenceFile) ? JSON.parse(fs.readFileSync(evidenceFile, 'utf8')) : {
    projectRef: 'hdapofqufmxlghmcrftg',
    method: 'One real anonymous partner through public Auth, bootstrap, guarded RPC and official Realtime client. No service-role key, app mock or synthetic receipt.',
    checks: [],
    nativeVerification: 'Tracked separately by the iPhone simulator acceptance run.',
  };
  evidence.checks.push({ at: new Date().toISOString(), name, ...details });
  fs.mkdirSync(path.dirname(evidenceFile), { recursive: true });
  fs.writeFileSync(evidenceFile, JSON.stringify(evidence, null, 2) + '\n');
}

async function request(route, body, token) {
  const response = await fetch(origin + route, {
    method: 'POST',
    headers: { apikey: apiKey, 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw Error(`${route}: HTTP ${response.status}: ${data.message ?? data.msg ?? data.error_description ?? data.error ?? 'Request failed'}`);
  return data;
}

async function session() {
  if (!fixture) {
    if ((fs.statSync(privateFile).mode & 0o077) !== 0) throw Error('Private fixture permissions must be 0600');
    fixture = JSON.parse(fs.readFileSync(privateFile, 'utf8'));
  }
  if (fixture.session.expires_at * 1000 < Date.now() + 120000) {
    fixture.session = await request('/auth/v1/token?grant_type=refresh_token', { refresh_token: fixture.session.refresh_token });
    fixture.session.expires_at ??= Math.floor(Date.now() / 1000) + fixture.session.expires_in;
    savePrivate();
  }
  return fixture.session.access_token;
}

async function rpc(action, body = {}) {
  return request('/rest/v1/rpc/toli_action', { action, body }, await session());
}

async function main() {
  if (command === 'create') {
    if (fs.existsSync(privateFile)) throw Error('Partner already exists; use metadata or cleanup');
    const auth = await request('/auth/v1/signup', { data: { acceptance_run: 'toli-runtime-20261103' } });
    if (!auth.user?.id || !auth.access_token || !auth.refresh_token) throw Error('Anonymous signup returned no usable session');
    auth.expires_at ??= Math.floor(Date.now() / 1000) + auth.expires_in;
    const suffix = auth.user.id.replaceAll('-', '').slice(0, 8);
    fixture = { id: auth.user.id, username: `acceptance_partner_${suffix}`, displayName: `Toli Acceptance Partner ${suffix}`, session: auth };
    savePrivate();
    const bootstrap = await request('/functions/v1/bootstrap', {}, await session());
    if (bootstrap.code !== 0 || Object.keys(bootstrap.data).length !== 0) throw Error('Unexpected bootstrap result');
    await rpc('acceptAgreements', { version, adultConfirmed: true });
    const profile = await rpc('updateProfile', { displayName: fixture.displayName, username: fixture.username, bio: 'Temporary cooking chat acceptance partner.', dietaryTags: [], skillLevel: 'Beginner' });
    if (profile.id !== fixture.id || profile.username !== fixture.username) throw Error('Profile readback mismatch');
    record('Real anonymous partner created, bootstrapped, consented and profile verified', { partnerID: fixture.id, username: fixture.username, agreementVersion: version });
    console.log(JSON.stringify({ id: fixture.id, username: fixture.username, displayName: fixture.displayName }));
  } else if (command === 'metadata') {
    await session();
    console.log(JSON.stringify({ id: fixture.id, username: fixture.username, displayName: fixture.displayName }));
  } else if (command === 'partner-follow') {
    if (!/^[0-9a-f-]{36}$/i.test(args[0] ?? '')) throw Error('Supply the actual native guest UUID');
    await rpc('setFollow', { userID: args[0], following: true });
    const following = await rpc('relationships', { kind: 'following' });
    if (!following.some(profile => profile.id.toLowerCase() === args[0].toLowerCase())) throw Error('Follow readback missing');
    fixture.nativeGuestID = args[0]; savePrivate();
    record('Partner follows actual native guest; server readback verified', { partnerID: fixture.id, nativeGuestID: args[0] });
    console.log(JSON.stringify({ following: args[0], verified: true }));
  } else if (command === 'search') {
    console.log(JSON.stringify(await rpc('searchUsers', { query: args.join(' ') })));
  } else if (command === 'avatar') {
    const profiles = await rpc('searchUsers', { query: args[0] });
    const profile = profiles.find(item => item.username === args[0]);
    if (!profile?.avatarURL?.startsWith(`${origin}/storage/v1/object/public/avatars/${profile.id.toLowerCase()}/`)) throw Error('Expected profile-owned project avatar URL was not found');
    const response = await fetch(profile.avatarURL, { signal: AbortSignal.timeout(20000) });
    if (!response.ok) throw Error(`Anonymous avatar download HTTP ${response.status}`);
    const bytes = Buffer.from(await response.arrayBuffer());
    if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8 || bytes[2] !== 0xff) throw Error('Public avatar is not actual JPEG data');
    const details = { userID: profile.id, username: profile.username, avatarURL: profile.avatarURL, byteCount: bytes.length, contentType: response.headers.get('content-type'), sha256: createHash('sha256').update(bytes).digest('hex'), downloadedWithoutCredentials: true };
    record('Partner reads native-updated project-owned avatar and anonymous download verifies actual JPEG bytes', details);
    console.log(JSON.stringify(details));
  } else if (command === 'recipes') {
    const query = args.join(' ');
    const recipes = await rpc('recipes', { query, offset: 0 });
    const titles = recipes.map(recipe => ({ id: recipe.id, title: recipe.title }));
    record('Partner reads actual native-equivalent recipe search RPC', { query, recipes: titles });
    console.log(JSON.stringify({ query, recipes: titles }));
  } else if (command === 'observe-recipe' || command === 'observe-recipe-id') {
    const expectedID = command === 'observe-recipe-id' ? args.shift() : undefined;
    const query = args.join(' ');
    await session();
    if (!fixture.nativeGuestID) throw Error('Known native guest UUID is required');
    const maximumSeconds = Math.min(600, Math.max(5, Number(process.env.TOLI_ACCEPTANCE_OBSERVE_SECONDS ?? 180)));
    if (!Number.isFinite(maximumSeconds)) throw Error('Observation duration must be finite');
    const deadline = Date.now() + maximumSeconds * 1000;
    const observed = new Map();
    if (expectedID) {
      const prior = JSON.parse(fs.readFileSync(evidenceFile, 'utf8')).checks.filter(check => check.recipeID === expectedID && check.authorID === fixture.nativeGuestID && check.title).at(-1);
      if (!prior) throw Error('Expected recipe has no prior verified publication evidence');
      observed.set(expectedID, prior.title);
    }
    let revised = false;
    let absent = false;
    console.log(JSON.stringify({ observingQuery: query, maximumSeconds, nativeGuestID: fixture.nativeGuestID, priorVerifiedRecipeID: expectedID }));
    while (Date.now() < deadline) {
      const recipes = await rpc('recipes', { query, offset: 0 });
      const relevant = recipes.filter(recipe => (!expectedID || recipe.id === expectedID) && (!recipe.authorID || recipe.authorID.toLowerCase() === fixture.nativeGuestID.toLowerCase()) && recipe.imageURL?.startsWith(`${origin}/storage/v1/object/public/recipe-photos/${fixture.nativeGuestID.toLowerCase()}/`));
      for (const recipe of relevant) {
        if (observed.get(recipe.id) === recipe.title) continue;
        const works = await rpc('recipeCollection', { scope: 'works', userID: fixture.nativeGuestID });
        if (!works.some(work => work.id === recipe.id)) continue;
        const first = !observed.has(recipe.id);
        if (!first) revised = true;
        observed.set(recipe.id, recipe.title);
        const details = { recipeID: recipe.id, title: recipe.title, photoURL: recipe.imageURL, authorID: fixture.nativeGuestID, ownershipEvidence: 'Same recipe ID independently returned by guarded recipeCollection works for the native guest', stage: first ? 'published' : 'edited' };
        record('Ordinary partner observes native recipe publish/edit with verified author works ownership', details);
        console.log(JSON.stringify(details));
      }
      if (observed.size && [...observed.keys()].every(id => !relevant.some(recipe => recipe.id === id))) {
        const works = await rpc('recipeCollection', { scope: 'works', userID: fixture.nativeGuestID });
        if ([...observed.keys()].every(id => !works.some(recipe => recipe.id === id))) {
          absent = true;
          const details = { recipeIDs: [...observed.keys()], query, revisedObserved: revised, absentFromSearchAndAuthorWorks: true };
          record('Previously observed native recipe is absent from guarded search and its author works after native deletion', details);
          console.log(JSON.stringify(details));
          break;
        }
      }
      await new Promise(resolve => setTimeout(resolve, 1500));
    }
    const summary = { observedRecipeIDs: [...observed.keys()], revisedObserved: revised, absenceObserved: absent, finishedAt: new Date().toISOString() };
    record('Finite read-only native recipe observation ended', summary);
    console.log(JSON.stringify(summary));
  } else if (command === 'conversations') {
    const conversations = await rpc('conversations');
    record('Partner reads authorized conversation list', { conversationIDs: conversations.map(c => c.id) });
    console.log(JSON.stringify(conversations));
  } else if (command === 'send') {
    if (!args[0] || !args[1]) throw Error('Usage: send CONVERSATION_UUID MESSAGE');
    const message = await rpc('sendMessage', { conversationID: args[0], clientID: randomUUID(), body: args.slice(1).join(' ') });
    const history = await rpc('messages', { conversationID: args[0] });
    if (!history.some(item => item.id === message.id && item.body === message.body)) throw Error('Sent message absent in persisted history');
    record('Partner sends message and independently reads its persisted history', { message });
    console.log(JSON.stringify(message));
  } else if (command === 'read') {
    const messages = await rpc('messages', { conversationID: args[0] });
    record('Partner reads authorized persisted chat history', { conversationID: args[0], messages });
    console.log(JSON.stringify(messages));
  } else if (command === 'members') {
    const members = await rpc('conversationMembers', { conversationID: args[0] });
    record('Partner reads authorized conversation membership projection', { conversationID: args[0], members: members.map(member => ({ id: member.id, username: member.username })) });
    console.log(JSON.stringify(members.map(member => ({ id: member.id, username: member.username }))));
  } else if (command === 'expect-denied') {
    for (const action of ['messages', 'conversationMembers']) {
      let denial;
      try { await rpc(action, { conversationID: args[0] }); }
      catch (error) { denial = error.message; }
      if (!denial?.includes('Conversation access denied')) throw Error(`${action} did not return the expected conversation access denial`);
      record('Former group partner receives server access denial after native removal and owner leave', { conversationID: args[0], action, error: denial });
      console.log(JSON.stringify({ conversationID: args[0], action, denied: true }));
    }
  } else if (command === 'attachments') {
    const messages = await rpc('messages', { conversationID: args[0] });
    const images = messages.filter(message => message.imagePath);
    if (!images.length) throw Error('No persisted photo message in this conversation');
    await rpc('conversationMembers', { conversationID: args[0] });
    for (const message of images) {
      const signed = await request(`/storage/v1/object/sign/chat-images/${message.imagePath}`, { expiresIn: 300 }, await session());
      if (!signed.signedURL?.startsWith('/object/sign/chat-images/')) throw Error('Unexpected signed attachment route');
      const download = await fetch(origin + '/storage/v1' + signed.signedURL, { signal: AbortSignal.timeout(20000) });
      if (!download.ok) throw Error(`Private attachment download HTTP ${download.status}`);
      const bytes = Buffer.from(await download.arrayBuffer());
      if (bytes.length < 4 || bytes[0] !== 0xff || bytes[1] !== 0xd8 || bytes[2] !== 0xff) throw Error('Private photo is not actual JPEG data');
      const details = { messageID: message.id, senderID: message.senderID, conversationID: message.conversationID, imagePath: message.imagePath, byteCount: bytes.length, contentType: download.headers.get('content-type'), sha256: createHash('sha256').update(bytes).digest('hex'), signedURLLifetimeSeconds: 300 };
      record('Authorized real partner signs and downloads actual persisted private JPEG attachment', details);
      console.log(JSON.stringify(details));
    }
  } else if (command === 'watch' || command === 'auto-reply') {
    const seconds = Math.min(600, Math.max(5, Number(args[1] ?? 90)));
    await session();
    const require = createRequire(process.env.TOLI_SUPABASE_PACKAGE ?? '/private/tmp/toli-backend-check/package.json');
    const { createClient } = require('@supabase/supabase-js');
    const client = createClient(origin, apiKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { error } = await client.auth.setSession(fixture.session);
    if (error) throw Error('Partner Realtime session setup failed');
    const oldIDs = new Set((await rpc('messages', { conversationID: args[0] })).map(message => message.id));
    let handled = false;
    let completeReply;
    let rejectReply;
    const replyCompleted = new Promise((resolve, reject) => { completeReply = resolve; rejectReply = reject; });
    // Attach a rejection observer before subscription; callback errors must not become unhandled rejections.
    replyCompleted.catch(() => {});
    const channel = client.channel(`toli-native-acceptance-${randomUUID()}`).on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: `conversation_id=eq.${args[0]}` }, payload => {
      const message = payload.new;
      if (oldIDs.has(message.id)) return;
      oldIDs.add(message.id);
      if (command === 'auto-reply') {
        if (handled || message.sender_id === fixture.id || message.body !== 'Toli acceptance realtime ready') return;
        if (fixture.nativeGuestID && message.sender_id.toLowerCase() !== fixture.nativeGuestID.toLowerCase()) return;
        handled = true;
        const receivedAt = new Date().toISOString();
        (async () => {
          const reply = await rpc('sendMessage', { conversationID: args[0], clientID: randomUUID(), body: 'Toli acceptance partner reply' });
          const acknowledgedAt = new Date().toISOString();
          record('Partner receives a new native ready message over real WebSocket and sends a real RPC reply', { conversationID: args[0], receivedMessageID: message.id, receivedAt, serverCreatedAt: message.created_at, replyMessageID: reply.id, acknowledgedAt, replyMilliseconds: Date.parse(acknowledgedAt) - Date.parse(receivedAt) });
          console.log(JSON.stringify({ receivedMessageID: message.id, receivedAt, serverCreatedAt: message.created_at, replyMessageID: reply.id, acknowledgedAt, replyMilliseconds: Date.parse(acknowledgedAt) - Date.parse(receivedAt) }));
          completeReply();
        })().catch(rejectReply);
        return;
      }
      record('Partner receives real Postgres Changes INSERT over WebSocket', { messageID: message.id, conversationID: message.conversation_id, senderID: message.sender_id, body: message.body });
      console.log(JSON.stringify({ realtimeMessageID: message.id, senderID: message.sender_id, body: message.body }));
    });
    try {
      await new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(Error('Realtime subscription timed out')), 15000);
        channel.subscribe(status => {
          if (status === 'SUBSCRIBED') { clearTimeout(timeout); resolve(); }
          else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') { clearTimeout(timeout); reject(Error(`Realtime ${status}`)); }
        });
      });
      record('Partner real WebSocket subscription acknowledged', { conversationID: args[0] });
      console.log(JSON.stringify({ subscribed: args[0], seconds }));
      if (command === 'auto-reply') {
        let deadline;
        try {
          await Promise.race([replyCompleted, new Promise((_, reject) => { deadline = setTimeout(() => reject(Error('No new native ready message received before deadline')), seconds * 1000); })]);
        } finally { clearTimeout(deadline); }
      } else await new Promise(resolve => setTimeout(resolve, seconds * 1000));
    } finally { await client.removeAllChannels(); }
  } else if (command === 'cleanup') {
    await session();
    const id = fixture.id;
    const result = await request('/functions/v1/delete-account', {}, await session());
    if (Object.keys(result).length !== 0) throw Error('Unexpected account deletion response');
    let denied = false;
    try { await rpc('profile'); } catch (error) { denied = /Authentication required|401|403/.test(error.message); }
    if (!denied) throw Error('Deleted identity still has business access');
    fs.unlinkSync(privateFile);
    record('Only acceptance partner deleted through real self-service endpoint; stale-token business access rejected and private credentials removed', { partnerID: id });
    console.log(JSON.stringify({ deletedPartnerID: id, privateCredentialsRemoved: true }));
  } else throw Error('Commands: create, metadata, partner-follow UUID, search QUERY, avatar USERNAME, recipes QUERY, observe-recipe QUERY, observe-recipe-id RECIPE_ID QUERY, conversations, send CONVERSATION_UUID MESSAGE, read CONVERSATION_UUID, members CONVERSATION_UUID, expect-denied CONVERSATION_UUID, attachments CONVERSATION_UUID, watch CONVERSATION_UUID [SECONDS], auto-reply CONVERSATION_UUID [SECONDS], cleanup. Select secondary partner with TOLI_ACCEPTANCE_PARTNER=secondary.');
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
