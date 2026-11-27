import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/splash/splash_screen.dart';
import 'package:ludo_lovers/src/features/match/pawn_chooser.dart';
import 'package:ludo_lovers/src/theme/app_typography.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('approved semantic type roles and colors have measured dark contrast',
      () {
    expect(AppTypography.heading.fontFamily, 'Cinzel');
    expect(AppTypography.heading.fontWeight, FontWeight.w700);
    expect(AppTypography.button.fontWeight, FontWeight.w800);
    expect(AppTypography.playerName.fontWeight, FontWeight.w700);
    expect(AppTypography.status.fontWeight, FontWeight.w600);
    expect(AppTypography.body.fontWeight, FontWeight.w400);
    for (final color in [AppTypography.gold, AppTypography.ivory]) {
      for (final bg in [AppTypography.background, const Color(0xFF171320)]) {
        expect(
          (color.computeLuminance() + .05) / (bg.computeLuminance() + .05),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });
  testWidgets('ready startup has no fixed branding delay', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpWidget(const LudoLoversApp());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
  });
  testWidgets('startup failure is recoverable and retries once ready',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          loadOnboarding: () async {
            if (calls++ == 0) throw StateError('storage unavailable');
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startup_retry')), findsOneWidget);
    await tester.tap(find.byKey(const Key('startup_retry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
  });
  testWidgets('disposed startup completion cannot navigate', (tester) async {
    final completer = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(loadOnboarding: () => completer.future),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    completer.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('startup completion waits for resume', (tester) async {
    final ready = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(loadOnboarding: () => ready.future)),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    ready.complete(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splash_background')), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
  });
  testWidgets(
      'unresponsive initialization reaches retry after bounded deadline',
      (tester) async {
    final ready = Completer<bool>();
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(loadOnboarding: () => ready.future)),
    );
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startup_retry')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    ready.complete(true);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'pawn sheet shows all identities and excludes illegal commands at 200%',
      (tester) async {
    int? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showPawnChooser(
                    context,
                    [0, 2],
                    (v) => chosen = v,
                  ),
                  child: const Text('Choose'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.text('Pawn 1'), findsOneWidget);
    expect(find.text('Pawn 2'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('pawn_choice_0'))).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Pawn 2'));
    expect(chosen, isNull);
    await tester.tap(find.text('Pawn 1'));
    await tester.pumpAndSettle();
    expect(chosen, 0);
  });
}
