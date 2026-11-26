# Online authority

This service uses the existing Dart MatchSession and LudoGame. Supabase stores room membership, wallets, snapshots, ordered events and command receipts. Keep the service-role key on the Dart host. Put the host behind HTTPS and configure the Edge relay with MATCH_AUTHORITY_URL. The caller supplies a Supabase access token, match UUID, command UUID and expected sequence. Retries reuse all three identifiers. After a conflict, reload the member-scoped row and current sequence before sending a new intent.

## Staging verification

1. Apply migrations in order to a disposable Supabase project. Sign in as two staging users and seed virtual test balances through the administrative connection.
2. Join the same Classic or Quick queue concurrently. Assert unique seats and one debit per account. Repeat a request and verify that it returns the same room. Cancel a waiting room and check refunds.
3. Create a private room, join with its code, set both seats ready, and start as host. Verify safe stars, captures, third-six penalty, no-legal-move handling, a duplicate request and a stale sequence. Check that an unrelated user sees no match rows or events and cannot call the service-only commit RPC.
4. Test a dropped response by retrying the original command UUID. Subscribe before loading the initial snapshot. Reload on sequence gaps, reconnect and app resume. Run two independent clients through a win and verify exactly one wallet settlement.
5. Exercise expired human turns and bot seats. The timeout endpoint currently requires a participating client to invoke it. An autonomous worker and integration tests are required before unattended queues or live release.

## Flutter work pending

Wire a Riverpod room provider to the authenticated RPCs and Realtime. Expose explicit searching, waiting, playing, reconnecting and finished states. The existing board renderers should consume authoritative snapshots. Use event progress to drive the existing capture animation and the server deadline to draw the turn ring. Keep a local dice anticipation animation separate from the accepted die face.

The lobby needs queue tier and seat selection, private room sharing, ready/start controls, reactions and the results screen. A full podium and rematch require additional authoritative placement and rematch state. Coins in this package are virtual. Capture 60 FPS evidence on physical devices after the full flow is connected.
