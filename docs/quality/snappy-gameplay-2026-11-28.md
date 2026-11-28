# Zero-friction local gameplay and beveled dice

Source main: ef335c871fda69e63404fa47c84c7a743bdb62b2. This implements the owner's
new gameplay-speed/rules request in the playable app. Board/logo bytes, quadrant
order, calibrated geometry, portrait orientation and MatchSession authority remain.

## Actual component paths

- apps/mobile/lib/features/game/presentation/widgets/beveled_3d_dice.dart owns the
  production dice implementation. The old luxury_dice.dart exports it for existing
  call sites/tests, avoiding a disconnected demonstration. Beveled3DDice exposes
  onRollComplete(int); results/roll IDs come from accepted commands, never UI RNG.
- apps/mobile/lib/features/game/domain/ludo_turn_engine.dart is a pure-Dart
  Riverpod StateNotifier adapter over one MatchSession, not a second rules engine.
  MatchCommandController uses this instance. Explicit presentation phases retain
  accepted rolling identity even when a third-six event already advances state.
  Crown/status remain with the presented mover until landing; victory waits for
  that final movement rather than covering an unfinished hop.
- apps/mobile/lib/features/game/presentation/widgets/cached_ludo_board.dart uses
  the approved image, image-cache warmup and repaint boundaries. Existing route
  geometry/PawnAnimator supply cell-by-cell arcs. No replacement grid or coordinate
  table, Flame migration, GoRouter migration or independent rule implementation.

Riverpod2.6.1 and state_notifier1.0.0 are the only newly resolved packages, compatible
with pinned Flutter3.35.7. The authoritative domain/session import boundary remains
free of Flutter, Flame and Riverpod dependencies.

## Rules and interaction

New local matches explicitly select ludo-lovers-current@2: existing six/capture
bonuses plus finish bonus and third-six forfeiture. Old current@1 saves retain their
serialized rules and old finish/six behavior; Classic/Quick/TeamUp policies are
unchanged. Seating schema versions remain independent. Rule semantics are engine
flags, not conditions invented by the widgets. Restart retains the selected profile.

The pawn-sheet implementation and its footer/menu entry points are deleted.
Equivalent legal yard choices after six deploy the first legal pawn with no prompt.
Single legal moves use180ms; distinct track choices remain direct on-board.
Same-cell legal friendly pawns fan16 logical pixels apart (two pawns ±8), with
numbered badges. Existing inverse-scaled48dp targets/nearest-target hit testing and
individual pawn semantics remain. Only fan decoration can shift; ordinary anchors
must stay exact even at compact320x568. No geometry assertion was loosened.

A strengthened disposal test exposed the old scheduler retaining Future.delayed
timers after cancellation. It now owns/cancels a real Timer as well as invalidating
its generation; no leftover auto-pass timer survives disposal/rematch.

Dice420ms =280ms spin +140ms easeOutBack settle. Flutter's interpolation completion
uses elapsed > duration, so the exact-duration test samples the next scheduler tick
at421ms. Authoritative settled faces, duplicate requests, cancellation and reduced
motion retain generation guards. Third-six rolls now visibly animate their accepted
6 before the penalty toast and presentation handoff, rather than disappearing
because the authoritative post-penalty state has no pending die.

Pawn arcs use95ms per cell, subtle stretch and landing feedback. AI thinking remains
450ms. No-move feedback is a nonblocking650ms card overlay, not extra layout height.
Legal gold emphasis uses a finite900ms three-beat breath up to1.12x, avoiding an
endless idle ticker. Human/bot roles are copied at match creation and cannot flip
when a caller mutates/rebuilds its set. Four original vector portraits distinguish
human seats; approved board/logo and pawn silhouette are not regenerated.

## Rendering and feedback

Visible cube faces share one rigid transform, backface culling and camera-depth
ordering. Each paints anti-aliased rounded faces, metallic bevels and recessed pips;
1/6 use ruby accents and the numeric badge is removed. One grounded shadow stays
below the die as it lifts; a finite gold slot pulse acknowledges human readiness.

Movement ticks rebuild the board AnimatedBuilder instead of the entire HUD.
Static image/pawn/portrait/dice paints have separate boundaries. This is rendering
isolation, not proof of a60fps device result or a promise that every frame is cached.

The five named local WAVs are bundled: dice_roll, pawn_hop, capture, safe_star,
victory. tool/prepare_match_audio.py reproduces aliases of existing clips and two
original synthesized chimes. Enabled audio pools warm asynchronously, are disposed
on exit/rematch and never gate rules. Existing sound/haptic preferences remain.
Dice uses lightImpact, tile hops selectionClick, capture/victory heavyImpact;
unsupported effects remain best-effort and cannot block commands.

## Verification and gates

Fifteen added contract cases cover versioned save compatibility, equivalent choices,
third-six accepted identity/duplicate rejection, explicit rolls before passes, all
8 safe cells protecting opposing stacks, finish bonuses, dice completion frozen roles, four-way fan selection and platform haptic mapping. Existing old-behavior tests were updated to assert the approved automatic
choice/timing, not disabled. Full suite, actual four-size screenshots, native builds,
normal-APK process recovery, seeded recording and security CI must pass before
integration. Workflows now trigger simulations/recovery for relevant app changes.

Actual device p50/p95/p99, battery/memory, physical haptics/audio, iOS physical-device,
final owner visuals and60fps acceptance remain separate. No Ludo King source/art
was copied. No9.5 rating, physical acceptance or production-ready release is claimed.
