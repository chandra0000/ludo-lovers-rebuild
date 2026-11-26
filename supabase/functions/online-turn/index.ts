// A stateless relay. The Dart authority verifies the JWT with Supabase Auth.
const actions = new Set(["roll_dice", "execute_move", "handle_turn_timeout"]);
Deno.serve(async (request) => {
  if (request.method !== "POST") return new Response(null, { status: 405 });
  const auth = request.headers.get("authorization");
  if (!auth) return new Response(null, { status: 401 });
  try {
    const input = await request.json();
    if (!actions.has(input.action)) return new Response(null, { status: 400 });
    const origin = new URL(Deno.env.get("MATCH_AUTHORITY_URL")!);
    if (origin.protocol !== "https:") throw new Error("TLS required");
    const upstream = await fetch(new URL("/" + input.action, origin), {
      method: "POST",
      headers: { Authorization: auth, "Content-Type": "application/json" },
      body: JSON.stringify({ match_id: input.match_id, command_id: input.command_id,
        expected_sequence: input.expected_sequence, pawn_index: input.pawn_index }),
      signal: AbortSignal.timeout(8000),
      redirect: "error",
    });
    return new Response(upstream.body, { status: upstream.status,
      headers: { "Content-Type": "application/json", "Cache-Control": "no-store" } });
  } catch {
    return Response.json({ error: "Match service unavailable" }, { status: 503 });
  }
});
