# Coordinated match preparation and current production gaps

Main remains ef335c871fda69e63404fa47c84c7a743bdb62b2. This forward-only change
builds on PR117 c2b95b7f3e155ecac474a3266dab657b082b53c1, after114 and116.
No historical branch is merged or approved merely by its title.

## Remaining loading defect

The owner was correct that116 did not resolve the visual loading experience.
The reviewed final360x800 recording from46151617011 still shows a large empty
board panel and independently arriving logo/profiles.116 fixed command readiness,
not coordinated scene presentation. No crash is inferred from those frames.

The warmup requested the unresized icon, whereas the live RoyalBrandMark used a
216-pixel ResizeImage key. It also decoded four legacy portraits unused by the
current vector seats. Therefore warmup did not prepare exactly what was rendered.
Staged capture/AI/victory fixture replacement also appeared as unexplained resets.

## Implemented production improvement

- MatchAssets supplies the exact board and resized-logo providers to preparation
  and rendering. Two image-stream listeners retain decoded frames only for the
  route lifetime; listeners and received ImageInfo handles are disposed safely.
  Unused portrait warmup and duplicate unresized-logo decode are removed.
- A royal preparation surface displays the approved logo, truthful image progress
  and accessible exit. Profiles, board, dice and utilities reveal together once
  both images decode. Invisible controls cannot receive pointer, semantic or
  keyboard input; their tickers are muted. MatchSession remains unchanged.
- A12-second stalled-decode deadline exposes recoverable Retry/Back instead of
  an endless loader. Retry evicts only failed/pending assets, has bounded3-second
  eviction and invalidates stale callbacks. It rebuilds presentation, not the
  match engine, roster or accepted command history. Save success is not promised
  by preparation copy. Existing decoded-board input guard remains authoritative.
- Warm scene changes/rematches retain providers and do not deliberately add a
  branding delay. This is cache correctness, not a measured startup/FPS claim.
- Native recordings now visibly disclose900ms seeded-scenario transition cards.
  These are test-only and explicitly describe position/AI resets. Actual game
  widgets, geometry, rules and animation timings are unchanged. No footage is
  generated, reconstructed or edited to conceal a production failure.

## Regression and evidence scope

Eight new focused cases cover board/logo coordination, one-shot retry, bounded
stall handling, warm reuse, exact resized-provider identity, late provider frames,
retry disposal and hidden-control keyboard focus. The previous eight slow-board
cases now protect the whole preparation view, all four200% text viewports,
command gating, AI delay, restored-six exactly-once execution and disposal.
Actual PNGs are generated with real bundled fonts. Existing interaction/capture
helpers await both real providers and the post-frame readiness update, rather
than clicking invisible controls. No gameplay assertion or timeout is weakened.

The reduced-motion release test now asserts the two accepted commands directly;
it no longer taps a pawn already automatically deployed. Repeated-tap coverage
remains elsewhere. The full568-test suite, fatal-info analysis, native builds,
installed Android/iOS checks, recovery and fresh four-size recordings are required
for the published revision. Historical recordings do not verify this change.

## Repository review and ordered production work

| Area | Current evidence / decision |
| --- | --- |
| Loading composition | Implemented here; fresh native/owner visual evidence required |
| Engine, board, saved schemas | Preserved; existing deterministic and pixel/geometry tests required |
| Public local2/3/4 | Already implemented; retain opposite Orange/Magenta for2 players |
| AI difficulty | Already selectable; preference is reset to Medium on every setup. Persisting only difficulty is a useful next isolated UX feature; explicit player count/roster/rules must not be overridden |
| PR115 | Old base test/native-victory-rematch. Current source already freezes roles and animates captured retreat. Any unique route/rematch tests need forward-port review; do not merge the old UI wholesale |
| PR104 dependency upgrade | Blocked by its required Flutter version; pinned3.35.7 must not be bypassed |
| Online/Auth drafts90/94 | Need one reconciled authoritative design and hosted security/two-client acceptance; do not expose incomplete online services |
| Localization, help/privacy, richer results/history | Remaining product scope; history needs an idempotent completed-match persistence contract before awards/counting |
| Physical performance/accessibility/audio | Still open; software debug recording cadence is not60fps evidence |
| Signing/store and owner visuals | Separate external release gates; no automatic clearance |

This is not a production-ready verdict or a9.5 score. Prior failed recorder attempts
remain failed. Exact tested heads, run/artifact links and remaining limits belong
in the implementation PR's final verification receipt and the Notion hub.
