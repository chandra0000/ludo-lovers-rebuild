# Normal Android APK process-death acceptance

Existing integration suites mock SharedPreferences. Snapshot codec and widget
resume coverage cannot prove that Android native preferences survived process
termination. This workflow intentionally installs lib/main.dart, no test entry
point, no deterministic dice injection, no preview-mode define and no mocked
preferences. Flutter keeps its default renderer with emulator SwANGLE.

The disposable API33 emulator runs public all-human local2 and3 separately. Each
case uses the actual Home/Setup/dice UI, reads the real run-as native preferences
XML, waits for an acknowledged roll snapshot, records its process PID, force-stops
the app, verifies that PID is gone, relaunches, taps Resume Saved Match and checks
the restored snapshot/roster/profiles/commands/pawns. One pending non-six can
legitimately produce exactly one no-legal-move pass on restoration. A second roll,
pawn movement, identity change, extra version or changed profile fails acceptance.
Random production dice are disclosed, not staged as deterministic video.

Before install, clear or force-stop, serial must be emulator-* and ro.kernel.qemu
must equal1. No physical device data is cleared. Each case clears only this app
on the dedicated AVD. Native files are read, never injected or edited. The host
reuses existing ADB/UI/screenshot helpers; it does not implement game rules or
change production. Final screenshots prove match UI, not merely a disk file.

Run from apps/mobile after building a normal debug x64 APK and booting a dedicated
emulator:

```sh
python3 ../../.github/scripts/android_process_recovery.py
```

The dedicated workflow builds before booting, retains reports/screenshots/logcat
and source/APK/toolchain diagnostics, uses pinned actions/toolchain, bounded
readiness and the existing emulator cleanup. PR path triggers and manual dispatch
are supported. Six host tests cover emulator guards, actual XML shape, exact
restoration, authorized single-pass and rejection of altered state. They passed
locally; installed execution is pending until the exact-head workflow passes.

Initial run46096833818 failed during the first UIAutomator read: Android had not
written /sdcard/ludo-window.xml yet. Actual screenshot showed native startup and
logcat showed the engine/VM starting, not a demonstrated app crash. Readiness now
retains missing/malformed-window errors and retries within the existing30/45s
caller deadlines. No timeout increase, application change or missing UI pass.
The original failed run remains failed; fresh exact-head installed proof is required.

This is debug emulator process termination evidence, not physical-device,
release-build, reboot/power-loss durability, low-memory soak, atomic filesystem
proof,60fps performance or online recovery acceptance. The existing seeded
recording workflow remains separate; no MP4 is claimed by this check.
