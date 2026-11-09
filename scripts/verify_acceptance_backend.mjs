// Finite acceptance checks using disposable anonymous accounts and public client access only.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';
import { randomUUID, createHash } from 'node:crypto';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const output = path.resolve(process.argv[2] ?? 'docs/runtime-acceptance/backend-acceptance.json');
const config = fs.readFileSync(path.join(root, 'TiloApp/Tilo/Backend/TiloBackendConfiguration.swift'), 'utf8');
const origin = config.match(/projectURL = URL\(string: "([^"]+)"/)[1];
const key = config.match(/publishableKey = "([^"]+)"/)[1];
const version = config.match(/agreementVersion = "([^"]+)"/)[1];
if (origin !== 'https://hdapofqufmxlghmcrftg.supabase.co') throw Error('Unexpected backend project');
const require = createRequire(process.env.TOLI_SUPABASE_PACKAGE ?? '/private/tmp/toli-backend-check/package.json');
const { createClient } = require('@supabase/supabase-js');
const clients = [];
const sessions = [];
const evidence = { startedAt: new Date().toISOString(), projectRef: 'hdapofqufmxlghmcrftg', checks: [], cleanup: [], errors: [] };
const client = () => createClient(origin, key, { auth: { persistSession: false, autoRefreshToken: false } });
function save() { fs.mkdirSync(path.dirname(output), { recursive: true }); fs.writeFileSync(output, JSON.stringify(evidence, null, 2) + '\n'); }
function check(condition, name, details = {}) {
  evidence.checks.push({ at: new Date().toISOString(), name, result: condition ? 'passed' : 'failed', ...details });
  save();
  if (!condition) throw Error(name);
}
async function rpc(c, action, body = {}) {
  const { data, error } = await c.rpc('toli_action', { action, body });
  if (error) throw Error(action + ': ' + error.message);
  return data;
}
async function denied(c, action, body, name) {
  const { error } = await c.rpc('toli_action', { action, body });
  check(!!error, name, { serverError: error?.message });
}
async function subscribe(channel) {
  await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(Error('Realtime subscription timed out')), 15000);
    channel.subscribe(status => {
      if (status === 'SUBSCRIBED') { clearTimeout(timer); resolve(); }
      else if (['CHANNEL_ERROR', 'TIMED_OUT', 'CLOSED'].includes(status)) { clearTimeout(timer); reject(Error('Realtime ' + status)); }
    });
  });
}
async function waitFor(predicate, name) {
  const deadline = Date.now() + 15000;
  while (!predicate() && Date.now() < deadline) await new Promise(resolve => setTimeout(resolve, 100));
  check(predicate(), name);
}

