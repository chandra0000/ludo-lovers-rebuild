import 'player_color.dart';

class NormalizedBoardPoint {
  const NormalizedBoardPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      other is NormalizedBoardPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class BoardCell {
  const BoardCell(this.column, this.row);

  final int column;
  final int row;

  bool get isInside => column >= 0 && column < 15 && row >= 0 && row < 15;

  NormalizedBoardPoint get normalizedCenter => NormalizedBoardPoint(
        (column + 0.5) / 15,
        (row + 0.5) / 15,
      );
}

class PlayerBoardSeat {
  const PlayerBoardSeat({
    required this.entryIndex,
    required this.yardColumn,
    required this.yardRow,
    required this.homeLane,
  });

  final int entryIndex;
  final int yardColumn;
  final int yardRow;
  final List<BoardCell> homeLane;
}

class BoardGeometry {
  const BoardGeometry._();

  static const int gridSize = 15;
  static const int trackLength = 52;
  static const int playerTrackLength = 51;
  static const int homeLaneLength = 5;

  // Physical cell centers mapped to the approved 15×15 board artwork.
  // The four documented corner connectors are diagonal by design.
  static const List<BoardCell> sharedTrack = <BoardCell>[
    BoardCell(1, 6),
    BoardCell(2, 6),
    BoardCell(3, 6),
    BoardCell(4, 6),
    BoardCell(5, 6),
    BoardCell(6, 5),
    BoardCell(6, 4),
    BoardCell(6, 3),
    BoardCell(6, 2),
    BoardCell(6, 1),
    BoardCell(6, 0),
    BoardCell(7, 0),
    BoardCell(8, 0),
    BoardCell(8, 1),
    BoardCell(8, 2),
    BoardCell(8, 3),
    BoardCell(8, 4),
    BoardCell(8, 5),
    BoardCell(9, 6),
    BoardCell(10, 6),
    BoardCell(11, 6),
    BoardCell(12, 6),
    BoardCell(13, 6),
    BoardCell(14, 6),
    BoardCell(14, 7),
    BoardCell(14, 8),
    BoardCell(13, 8),
    BoardCell(12, 8),
    BoardCell(11, 8),
    BoardCell(10, 8),
    BoardCell(9, 8),
    BoardCell(8, 9),
    BoardCell(8, 10),
    BoardCell(8, 11),
    BoardCell(8, 12),
    BoardCell(8, 13),
    BoardCell(8, 14),
    BoardCell(7, 14),
    BoardCell(6, 14),
    BoardCell(6, 13),
    BoardCell(6, 12),
    BoardCell(6, 11),
    BoardCell(6, 10),
    BoardCell(6, 9),
    BoardCell(5, 8),
    BoardCell(4, 8),
    BoardCell(3, 8),
    BoardCell(2, 8),
    BoardCell(1, 8),
    BoardCell(0, 8),
    BoardCell(0, 7),
    BoardCell(0, 6),
  ];

  static const Set<int> cornerConnectorIndexes = <int>{4, 17, 30, 43};
  static const Set<int> safeTrackCells = <int>{0, 8, 13, 21, 26, 34, 39, 47};
  static const BoardCell finishCell = BoardCell(7, 7);

  static const Map<PlayerColor, PlayerBoardSeat> seats =
      <PlayerColor, PlayerBoardSeat>{
    PlayerColor.orange: PlayerBoardSeat(
      entryIndex: 0,
      yardColumn: 0,
      yardRow: 0,
      homeLane: <BoardCell>[
        BoardCell(1, 7),
        BoardCell(2, 7),
        BoardCell(3, 7),
        BoardCell(4, 7),
        BoardCell(5, 7),
      ],
    ),
    PlayerColor.green: PlayerBoardSeat(
      entryIndex: 13,
      yardColumn: 9,
      yardRow: 0,
      homeLane: <BoardCell>[
        BoardCell(7, 1),
        BoardCell(7, 2),
        BoardCell(7, 3),
        BoardCell(7, 4),
        BoardCell(7, 5),
      ],
    ),
    PlayerColor.magenta: PlayerBoardSeat(
      entryIndex: 26,
      yardColumn: 9,
      yardRow: 9,
      homeLane: <BoardCell>[
        BoardCell(13, 7),
        BoardCell(12, 7),
        BoardCell(11, 7),
        BoardCell(10, 7),
        BoardCell(9, 7),
      ],
    ),
    PlayerColor.blue: PlayerBoardSeat(
      entryIndex: 39,
      yardColumn: 0,
      yardRow: 9,
      homeLane: <BoardCell>[
        BoardCell(7, 13),
        BoardCell(7, 12),
        BoardCell(7, 11),
        BoardCell(7, 10),
        BoardCell(7, 9),
      ],
    ),
  };

  static const List<NormalizedBoardPoint> _yardOffsets =
      <NormalizedBoardPoint>[
    NormalizedBoardPoint(2.22, 2.22),
    NormalizedBoardPoint(3.78, 2.22),
    NormalizedBoardPoint(2.22, 3.78),
    NormalizedBoardPoint(3.78, 3.78),
  ];

  static NormalizedBoardPoint normalizedPosition(
    PlayerColor color,
    int progress,
    int pawnIndex,
  ) {
    final seat = seats[color]!;
    if (pawnIndex < 0 || pawnIndex > 3) {
      throw RangeError.range(pawnIndex, 0, 3, 'pawnIndex');
    }
    if (progress == -1) {
      final offset = _yardOffsets[pawnIndex];
      return NormalizedBoardPoint(
        (seat.yardColumn + offset.x) / gridSize,
        (seat.yardRow + offset.y) / gridSize,
      );
    }
    if (progress < -1 || progress > 56) {
      throw RangeError.range(progress, -1, 56, 'progress');
    }
    if (progress == 56) {
      return finishCell.normalizedCenter;
    }
    if (progress < playerTrackLength) {
      return sharedTrack[(seat.entryIndex + progress) % trackLength].normalizedCenter;
    }
    return seat.homeLane[progress - playerTrackLength].normalizedCenter;
  }

  static int physicalTrackCell(PlayerColor color, int progress) {
    if (progress < 0 || progress >= playerTrackLength) {
      throw RangeError.range(progress, 0, playerTrackLength - 1, 'progress');
    }
    return (seats[color]!.entryIndex + progress) % trackLength;
  }

  static bool get isStructurallyValid =>
      sharedTrack.length == trackLength &&
      sharedTrack.toSet().length == trackLength &&
      sharedTrack.every((cell) => cell.isInside) &&
      seats.values.every(
        (seat) =>
            seat.homeLane.length == homeLaneLength &&
            seat.homeLane.toSet().length == homeLaneLength &&
            seat.homeLane.every((cell) => cell.isInside),
      );

  static List<int> get nonOrthogonalTransitions {
    final result = <int>[];
    for (var index = 0; index < sharedTrack.length; index++) {
      final from = sharedTrack[index];
      final to = sharedTrack[(index + 1) % sharedTrack.length];
      final distance =
          (from.column - to.column).abs() + (from.row - to.row).abs();
      if (distance != 1) {
        result.add(index);
      }
    }
    return List<int>.unmodifiable(result);
  }

  // This remains a release gate until visual review is performed on the
  // original artwork and the intended rules profile is signed off.
  static const bool visualApprovalPending = true;
}
