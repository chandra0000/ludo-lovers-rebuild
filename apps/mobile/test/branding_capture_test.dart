import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/features/home/home_screen.dart';
import 'package:ludo_lovers/src/features/setup/game_setup_screen.dart';
import 'package:ludo_lovers/src/features/setup/mode_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/splash/splash_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'support/load_sdk_fonts.dart';
import 'support/capture_artifact.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(393, 873),
    Size(430, 932),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('bundled typography safe areas and ${scale}x text at $size',
          (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('type_capture'),
            child: Builder(
              builder: (context) {
                final theme =
                    (const LudoLoversApp().build(context) as MaterialApp).theme;
                return MaterialApp(
                  theme: theme,
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: MatchScreen(
                    profiles: MatchPlayerProfile.local(
                      names: const {
                        PlayerColor.orange: 'Éléonore Alexandra',
                        PlayerColor.green: 'Renée',
                        PlayerColor.blue: 'Zoë 🌟',
                        PlayerColor.magenta: 'Māya',
                      },
                    ),
                    rollDice: () => 6,
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final board = tester.getSize(find.byKey(const Key('board_stage')));
        expect(board.width, closeTo(board.height, .01));
        expect(board.width, greaterThan(100));
        expect(
          tester.getRect(find.byKey(const Key('more_button'))).height,
          greaterThanOrEqualTo(48),
        );
        expect(
          MediaQuery.textScalerOf(tester.element(find.byType(MatchScreen)))
              .scale(15),
          15 * scale,
        );
        await captureArtifact(
          tester,
          'branding-match-${size.width.toInt()}x${size.height.toInt()}-${scale}x',
          key: const Key('type_capture'),
        );
        if (size.width == 393 && scale == 1) {
          await tester.tap(find.byKey(const Key('roll_dice')));
          await tester.pumpAndSettle();
          await tester.pumpAndSettle();
          await captureArtifact(
            tester,
            'branding-direct-pawn-selection',
            key: const Key('type_capture'),
          );
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final surface in <String, Widget>{
    'home': const HomeScreen(),
    'setup': const GameSetupScreen(),
    'modes': const ModeSelectionScreen(),
  }.entries) {
    testWidgets('${surface.key} is readable at 200% on compact phone',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('large_surface'),
          child: Builder(
            builder: (context) {
              final theme =
                  (const LudoLoversApp().build(context) as MaterialApp).theme;
              return MaterialApp(
                theme: theme,
                debugShowCheckedModeBanner: false,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: surface.value,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureArtifact(
        tester,
        'branding-${surface.key}-320x640-2x',
        key: const Key('large_surface'),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
  testWidgets('Team Up scores remain readable at 200% on compact phone',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('large_team'),
        child: Builder(
          builder: (context) {
            final theme =
                (const LudoLoversApp().build(context) as MaterialApp).theme;
            return MaterialApp(
              theme: theme,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: MatchScreen(
                initialGame: ModeRegistry.create(
                  MatchMode.teamUp,
                  allowInternal: true,
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await captureArtifact(
      tester,
      'branding-team-up-320x640-2x',
      key: const Key('large_team'),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  testWidgets('capture actual proportional Flutter splash before readiness',
      (tester) async {
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('splash_capture'),
        child: MaterialApp(
          home: SplashScreen(
            loadOnboarding: () => Future<bool>.delayed(
              const Duration(seconds: 1),
              () => true,
            ),
          ),
        ),
      ),
    );
    await captureArtifact(
      tester,
      'branding-flutter-splash',
      key: const Key('splash_capture'),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
