# Capture presentation and HUD acceptance

A move is saved as soon as MatchSession accepts it. MatchTurnCoordinator passes the immutable pre-move snapshot and the accepted event batch to MatchScreen. Only PawnCaptured and TeamPawnCaptured identify victims. The previous snapshot supplies each victim’s original progress and pawn index. Flutter consumes this data for presentation. It never issues a second move to return a pawn to its yard.

| Phase | Rendering | Feedback |
|---|---|---|
| Approach | Existing attacker hop timing. Each victim stays at its pre-move position. | Roll rattle starts when a roll is accepted. |
| Impact | On the first frame at or beyond arrival, start the radial burst and hold the victim for 70 ms. Offset the board up to two design units with a damped shake. | Capture thud and optional medium haptic. |
| Retreat | Each victim walks its own route backward. Each edge takes 48 ms. The final edge joins progress zero to that pawn’s yard socket. Multiple victims retreat concurrently. | Emit at most one tick per rendered beat. Five pitch bands descend over the return. |
| Settle | The longest retreat finishes the shared ticker. Clear all presentation overrides and schedule the next eligible turn. | Soft yard chime for capture, or finish cue for a winning move. |

The controller includes approach, hold and return in one duration. PawnAnimator samples the forward route with reversed normalized time. A dropped frame advances directly to its correct location. Rematch clears transient state, saved-match recovery displays the committed state, and reduced motion fast-forwards the same presentation callback.

The die face uses 74% of its previous size inside the existing hit area. A 500 ms tumble settles to the authoritative result. A gold arrow moves toward the current seat. No-move feedback lasts 550 ms. Multiple legal choices use 57.6 dp minimum targets and raised gold rings. Two shared pawns sit side by side and four use a stable two-by-two layout. Board event text ignores pointer input. Material button labels scale to 95% on press. Reactions continue to use the existing per-seat social layer.

Sound is opt-in through Game Feedback. MatchFeedback prepares short, bundled mono WAV clips and disposes the playback pools with the screen. Measure physical output latency with sound enabled. The artwork, route anchors, mode registry and seat order retain their existing release contracts. The app has no coin balance to animate.

For release, record a long and a short retreat, a multi-victim Team move, reduced motion, a mid-retreat background/resume and a rematch. Check adjacent selection and the active-seat pointer at all four Android sizes, 150% text and an iPhone safe area. Measure the same sequence in profile mode with recording off before making a 60 FPS claim.

## Start a local game

Local and Classic open Classic setup with a choice of two, three or four players. Quick uses the same rosters and its existing two-finish victory target. Play Now retains the four-seat compatibility profile. Two players use Orange and Magenta. Three use Orange, Green and Magenta. In public local Team Up, four seats form Orange/Magenta and Green/Blue and play toward eight team finishes. Saved matches retain their original profile.
