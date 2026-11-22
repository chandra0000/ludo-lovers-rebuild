import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/support/local_mode_navigation.dart';
import '../test/support/setup_navigation.dart';
import 'support/gameplay_recording.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  if (const bool.fromEnvironment('LUDO_RECORD_GAMEPLAY')) {
    // Paint the real app while the driver attaches, rather than an empty test
    // surface. Normal release/default integration entrypoints are unchanged.
    runApp(const LudoLoversApp());
  }
  // Diagnose native accessibility activation separately from test-owned handles.
  final dispatcher = binding.platformDispatcher;
  final previousSemanticsCallback = dispatcher.onSemanticsEnabledChanged;
  dispatcher.onSemanticsEnabledChanged = () {
    debugPrint(
      'NATIVE_SEMANTICS before=${binding.debugOutstandingSemanticsHandles} enabled=${dispatcher.semanticsEnabled}',
    );
    previousSemanticsCallback?.call();
    debugPrint(
      'NATIVE_SEMANTICS after=${binding.debugOutstandingSemanticsHandles}',
    );
  };
  tearDownAll(
    () => dispatcher.onSemanticsEnabledChanged = previousSemanticsCallback,
  );
  setUp(
    () => debugPrint(
      'TEST_SEMANTICS start=${binding.debugOutstandingSemanticsHandles} native=${dispatcher.semanticsEnabled}',
    ),
  );
  tearDown(
    () => debugPrint(
      'TEST_SEMANTICS end=${binding.debugOutstandingSemanticsHandles} native=${dispatcher.semanticsEnabled}',
    ),
  );
  var surfaceConverted = false;
  setUp(() => surfaceConverted = false);
  Future<void> capture(WidgetTester tester, String name) async {
    final errors = <Object>[];
    final context = tester.element(find.byType(MaterialApp));
    final providers = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .toSet();
    await tester.runAsync(
      () => Future.wait(
        providers.map(
          (provider) => precacheImage(
            provider,
            context,
            onError: (error, stack) => errors.add(error),
          ),
        ),
      ).timeout(const Duration(seconds: 10)),
    );
    expect(errors, isEmpty, reason: 'Installed capture $name asset readiness');
    await tester.pump();
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Capture the actual Android display without replacing Flutter's surface.
      debugPrint('LUDO_NATIVE_CAPTURE:$name');
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
      return;
    }
    if (!surfaceConverted) {
      // SDK registers teardown to revert the Android image surface after each test.
      await binding.convertFlutterSurfaceToImage();
      surfaceConverted = true;
      await tester.pump();
    }
    // Live test bindings fade pointer crosses over two paint frames. Include
    // one clean frame before capture; never retouch the resulting screenshot.
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await binding.takeScreenshot(name).timeout(const Duration(seconds: 15));
  }

  if (const bool.fromEnvironment('LUDO_RECORD_GAMEPLAY')) {
    registerGameplayRecording();
  }
  testWidgets(
    'home to local match navigation survives repeated exits',
    (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed_v1': true,
      });

      await tester.pumpWidget(const LudoLoversApp());
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('open_game_setup')), findsOneWidget);

      for (var cycle = 0; cycle < 3; cycle++) {
        await tester.tap(find.byKey(const Key('open_game_setup')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('start_local_match')), findsOneWidget);

        if (cycle == 0) {
          await tester.tap(find.byKey(const Key('edit_player_names')));
          await tester.pumpAndSettle();
          await tester
              .ensureVisible(find.byKey(const Key('player_name_orange')));
          await tester.enterText(
            find.byKey(const Key('player_name_orange')),
            'Élan',
          );
          await tester
              .ensureVisible(find.byKey(const Key('player_name_green')));
          await tester.enterText(
            find.byKey(const Key('player_name_green')),
            'Renée',
          );
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester
              .ensureVisible(find.byKey(const Key('edit_player_names')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('edit_player_names')));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('player_name_orange')), findsNothing);
        }
        // Setup uses a lazy ListView. Collapsing the name editor can leave the
        // start card outside the built sliver; ensureVisible alone cannot find it.
        await revealLocalMatchStart(tester);
        await tester.tap(find.byKey(const Key('start_local_match')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('board_artwork')), findsOneWidget);
        expect(find.byKey(const Key('roll_dice')), findsOneWidget);
        if (cycle == 0) await capture(tester, 'native-ffa-match');
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('exit_match')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_leave_match')));
        await tester.pumpAndSettle();
        // Exiting a match returns to Game Setup, not directly to Home.
        expect(find.byKey(const Key('start_local_match')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  testWidgets(
    'installed local modes support roll, restart and saved resume',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await verifyLocalModeNavigation(
        tester,
        capture: (name) => capture(tester, name),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
  testWidgets(
    'installed computer setup and profile social surfaces',
    (tester) async {
      SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
      await tester.pumpWidget(const LudoLoversApp());
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.pumpAndSettle();
      final modes = find.byKey(const Key('open_mode_selection'));
      await tester.ensureVisible(modes);
      await tester.tap(modes);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('launch_computer')));
      await tester.pumpAndSettle();
      final start = find.byKey(const Key('start_ai_match'));
      await tester.scrollUntilVisible(
        start,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(start);
      await tester.pumpAndSettle();
      await capture(tester, 'native-computer-match');
      await tester.tap(find.byKey(const Key('profile_emoji_orange')));
      await tester.pumpAndSettle();
      await capture(tester, 'native-emoji-picker');
      await tester.tap(find.text('🔥'));
      await tester.pumpAndSettle();
      await capture(tester, 'native-profile-bubble');
      await tester.tap(find.byKey(const Key('profile_chat_orange')));
      await tester.pumpAndSettle();
      await capture(tester, 'native-local-chat');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
