# Online authority

This service uses the existing Dart MatchSession and LudoGame. Supabase stores room membership, wallets, snapshots, ordered events and command receipts. Keep the service-role key on the Dart host. Put the host behind HTTPS and configure the Edge relay with MATCH_AUTHORITY_URL. The caller supplies a Supabase access token, match UUID, command UUID and expected sequence. Retries reuse all three identifiers. After a conflict, reload the member-scoped row and current sequence before sending a new intent.

## Staging verification

1. Apply migrations in order to a disposable Supabase project. Sign in as two staging users and seed virtual test balances through the administrative connection.
2. Join the same Classic or Quick queue concurrently. Assert unique seats and one debit per account. Repeat a request and verify that it returns the same room. Cancel a waiting room and check refunds.
3. Create a private room, join with its code, set both seats ready, and start as host. Verify safe stars, captures, third-six penalty, no-legal-move handling, a duplicate request and a stale sequence. Check that an unrelated user sees no match rows or events and cannot call the service-only commit RPC.
4. Test a dropped response by retrying the original command UUID. Subscribe before loading the initial snapshot. Reload on sequence gaps, reconnect and app resume. Run two independent clients through a win and verify exactly one wallet settlement.
5. Exercise expired human turns and bot seats. The Dart host sweeps due turns once per second while it is running. Run two host instances to verify that concurrent sweeps commit just one version and that retries cannot duplicate a payout. Verify bot and human timeout behavior with all clients disconnected.

## Flutter work pending

Wire a Riverpod room provider to the authenticated RPCs and Realtime. Expose explicit searching, waiting, playing, reconnecting and finished states. The existing board renderers should consume authoritative snapshots. Use event progress to drive the existing capture animation and the server deadline to draw the turn ring. Keep a local dice anticipation animation separate from the accepted die face.

The lobby needs queue tier and seat selection, private room sharing, ready/start controls, reactions and the results screen. A full podium and rematch require additional authoritative placement and rematch state. Coins in this package are virtual. Capture 60 FPS evidence on physical devices after the full flow is connected.

## Online multiplayer status and creation backlog

Backend baseline `91d83f2357588de402ec6bd1e2b6932b33bae398` in [draft PR #94](https://github.com/chandra0000/ludo-lovers-rebuild/pull/94). Pinned Dart static analysis and executable compilation passed. [Authority CI](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45854430511)

**Implemented in source.** Transactional private rooms and public queue seating, ready/start controls, host-triggered bot fill, virtual-coin escrow and settlement, sequenced command receipts, shared Dart rules and server RNG, preset reactions with a cooldown, and a once-per-second server sweep for expired turns. The Edge relay forwards authenticated intents to the Dart host.

| Priority | Create | Acceptance |
|---|---|---|
| 1 | Staging Supabase project, HTTPS Dart authority deployment, service secrets and Edge relay configuration | Apply migrations cleanly. Two authenticated accounts can play. An unrelated account cannot read room data or call the commit RPC. |
| 2 | Database integration fixtures and CI for room joins, retries, wallet settlement and timeouts | Concurrent joins assign unique seats. Retries advance one version and pay once. Expired turns advance with every client disconnected. Verify abandoned-room expiry and refunds. |
| 3 | Flutter online repository and Riverpod session controller | Subscribe before loading the snapshot. Recover from sequence gaps, app resume and dropped responses. Derive the countdown from the server deadline. Optimistic dice animation settles on the accepted face. |
| 4 | Public queue and private-room screens | Classic and Quick support 2/4 seats. Show tier, fee and searching state. Test code sharing, ready/start, cancel/refund and the 11-second bot-fill prompt with two clients. |
| 5 | Online match and results screens | Render capture events through the existing board presentation. Show sender-side reactions. Persist authoritative placements and stats, then wire the podium, rematch and play-again actions. |
| 6 | Device acceptance | Run disconnect, resume, AFK and rematch scenarios on two devices. Measure physical frame pacing at 60 Hz and capture screenshots and audio timing. |

Connected Supabase projects available at the last check: zero. The branch is a draft and the successful Dart job covers static analysis and compilation. Hosted SQL/RLS behavior, financial-state concurrency and device acceptance remain unverified.