try {
  await denied(client(), 'profile', {}, 'Unauthenticated business access is rejected');
  for (let index = 0; index < 3; index++) {
    const c = client(); clients.push(c);
    const { data, error } = await c.auth.signInAnonymously({ options: { data: { acceptance_run: path.basename(path.dirname(output)) } } });
    if (error) throw Error('Anonymous signup: ' + error.message);
    sessions.push(data.session);
    check(!!data.user?.is_anonymous, 'Disposable anonymous identity created ' + index, { userID: data.user.id });
    const boot = await c.functions.invoke('bootstrap', { body: {} });
    check(!boot.error && boot.data?.code === 0 && Object.keys(boot.data.data).length === 0, 'Stage A bootstrap is acknowledged ' + index);
    await rpc(c, 'acceptAgreements', { version, adultConfirmed: true });
    const own = await rpc(c, 'profile');
    check(own.followersCount === 0 && own.followingCount === 0 && own.worksCount === 0, 'New member has no fictional relationships or works ' + index);
    for (const [action, body] of [['conversations', {}], ['recipeCollection', { scope: 'saved' }], ['recipeCollection', { scope: 'liked' }], ['groceries', {}], ['mealPlans', {}]]) {
      check((await rpc(c, action, body)).length === 0, 'New member has empty ' + action + ' ' + (body.scope ?? '') + ' ' + index);
    }
    const suffix = data.user.id.replaceAll('-', '').slice(0, 14);
    await rpc(c, 'updateProfile', { displayName: 'Toli Finite Acceptance ' + index, username: 'finite_' + suffix, bio: 'Disposable full-application acceptance account.', dietaryTags: [], skillLevel: 'Beginner' });
    check((await rpc(c, 'profile')).username === 'finite_' + suffix, 'Profile write survives server readback ' + index);
  }
  const [a, b, n] = clients;
  const [au, bu, nu] = sessions.map(s => s.user);
  const refreshed = await a.auth.refreshSession();
  if (refreshed.error) throw refreshed.error;
  sessions[0] = refreshed.data.session;
  check(refreshed.data.user.id === au.id, 'Session refresh preserves account identity');
  const recipes = await rpc(a, 'recipes');
  const videos = await rpc(a, 'videos');
  check(recipes.filter(r => r.id.startsWith('recipe-')).length === 12 && videos.length === 6, 'Editorial recipe and replay catalog loads', { recipeCount: recipes.length, videoCount: videos.length });
  check(recipes.filter(r => r.id.startsWith('recipe-')).every(r => r.payload.tutorial), 'Editorial recipes retain tutorial metadata');
  const recipePhoto = await fetch(origin + '/storage/v1/object/public/toli-catalog/recipe-01.jpg', { signal: AbortSignal.timeout(20000) });
  if (!recipePhoto.ok) throw Error('Catalog photo download HTTP ' + recipePhoto.status);
  const recipeBytes = Buffer.from(await recipePhoto.arrayBuffer());
  const recipePhotoPath = `${au.id}/${randomUUID()}.jpg`;
  const recipeUpload = await a.storage.from('recipe-photos').upload(recipePhotoPath, recipeBytes, { contentType: 'image/jpeg' });
  if (recipeUpload.error) throw recipeUpload.error;
  const recipePhotoURL = a.storage.from('recipe-photos').getPublicUrl(recipePhotoPath).data.publicUrl;
  const draft = {
    id: 'finite-' + randomUUID(), title: 'Disposable acceptance pasta', category: 'European', imageURL: recipePhotoURL,
    payload: { summary: 'An isolated acceptance recipe removed after verification.', prepMinutes: 10, cookMinutes: 20,
      servings: 2, calories: 0, protein: 0, carbs: 0, fat: 0, difficulty: 'Home cooking', tags: [],
      ingredients: [{ name: 'Spaghetti', quantity: '200', unit: 'g' }],
      steps: ['Boil the spaghetti according to the packet instructions.', 'Drain and serve with tomato sauce.'] },
  };
  const published = await rpc(a, 'publishRecipe', draft);
  check(published.id === draft.id && published.imageURL === recipePhotoURL, 'Owned original recipe publishes after actual photo upload');
  check((await rpc(b, 'recipes', { query: draft.title })).some(r => r.id === draft.id), 'Independent account reads the published recipe from the server');
  check((await rpc(a, 'recipeCollection', { scope: 'works' })).some(r => r.id === draft.id), 'Published recipe appears in its actual author works');
  await denied(b, 'publishRecipe', { ...draft, id: 'finite-unowned-' + randomUUID() }, 'A recipe cannot use another account photo');
  await denied(a, 'publishRecipe', { ...draft, id: 'finite-external-' + randomUUID(), imageURL: 'https://example.invalid/photo.jpg' }, 'A published recipe cannot use an arbitrary external photo URL');
  await rpc(a, 'publishRecipe', { ...draft, title: draft.title + ' revised' });
  check((await rpc(b, 'recipe', { id: draft.id })).title === draft.title + ' revised', 'Independent account reads an acknowledged recipe edit');
  const foreignDelete = await b.rpc('toli_action', { action: 'deleteRecipe', body: { id: draft.id } });
  check((await rpc(a, 'recipe', { id: draft.id })).title === draft.title + ' revised', 'Another account cannot delete an owned recipe', { deniedOrNoOp: foreignDelete.error ? 'denied' : 'no-op' });
  await rpc(a, 'deleteRecipe', { id: draft.id });
  check(!(await rpc(b, 'recipes', { query: draft.title })).some(r => r.id === draft.id), 'Independent server search confirms owned recipe deletion');
  await denied(a, 'createDirect', { userID: bu.id }, 'Direct messaging requires the sender to follow the recipient');
  await rpc(a, 'setFollow', { userID: bu.id, following: true });
  const chat = await rpc(a, 'createDirect', { userID: bu.id });
  check(chat.peerID === bu.id, 'A sender follow enables a real direct conversation without a reciprocal follow');
  await denied(b, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Denied before following' }, 'An unfollowing recipient cannot send through an existing conversation');
  await rpc(b, 'setFollow', { userID: au.id, following: true });
  await denied(n, 'messages', { conversationID: chat.id }, 'Nonmember cannot retrieve private history');
  await denied(n, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Denied acceptance probe' }, 'Nonmember cannot send a private message');
  const received = [];
  const outside = [];
  const channel = b.channel('finite-member-' + randomUUID()).on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: 'conversation_id=eq.' + chat.id }, payload => received.push(payload.new));
  const outsiderChannel = n.channel('finite-nonmember-' + randomUUID()).on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: 'conversation_id=eq.' + chat.id }, payload => outside.push(payload.new));
  await subscribe(channel); await subscribe(outsiderChannel);
  const clientID = randomUUID();
  const message = await rpc(a, 'sendMessage', { conversationID: chat.id, clientID, body: 'Finite acceptance message' });
  const retry = await rpc(a, 'sendMessage', { conversationID: chat.id, clientID, body: 'Finite acceptance message' });
  check(message.id === retry.id, 'Repeated client ID returns one transactionally persisted message', { messageID: message.id });
  await denied(a, 'sendMessage', { conversationID: chat.id, clientID, body: 'Conflicting retry' }, 'Conflicting retry payload is rejected');
  await waitFor(() => received.some(row => row.id === message.id), 'Authorized partner receives real WebSocket message');
  check(outside.length === 0, 'Nonmember received no private event during the observed delivery interval');
  check((await rpc(b, 'messages', { conversationID: chat.id })).filter(m => m.id === message.id).length === 1, 'Partner independently reads exactly one persisted message');
  await b.removeChannel(channel);
  const missed = await rpc(a, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Missed while disconnected' });
  const rejoined = b.channel('finite-rejoin-' + randomUUID()).on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'messages', filter: 'conversation_id=eq.' + chat.id }, () => {});
  await subscribe(rejoined);
  check((await rpc(b, 'messages', { conversationID: chat.id })).some(m => m.id === missed.id), 'Reconnect history reconciles a missed WebSocket event');
  await rpc(a, 'updateConversation', { conversationID: chat.id, pinned: true, muted: true, draft: 'Private finite acceptance draft' });
  const preference = (await rpc(a, 'conversations')).find(c => c.id === chat.id);
  check(preference.isPinned && preference.isMuted && preference.draft === 'Private finite acceptance draft', 'Conversation preferences persist per account');
  const memberRows = await b.from('conversation_members').select('*').eq('conversation_id', chat.id);
  check(!memberRows.error && memberRows.data.length === 1 && memberRows.data[0].user_id === bu.id, 'Direct Data API cannot expose another member preferences');
  const outsiderRows = await n.from('messages').select('*').eq('conversation_id', chat.id);
  check(!outsiderRows.error && outsiderRows.data.length === 0, 'Direct Data API RLS hides private messages');
  await rpc(a, 'setFollow', { userID: bu.id, following: false });
  await denied(a, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Denied after unfollow' }, 'Existing direct conversation enforces the current sender-follow rule');
  await rpc(a, 'setFollow', { userID: bu.id, following: true });
  await rpc(a, 'toggleBookmark', { recipeID: recipes[0].id, saved: true });
  check((await rpc(a, 'recipeCollection', { scope: 'saved' })).length === 1 && (await rpc(b, 'recipeCollection', { scope: 'saved' })).length === 0, 'Bookmarks persist with account isolation');
  await rpc(a, 'saveMeal', { date: '2026-11-05', slot: 'Dinner', recipeID: recipes[0].id });
  check((await rpc(a, 'mealPlans')).length === 1 && (await rpc(b, 'mealPlans')).length === 0, 'Meal plans persist with account isolation');
  await rpc(a, 'addGroceries', { items: [{ name: 'Flour', quantity: '200', unit: 'g' }, { name: 'flour', quantity: '50', unit: 'g' }], scale: 2 });
  check((await rpc(a, 'groceries')).length === 1, 'Ingredient aggregation normalizes names');
  await denied(a, 'addGroceries', { items: [{ name: 'Rice', quantity: '100', unit: 'g' }, { name: '', quantity: '1', unit: 'g' }], scale: 1 }, 'Invalid ingredient batch is rejected');
  check((await rpc(a, 'groceries')).length === 1, 'Invalid batch atomically rolls back all additions');
  const grocery = (await rpc(a, 'groceries'))[0];
  await rpc(a, 'updateGrocery', { id: grocery.id, checked: true });
  check((await rpc(a, 'groceries'))[0].checked, 'Grocery completion persists');
  // Owner-filtered updates may acknowledge a no-op; verify the protected row itself.
  const foreignUpdate = await b.rpc('toli_action', { action: 'updateGrocery', body: { id: grocery.id, checked: false } });
  check((await rpc(a, 'groceries')).find(item => item.id === grocery.id)?.checked === true && (await rpc(b, 'groceries')).length === 0, 'Another account cannot alter or read a private grocery', { deniedOrNoOp: foreignUpdate.error ? 'denied' : 'no-op' });
  await rpc(a, 'removeGrocery', { id: grocery.id });
  check((await rpc(a, 'groceries')).length === 0, 'Grocery removal persists');
  await denied(a, 'createGroup', { title: 'Invalid small group', memberIDs: [bu.id] }, 'A group requires two other mutual friends');
  await rpc(a, 'setFollow', { userID: nu.id, following: true });
  await rpc(n, 'setFollow', { userID: au.id, following: true });
  const group = await rpc(a, 'createGroup', { title: 'Disposable Finite Cooking Group', memberIDs: [bu.id, nu.id] });
  check((await rpc(a, 'conversationMembers', { conversationID: group.id })).length === 3, 'Group membership contains three actual accounts');
  await denied(b, 'changeMember', { conversationID: group.id, userID: nu.id, remove: true }, 'Nonowner cannot remove a group member');
  await rpc(a, 'changeMember', { conversationID: group.id, userID: nu.id, remove: true });
  await denied(n, 'messages', { conversationID: group.id }, 'Removed group member loses history access');
  await rpc(a, 'changeMember', { conversationID: group.id, userID: nu.id, remove: false });
  check((await rpc(n, 'conversationMembers', { conversationID: group.id })).length === 3, 'Owner can re-invite a mutual friend');
  const imagePath = `${chat.id}/${au.id}/${randomUUID()}.jpg`;
  const upload = await a.storage.from('chat-images').upload(imagePath, recipeBytes, { contentType: 'image/jpeg' });
  if (upload.error) throw upload.error;
  const photo = await rpc(a, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Actual private food photo', imagePath });
  check(photo.imagePath === imagePath, 'Photo message references an existing owned uploaded object');
  const signed = await b.storage.from('chat-images').createSignedUrl(imagePath, 300);
  check(!signed.error && !!signed.data?.signedUrl, 'Authorized partner can sign private image');
  const download = await fetch(signed.data.signedUrl, { signal: AbortSignal.timeout(20000) });
  const downloaded = Buffer.from(await download.arrayBuffer());
  check(download.ok && createHash('sha256').update(downloaded).digest('hex') === createHash('sha256').update(recipeBytes).digest('hex'), 'Private attachment download matches actual uploaded bytes');
  check(!!(await n.storage.from('chat-images').createSignedUrl(imagePath, 300)).error, 'Nonmember cannot sign private image');
  await denied(a, 'sendMessage', { conversationID: chat.id, clientID: randomUUID(), body: 'Missing image probe', imagePath: `${chat.id}/${au.id}/${randomUUID()}.jpg` }, 'Missing image object cannot become a successful message');
  await rpc(a, 'block', { userID: bu.id });
  check((await rpc(a, 'blockedUsers')).some(u => u.id === bu.id), 'Block is acknowledged and read back');
  await denied(b, 'messages', { conversationID: chat.id }, 'Blocked participant loses server chat access');
  check(!!(await b.storage.from('chat-images').createSignedUrl(imagePath, 300)).error, 'Blocked participant cannot renew private image access');
  await rpc(a, 'unblock', { userID: bu.id });
  check((await rpc(a, 'blockedUsers')).length === 0, 'Unblock persists');
  check((await rpc(a, 'relationships', { kind: 'mutuals' })).every(u => u.id !== bu.id), 'Unblocking does not fabricate restored mutual follows');
} catch (error) {
  evidence.errors.push(error.message);
  process.exitCode = 1;
} finally {
  for (const c of clients) await c.removeAllChannels();
  for (let index = 0; index < sessions.length; index++) {
    const session = sessions[index];
    try {
      const response = await fetch(origin + '/functions/v1/delete-account', { method: 'POST', headers: { apikey: key, Authorization: 'Bearer ' + session.access_token, 'Content-Type': 'application/json' }, body: '{}', signal: AbortSignal.timeout(20000) });
      if (!response.ok) throw Error('Delete endpoint HTTP ' + response.status);
      const stale = await clients[index].rpc('toli_action', { action: 'profile', body: {} });
      if (!stale.error) throw Error('Deleted account still has business access');
      evidence.cleanup.push({ userID: session.user.id, deleted: true, staleTokenDenied: true });
    } catch (error) {
      const recovery = '/private/tmp/toli-finite-cleanup-' + session.user.id + '.json';
      fs.writeFileSync(recovery, JSON.stringify(session), { mode: 0o600 });
      evidence.cleanup.push({ userID: session.user.id, deleted: false, error: error.message, privateRecoveryFile: recovery });
      process.exitCode = 1;
    }
  }
  evidence.finishedAt = new Date().toISOString();
  evidence.passed = evidence.checks.filter(c => c.result === 'passed').length;
  evidence.failed = evidence.checks.filter(c => c.result === 'failed').length;
  save();
  console.log(JSON.stringify({ passed: evidence.passed, failed: evidence.failed, errors: evidence.errors, deletedAccounts: evidence.cleanup.filter(c => c.deleted).length, output }));
}
