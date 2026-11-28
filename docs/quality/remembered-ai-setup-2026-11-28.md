# Remember AI difficulty without changing match authority

This focused local-play feature builds on coordinated preparation PR118. It
persists only the preferred Easy/Medium/Hard choice under
preferred_ai_difficulty_v1. Explicit player count, seat colors, human/bot roster,
mode, rules, dice and saved-match snapshots are not overwritten by preferences.
Missing/malformed values fall back to Medium. No new dependencies are added.

Setup does not wait for preference loading. Late results cannot overwrite an
edited difficulty or an already-starting match, and disposal is guarded. An AI
start saves the choice best-effort with a2-second bound; failure or a late write
cannot prevent the selected match or launch it twice. This is an optional setup
write bound, not an extension of an application/runtime test timeout.

The accepted setup intent (game configuration, difficulty, roster and names) is
captured before asynchronous writes. Count/human/difficulty controls and start
buttons are disabled while starting; the UI says Starting. Existing rule profiles,
opposite two-player seats, player names and saved-match persistence remain intact.

Eleven new regressions cover all three values, corruption, save isolation, late
load/edit races, frozen two-seat setup, failed/stalled writes, disposal and actual
bundled-font setup rendering. The shared widget/installed Android/iOS acceptance
flow now starts a Hard AI game, exits and opens a fresh setup, verifies Hard was
restored and captures native-preferred-ai-difficulty-setup. This verifies live UI
integration; do not claim physical process-restart preference acceptance from a
mocked integration binding. Normal-APK process recovery remains a separate gate.

Required gates are strict formatting, fatal-info analysis, the full579-test suite,
Android builds and installed Android/iOS scenarios on the exact published head.
Known external production limits remain physical-device profiling/accessibility,
signing/store credentials, owner visuals and hosted online/Auth security testing.
Supabase lists zero connected projects at this review; no fake online service,
coins, tournament rules or9.5 score is introduced to fill that gap.

The actual setup screenshot exposed a missing right-arrow glyph in the bundled
Latin-font capture path. The turn-order summary now uses the real Material arrow
icon plus an explicit spoken order, rather than depending on an OS symbol font.
This preserves the typography/color contract and text scaling. It is not a claim
that the original glyph failure was reproduced on a physical phone.
