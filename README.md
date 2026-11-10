# Ludo Lovers — Rebuild

A clean, Android-first Flutter implementation of Ludo Lovers.

## First milestone

Deliver one reliable local match with a stable first frame, faithful board artwork rendering, deterministic pawn coordinates, and automated rule/UI tests. Additional modes and online services are out of scope until this foundation is accepted.

## Product constraints

- Preserve the approved black-and-gold premium glassmorphism identity.
- Preserve the original board artwork without cropping or distortion.
- Player colours: Orange `#FF8928`, Green `#33FF28`, Blue `#289EFF`, Magenta `#F428FF`.
- Turn order: Orange → Green → Magenta → Blue.
- Keep game rules and board geometry independent from Flutter widgets.
- Never mark device acceptance complete without a real Android device test.

## Local Android setup

```bash
cd apps/mobile
flutter create --platforms=android --project-name=ludo_lovers --org=com.ludolovers .
flutter pub get
flutter test
flutter run
```

The Android platform scaffold is generated in CI and can be generated locally with the command above.

## Current status

The first Flutter foundation is under review in [PR #1](https://github.com/chandra0000/ludo-lovers-rebuild/pull/1). The portrait artwork is bundled with interactive pawn/dice overlays and a provisional local rules engine. Board geometry still needs visual acceptance, and no physical-device validation has been performed yet.
