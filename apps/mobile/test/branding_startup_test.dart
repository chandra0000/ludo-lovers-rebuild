import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/splash/splash_screen.dart';
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
  testWidgets('fresh startup opens Play Now', (tester) async {
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
  testWidgets('game utility controls never open a pawn selection sheet at 200%',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const MatchScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessible_pawn_chooser')), findsNothing);
    expect(find.byKey(const Key('chat_button')), findsOneWidget);
    expect(find.byKey(const Key('more_button')), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
