# Android checkpoint resource isolation

The profile/logo UI in PR #73 passes all 446 tests, strict formatting/analysis,
Android debug/profile/release/AAB builds and installed iOS scenarios/screenshots.
Its opt-in Android emulator checkpoint failed twice on source
`b674d2870de5a763ee9820de141d5a28b5672560` (run44508864048, jobs135507512125
and135512265757). After launch/driver attachment, the VM service disappeared,
ADB became offline and the emulator's5554 control port refused connections.
The retry reached the second scenario. No widget assertion failure was reported.
This proves loss of the emulator environment, not the underlying host kill reason;
the old post-failure ADB diagnostics could not recover guest logs.

Inspection found the generated Flutter3.35.7 Gradle template permits an8GB heap
and4GB metaspace. The checkpoint compiles Gradle/Kotlin while a2GB emulator is
already running and leaves Java daemons alive. This is a concrete budget/overlap
risk on the standard hosted runner; an OOM kill is a hypothesis, not a proven cause.

The focused follow-up changes CI only:

- Cap Gradle heap4GB/metaspace1GB, use two workers, compile Kotlin in-process,
  disable persistent Gradle daemons and explicitly stop them after compilation.
- Build the identical x86_64 debug integration target/defines before booting the emulator.
- Use the pinned SDK's supported `flutter drive --use-application-binary` path to
  install/launch that APK, retaining the same screenshot driver and scenarios.
- Add host memory/process/kernel diagnostics so a further failure distinguishes
  host resource loss from a guest/app assertion or graphics failure.

No UI, engine, fixture, timeout or required screenshot change. Job25m/emulator20m
outer bounds remain; the new prebuild stage has a10m bound within that job.
YAML/Bash parse checks pass. Three actual configuration-transform fixtures verify
AndroidX preservation, removal of old/duplicate limits, expected caps and idempotency.
The SDK's DriveService explicitly marks a supplied application binary prebuilt,
skipping compilation during emulator execution. Native result is recorded in the PR.

This is not evidence of phone performance or physical-device acceptance. Historical
failed runs stay failed. No test is disabled and no PR is merged automatically.
Review after #73, itself dependent on #72 and the preceding implementation stack.


The first isolated run44512155537 failed before emulator boot because the initial
2GB cap exhausted Java heap during JetifyTransform of the x86_64 debug engine.
This is an explicit compiler-memory failure, distinct from the earlier emulator
losses. Host telemetry reports15,701MB total RAM. The follow-up uses4GB heap/1GB
metaspace and builds only android-x64, matching the emulator ABI and avoiding
unnecessary ARM engine transforms. Compilation remains separated from QEMU;
no test or timeout is relaxed. This build-cap adjustment is based on actual logs,
not a claimed proof of the original emulator kill cause.


Run44513158990 passed the4GB/x86 prebuild, then again lost QEMU during the first
scenario. Downloaded host diagnostics14524093542 (ZIP SHA256
`a38c105ec4297acf7ef21da931b60c4d702674e77f47e89a7e86ba6de27d2250`)
show14,502MB available after failure and no kernel OOM/kill entry. A native crash
reporter (`apport`) was present; this does not prove an exact graphics stack frame.
Compilation overlap is not a sufficient explanation. The next checkpoint disables
Vulkan software emulation while retaining SwiftShader OpenGL and the identical
app/driver/scenarios/screenshots. Bounded, allowlisted native QEMU crash summaries are added; process environments
and raw core/minidump contents are excluded.
This is a headless-emulator backend configuration, not a change to the production
Flutter renderer. Physical Vulkan acceptance remains unverified, and success on
software OpenGL must not be reported as a physical GPU benchmark or Vulkan pass.

OpenGL run44514945790 also lost QEMU (diagnostics14526285608, verified ZIP
SHA25602fd9ee759f915e75b613a01b7e63d78d090c66bb5800c4d39699f2359782057).
Host available RAM was14,885MB; no native summary/minidump filename was produced.
Disabling Vulkan did not resolve the failure and must not be described as a fix.
The next diagnostic matrix compares current UI with the previously verified mobile
source22bb509ec95af8c816d7a6ec6275fcf356d0edf1. Both use identical current CI,
Flutter/emulator configuration, prebuild, scenarios and screenshot requirements.
Only the control's apps/mobile tree is restored in its isolated ephemeral checkout.
Jobs and artifacts explicitly identify current versus known-baseline. Fail-fast
is false so a failure cannot cancel the independent control. A baseline pass must
never count as new-UI acceptance; this is a diagnostic comparison, not a renderer
performance benchmark or a product-rule change.
