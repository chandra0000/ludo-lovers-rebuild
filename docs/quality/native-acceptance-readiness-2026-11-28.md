# Native acceptance readiness and failure evidence

This QA-only follow-up preserves PR119 application code. It does not increase
application, per-test or workflow timeouts or disable screenshots/tests.

PR118 default-renderer run46164948632 reached Team Up, then exceeded the existing
3-minute local-mode limit. Its first FFA PNG captured preparation before readiness.
A driver printed All tests passed despite Some tests failed above it; missing
computer evidence still correctly failed the job. Do not trust that footer.

The helper now advances at most three frames only while preparation/board status
is pending, then asserts readiness. Warm entries avoid redundant GPU pumps.
Native captures wait for a validated/written PNG acknowledgement instead of an
unconditional3-second hold each time. Missing/invalid captures still fail within
a bounded10-second acknowledgement deadline. The host latches Flutter test
failures and rejects an erroneous success exit/footer.

Run46164924127 failed before Home. Its screenshot shows Android's launcher context
menu; the tail log does not establish an app crash or why foreground was lost.
Recovery now records launch output, rejects Activity errors, retains continuous
logcat before installation and recognizes Home only in the real app package.
The obsolete blind SKIP action is removed: production SplashScreen goes directly
to Home. The45-second Home deadline and360-second integration watchdog are unchanged.
No unproven root cause is claimed. Old failed runs remain failed.

Four added host cases protect PNG-before-ack ordering, failure-footer latching,
non-interacting/app-scoped Home readiness and launch-error diagnostics. All38
host checks pass locally. Full579 tests, strict format/analyzer, native Android,
recovery, iPhone simulator and new four-size MP4 inspection remain required.
Physical performance, hosted Auth/security, signing/store and owner visuals are
separate release gates.
