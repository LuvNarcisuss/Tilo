const origin = Deno.env.get("SUPABASE_URL")!;
const anon = Deno.env.get("SUPABASE_ANON_KEY")!;
const reply = (data: unknown, status = 200) => new Response(JSON.stringify(data), { status, headers: { "Content-Type": "application/json" } });
Deno.serve(async req => {
  if (req.method !== "POST") return reply({ error: "POST required" }, 405);
  const authorization = req.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) return reply({ error: "Authentication required" }, 401);
  const auth = await fetch(origin + "/auth/v1/user", { headers: { apikey: anon, Authorization: authorization } });
  if (!auth.ok) return reply({ error: "Authentication required" }, 401);
  const result = await fetch(origin + "/rest/v1/rpc/toli_action", { method: "POST", headers: { apikey: anon, Authorization: authorization, "Content-Type": "application/json" }, body: JSON.stringify({ action: "bootstrap", body: {} }) });
  if (!result.ok) return reply({ error: "Account setup failed" }, 500);
  return reply(await result.json());
});
