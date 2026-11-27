import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main() {
  testWidgets('live pawn overlays align to track, lane and finish anchors',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    const progressByColor = <PlayerColor, int>{
      PlayerColor.orange: 5,
      PlayerColor.green: 51,
      PlayerColor.magenta: 56,
      PlayerColor.blue: 48,
    };
    final game = LudoGame.fromProgress(
      activePlayer: PlayerColor.orange,
      pawnProgress: {
        for (final entry in progressByColor.entries)
          entry.key: [entry.value, -1, -1, -1],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: MatchScreen(initialGame: game)),
    );
    await tester.pump();

    final canvasRect = tester.getRect(find.byKey(const Key('match_canvas')));
    final scale = canvasRect.width / BoardGeometry.canvasWidth;
    for (final entry in progressByColor.entries) {
      final point = BoardGeometry.canvasPosition(
        BoardGeometry.normalizedPosition(entry.key, entry.value, 0),
      );
      final isHome = entry.value == 56;
      final lane = BoardGeometry.canvasPosition(
        BoardGeometry.normalizedPosition(entry.key, 55, 0),
      );
      final direction = Offset(lane.x - point.x, lane.y - point.y);
      final axis = direction / direction.distance;
      final offset =
          isHome ? axis * 18 + Offset(-axis.dy, axis.dx) * -4.5 : Offset.zero;
      final expected = Offset(
        canvasRect.left + (point.x + offset.dx) * scale,
        canvasRect.top + (point.y + offset.dy) * scale,
      );
      final key = isHome
          ? 'home_token_${entry.key.name}_0'
          : 'pawn_${entry.key.name}_0';
      final actual = tester.getCenter(find.byKey(Key(key)));
      expect(
        actual.dx,
        closeTo(expected.dx, 0.5),
        reason: '${entry.key} pawn horizontal placement',
      );
      expect(
        actual.dy,
        closeTo(expected.dy, 0.5),
        reason: '${entry.key} pawn vertical placement',
      );
    }
  });
}
