// Deployment-only curated ingest. Disabled after the verified initial upload.
Deno.serve(() => new Response(JSON.stringify({ error: "Initial import is closed." }), { status: 410, headers: { "Content-Type": "application/json" } }));
