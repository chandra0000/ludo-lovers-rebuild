# Android bundle compilation gate

The foundation workflow builds debug, split profile/release APKs and a release
AAB from pinned Flutter 3.35.7. The AAB artifact is explicitly named
`ludo-validation-only-app-bundle-not-production-signed`.

The generated Android runner currently signs release outputs with its debug
certificate. This artifact proves bundle compilation only. It must not be promoted
as a production-signed or Play-accepted bundle. No production key or store upload
is introduced. Release engineering still requires committed/reviewed native app
identity, launcher icon/label, signing/keystore access, distribution configuration,
Play validation and physical-device acceptance. Preserve the approved logo when
reviewing launcher assets; do not approve Flutter's generated launcher for release.

AAB generation is an additional automated check, not a workaround for signing or
physical acceptance. CI must fail on a failed build or missing artifact.
