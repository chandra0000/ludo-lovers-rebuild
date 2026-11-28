# Fixed physical seats under RTL presentation

A real MatchScreen test at393x873 reproduced Orange on the right of Green and
Blue on the right of Magenta when Directionality was RTL. The approved board
artwork itself did not mirror, so identity and physical quadrant diverged.
Before-fix assertion: Orange x313.3475 was not less than Green x79.6525.
This is a layout-contract regression, not evidence that Arabic is released.

Both profile rows now explicitly use LTR child ordering. Player text, navigation
and the rest of the UI retain ambient directionality. Orange/Green remain upper
left/right and Blue/Magenta lower left/right. Engine turn order, identifiers,
colors, artwork, anchors and direct selection are unchanged. No translations or
language selector are claimed by this fix.

Twenty-four actual MatchScreen cases cover LTR/RTL, local2/3/4 rosters and all
four required portrait viewports. They check physical centers and square board,
load bundled fonts and capture actual Flutter frames. Before/after393x873 RTL
frames were inspected. The focused24 and full520 tests passed before integration
with the independently validated board-recovery/simulation changes. The combined
revision passed537 tests locally, strict202-file formatting and fatal-info analysis.
Exact-head native CI remains required before merge.

The main baseline is46c8bcb52cbee19e1d7b16bd6f523f22c62f7456, containing #108 and
#111. No historical visual, physical-device or performance approval is inherited.
