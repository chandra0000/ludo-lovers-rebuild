# Native Android footage review — 2026-11-22

Reviewed sampled frames, native PNGs, artifact metadata, and asserted gameplay events from two actual installed Android recordings. Both clips use Android API 33, a 360 × 800 screen at 160 dpi, a debug APK, and Skia software rendering. The match scenarios use test-only seeded rolls and staged board positions.

| Capture | Duration | Encoded average | Median active cadence | Evidence |
| --- | --- | --- | --- | --- |
| #75, QA source `bdf08df` | 58.741 s | 9.16 fps | 20.67 fps | [Recorded clip and assertions](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/44875015368/artifacts/14695484241) |
| #76, source `85c10f5` | 90.682 s | 7.65 fps | 22.10 fps | [Recorded clip and assertions](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591/artifacts/14751477914) · [Native PNGs](https://github.com/chandra0000/ludo-lovers-rebuild/actions/runs/45015085591/artifacts/14752370005) |

Both H.264 streams delivered decoded frames and matched the downloaded artifact receipts. The SHA-256 hashes are `405a2c00169043e8bf422e75a25d380f134cfeee25c77e0dd21eb552f33d21c5` (#75) and `7bf275a42883440d6a4dfcac4ae976502cd41f3bf984be76fa9d3ca02f8cf80d` (#76). The local FFmpeg null muxer emitted timestamp warnings on these variable-rate inputs. Both source verifiers report a complete decode. Cadence measures recorded changes in this CI configuration. Neither capture met the 30 fps active-cadence target.

## Timestamped observations

| Clip time | Observation | Status and evidence |
| --- | --- | --- |
| #76 00:00–00:13 | The frame sample shows the launcher, the royal branded native splash, and the home screen. Splash is visible in sampled frames from 00:04 through 00:10. | Measure cold launch on physical hardware before treating the duration as a production startup measurement. See `native-installed-launcher.png` and `native-cold-start-*.png`. |
| #76 00:13–00:29 | Home is visible, and the normal app reaches Game Setup before returning to the launcher. | The native artifact contains home, background, warm home and setup PNGs. Separate installed assertions cover mode-specific entry. |
| #76 00:30–00:49 | The recorder shows the deliberate launcher/APK handoff, another branded splash, and home during driver attachment. At about 00:45 the home logo is briefly missing from its frame, then appears in the following sample. | This interval includes the test process launch and fixture preparation. Measure ordinary production navigation separately. |
| #75 00:15 and #76 about 00:50 | Profiles and pieces briefly render before the artwork finishes appearing during seeded fixture mounting or replacement. The approved board is visible in subsequent frames, including #76 at 00:51. | Confirmed presentation gap in the fixture and a candidate for a normal-route reproduction. Inspect image readiness and layer ordering in `apps/mobile/lib/src/features/match/match_board_artwork.dart` and `game_board_scaffold.dart`. A focused regression should delay image resolution and verify that the pawns and actionable board first appear together. |
| #76 00:52–01:24 | Dice change orientation and settle, pawns occupy different cells, and a green AI seat takes a turn. The event log verifies yard entry, three-cell travel, a staged capture and bonus turn, AI handoff, and a no-legal-move pass. | Native PNGs include `recording-yard-release-landed.png`, `recording-three-cell-travel-landed-turn-green.png`, `recording-capture-and-bonus-confirmed.png`, and `recording-seeded-ai-roll-move-human-handoff.png`. Exact assertion elapsed times are relative to the seeded fixture. |
| Both complete clips | No winning screen or rematch appears in the recorded scenario. | Add native end-of-match coverage for victory and rematch. These recordings cannot measure touch latency or verify physical GPU performance. |

The board fixture and first-frame startup findings should be rechecked via a normal installed match with a cold image cache. Keep APK switches and CI driver delays out of production startup measurements. No default-renderer or physical-device release gate is cleared by the recordings.
