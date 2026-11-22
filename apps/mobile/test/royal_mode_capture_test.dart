import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'support/capture_artifact.dart';
import 'support/load_sdk_fonts.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const Key('royal_app_capture'),
        child: Builder(
          builder: (context) {
            final app = const LudoLoversApp().build(context) as MaterialApp;
            return MaterialApp(
              theme: app.theme,
              debugShowCheckedModeBanner: false,
              home: child,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await captureArtifact(tester, name, key: const Key('royal_app_capture'));
    expect(tester.takeException(), isNull);
  }

  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  for (final entry in [
    (id: 'ffa', mode: MatchMode.compatibility, count: 4, bots: false),
    (id: '1v1', mode: MatchMode.classic, count: 2, bots: false),
    (id: 'computer', mode: MatchMode.compatibility, count: 4, bots: true),
    (id: 'team-up', mode: MatchMode.teamUp, count: 4, bots: false),
  ]) {
    testWidgets('capture royal ${entry.id} live match', (tester) async {
      await mount(
        tester,
        MatchScreen(
          initialGame: ModeRegistry.create(
            entry.mode,
            playerCount: entry.count,
            allowInternal: true,
          ),
          aiPlayers: entry.bots
              ? {PlayerColor.green, PlayerColor.magenta, PlayerColor.blue}
              : const {},
        ),
      );
      await capture(tester, 'royal-${entry.id}-393x873');
      await dispose(tester);
    });
  }
  testWidgets('capture actual local emoji picker and seat bubble',
      (tester) async {
    await mount(tester, const MatchScreen());
    await tester.tap(find.byKey(const Key('profile_emoji_blue')));
    await tester.pumpAndSettle();
    await capture(tester, 'royal-emoji-picker-393x873');
    await tester.tap(find.text('🔥'));
    await tester.pumpAndSettle();
    await capture(tester, 'royal-profile-bubble-393x873');
    final card = tester.getRect(find.byKey(const Key('profile_blue')));
    final bubble =
        tester.getRect(find.byKey(const Key('local_reaction_toast')));
    expect(card.contains(bubble.center), isTrue);
    await dispose(tester);
  });
  testWidgets('capture actual player chat presets', (tester) async {
    await mount(tester, const MatchScreen());
    await tester.tap(find.byKey(const Key('profile_chat_orange')));
    await tester.pumpAndSettle();
    await capture(tester, 'royal-local-chat-393x873');
    await dispose(tester);
  });
}
