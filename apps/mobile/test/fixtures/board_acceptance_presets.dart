import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

/// Deterministic game states for inspecting board/pawn rendering.
///
/// These fixtures are deliberately test-only: they do not add a player-facing
/// debug route or alter the production game flow.
abstract final class BoardAcceptancePresets {
  static const int trackLength = 52;

  static LudoGame get allYardSocketsFilled => _game({
        for (final color in PlayerColor.turnOrder)
          color: const [-1, -1, -1, -1],
      });

  static LudoGame get singlePawnOnTrack => _game({
        PlayerColor.orange: [5, -1, -1, -1],
      });

  /// Two friendly pawns occupy physical shared-track cell 10.
  static LudoGame get friendlyTwoPawnStackAtCell10 => _game({
        PlayerColor.orange: [10, 10, -1, -1],
      });

  /// Three different colours occupy safe physical cell 21.
  static LudoGame get mixedThreePawnStackAtSafeCell21 => _game({
        PlayerColor.orange: [
          _progressForCell(PlayerColor.orange, 21),
          -1,
          -1,
          -1,
        ],
        PlayerColor.green: [
          _progressForCell(PlayerColor.green, 21),
          -1,
          -1,
          -1,
        ],
        PlayerColor.magenta: [
          _progressForCell(PlayerColor.magenta, 21),
          -1,
          -1,
          -1,
        ],
      });

  static LudoGame get pawnAtHomeLaneEntry => _game({
        PlayerColor.orange: [51, -1, -1, -1],
      });

  static LudoGame get pawnAtGoal => _game({
        PlayerColor.orange: [56, -1, -1, -1],
      });

  static LudoGame _game(Map<PlayerColor, List<int>> progress) =>
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: progress,
      );

  static int _progressForCell(PlayerColor color, int physicalCell) =>
      (physicalCell - color.entryIndex + trackLength) % trackLength;
}
