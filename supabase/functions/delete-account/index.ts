const origin = Deno.env.get("SUPABASE_URL")!;
const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const reply = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
const adminHeaders = { apikey: service, Authorization: `Bearer ${service}`, "Content-Type": "application/json" };
Deno.serve(async req => {
  if (req.method !== "POST") return reply({ error: "POST required" }, 405);
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return reply({ error: "Authentication required" }, 401);
  const auth = await fetch(origin + "/auth/v1/user", { headers: { apikey: anon, Authorization: authorization } });
  if (!auth.ok) return reply({ error: "Authentication required" }, 401);
  const user = await auth.json();
  // The requested account is derived exclusively from the verified access token.
  const memberResponse = await fetch(origin + `/rest/v1/conversation_members?select=conversation_id&user_id=eq.${user.id}`, { headers: adminHeaders });
  if (!memberResponse.ok) return reply({ error: "Account removal could not begin" }, 500);
  const memberships = await memberResponse.json();
  const folders = [{ bucket: "avatars", prefix: `${user.id}/` }, { bucket: "recipe-photos", prefix: `${user.id}/` }, ...memberships.map((m: { conversation_id: string }) => ({ bucket: "chat-images", prefix: `${m.conversation_id}/${user.id}/` }))];
  for (const folder of folders) {
    for (let batch = 0; batch < 100; batch++) {
      const listing = await fetch(origin + `/storage/v1/object/list/${folder.bucket}`, { method: "POST", headers: adminHeaders, body: JSON.stringify({ prefix: folder.prefix, limit: 100, offset: 0 }) });
      if (!listing.ok) return reply({ error: "Media removal failed; please retry" }, 500);
      const files = await listing.json();
      if (!files.length) break;
      const keys = files.filter((f: { id: string | null }) => f.id).map((f: { name: string }) => folder.prefix + f.name);
      if (!keys.length) break;
      const deleted = await fetch(origin + `/storage/v1/object/${folder.bucket}`, { method: "DELETE", headers: adminHeaders, body: JSON.stringify({ prefixes: keys }) });
      if (!deleted.ok) return reply({ error: "Media removal failed; please retry" }, 500);
      if (batch === 99) return reply({ error: "More media remains; please retry account deletion" }, 409);
    }
  }
  const logout = await fetch(origin + "/auth/v1/logout?scope=global", { method: "POST", headers: { apikey: anon, Authorization: authorization } });
  if (!logout.ok && logout.status !== 401) return reply({ error: "Session revocation failed; please retry" }, 500);
  const removed = await fetch(origin + `/auth/v1/admin/users/${user.id}`, { method: "DELETE", headers: adminHeaders });
  if (!removed.ok) return reply({ error: "Account removal failed; please retry" }, 500);
  return reply({});
});
