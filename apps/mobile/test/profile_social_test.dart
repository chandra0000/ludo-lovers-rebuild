import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/features/match/local_match_chat_sheet.dart';
import 'package:ludo_lovers/src/features/match/social_overlay_coordinator.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(393, 873),
    const Size(430, 932),
  ]) {
    testWidgets('eight profile social controls fit outside board at $size',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
      await tester.pumpAndSettle();
      final board = tester.getRect(find.byKey(const Key('board_stage')));
      for (final player in PlayerColor.turnOrder) {
        final card = tester.getRect(find.byKey(Key('profile_${player.name}')));
        for (final action in ['chat', 'emoji']) {
          final rect = tester
              .getRect(find.byKey(Key('profile_${action}_${player.name}')));
          final icon = tester.widget<Icon>(
            find.descendant(
              of: find.byKey(Key('profile_${action}_${player.name}')),
              matching: find.byType(Icon),
            ),
          );
          expect(icon.size, 20);
          expect(rect.size.width, greaterThanOrEqualTo(48));
          expect(rect.size.height, greaterThanOrEqualTo(48));
          expect(rect.overlaps(board), isFalse);
          expect(card.contains(rect.center), isTrue);
        }
      }
      expect(find.byKey(const Key('quick_reactions_button')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('profiles and square avatars grow with usable portrait space',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final avatars = <double>[];
    final heights = <double>[];
    for (final size in [const Size(320, 640), const Size(430, 932)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
      await tester.pumpAndSettle();
      avatars.add(
        tester.getSize(find.byKey(const Key('profile_avatar_orange'))).width,
      );
      heights
          .add(tester.getSize(find.byKey(const Key('profile_orange'))).height);
      expect(tester.takeException(), isNull);
    }
    expect(avatars.first, greaterThan(40));
    expect(avatars.last, greaterThan(avatars.first + 15));
    expect(heights.last, greaterThan(heights.first));
  });
  testWidgets('preset is attributed to selected seat without a game command',
      (tester) async {
    final versions = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          saveMatch: (save) async {
            versions.add(save.game.stateVersion);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_chat_green')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preset_Nice move!')));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10)); // dismiss local sheet
    await tester.pumpAndSettle();
    final bubble =
        tester.getRect(find.byKey(const Key('local_reaction_toast')));
    final green = tester.getRect(find.byKey(const Key('profile_green')));
    expect(green.contains(bubble.center), isTrue);
    expect(versions, isNotEmpty);
    expect(versions.every((version) => version == 0), isTrue);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('local_reaction_toast')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  testWidgets('inactive seats cannot send local social feedback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          initialGame: ModeRegistry.create(
            MatchMode.classic,
            playerCount: 2,
            allowInternal: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_chat_green')), findsNothing);
    expect(find.byKey(const Key('profile_emoji_blue')), findsNothing);
    expect(find.byKey(const Key('profile_chat_magenta')), findsOneWidget);
  });
  testWidgets('coordinator replaces, expires and cancels per-seat timers',
      (tester) async {
    final social = SocialOverlayCoordinator();
    social.show(PlayerColor.blue, '👏');
    await tester.pump(const Duration(seconds: 1));
    social.show(PlayerColor.blue, '🔥');
    social.show(PlayerColor.orange, 'Good luck!');
    await tester.pump(const Duration(milliseconds: 1200));
    expect(social.forPlayer(PlayerColor.blue)!.text, '🔥');
    await tester.pump(const Duration(seconds: 1));
    expect(social.forPlayer(PlayerColor.blue), isNull);
    expect(social.forPlayer(PlayerColor.orange), isNull);
    social.show(PlayerColor.green, 'Hello');
    social.clear();
    expect(social.forPlayer(PlayerColor.green), isNull);
    social.show(PlayerColor.magenta, 'Bye');
    social.dispose();
    await tester.pump(const Duration(seconds: 4));
    expect(social.forPlayer(PlayerColor.magenta), isNull);
    social.show(PlayerColor.blue, 'ignored');
    expect(social.forPlayer(PlayerColor.blue), isNull);
    expect(tester.takeException(), isNull);
  });
  testWidgets('local sheet handles compact enlarged text and keyboard insets',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            viewInsets: EdgeInsets.only(bottom: 250),
          ),
          child: Scaffold(body: LocalMatchChatSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('local_chat_input')), findsOneWidget);
  });
}
