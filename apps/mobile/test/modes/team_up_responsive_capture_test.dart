import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/match_player_profile.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import '../support/capture_artifact.dart';
import '../support/load_sdk_fonts.dart';

void main() {
  setUpAll(loadSdkFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(393, 873),
    const Size(430, 932),
    const Size(320, 568),
  ]) {
    testWidgets('Team Up full board and teams fit $size', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      await tester.pumpWidget(
        MaterialApp(
          home: MatchScreen(
            initialGame:
                ModeRegistry.create(MatchMode.teamUp, allowInternal: true),
            profiles: MatchPlayerProfile.local(
              names: {
                PlayerColor.orange: 'Aarav',
                PlayerColor.green: 'Zoë',
                PlayerColor.magenta: 'Maya',
                PlayerColor.blue: 'Noah',
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final stage = tester.getRect(find.byKey(const Key('board_stage')));
      final art = tester.getRect(find.byKey(const Key('board_artwork')));
      expect(stage.width, closeTo(stage.height, .01));
      expect(art.top, greaterThanOrEqualTo(stage.top - .01));
      expect(art.bottom, lessThanOrEqualTo(stage.bottom + .01));
      for (final key in [
        'roll_dice',
        'chat_button',
        'quick_reactions_button',
        'more_button',
        'exit_match',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.width, greaterThanOrEqualTo(48));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      final canvas = tester.getRect(find.byKey(const Key('match_canvas')));
      final scale = canvas.width / 576;
      for (final color in PlayerColor.turnOrder) {
        final avatar =
            tester.getRect(find.byKey(Key('profile_avatar_${color.name}')));
        expect(avatar.width, closeTo(avatar.height, .01));
        for (var pawn = 0; pawn < 4; pawn++) {
          final point = BoardGeometry.canvasPosition(
            BoardGeometry.normalizedPosition(color, -1, pawn),
          );
          final actual =
              tester.getCenter(find.byKey(Key('pawn_${color.name}_$pawn')));
          expect(actual.dx, closeTo(canvas.left + point.x * scale, .5));
          expect(actual.dy, closeTo(canvas.top + point.y * scale, .5));
        }
      }
      await captureArtifact(
        tester,
        'team-up-match-${size.width.toInt()}x${size.height.toInt()}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  for (final won in [false, true]) {
    testWidgets('capture Team Up ${won ? 'winning' : 'transferred'} state',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 873);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var game = LudoGame.fromProgress(
        activePlayer: PlayerColor.magenta,
        pawnProgress: {
          PlayerColor.orange: [56, 56, 56, 56],
          if (won) PlayerColor.magenta: [56, 56, 56, 55],
        },
        ruleProfile: LudoRuleProfile.teamUpV1,
        configuration: MatchConfiguration.local(MatchMode.teamUp),
        scheduledPlayer: won ? PlayerColor.magenta : PlayerColor.orange,
      );
      if (won) game = game.roll(1).movePawn(3);
      await tester
          .pumpWidget(MaterialApp(home: MatchScreen(initialGame: game)));
      await tester.pump();
      await captureArtifact(
        tester,
        'team-up-${won ? 'winning' : 'transferred'}-393x873',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}
