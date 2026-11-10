import 'player_color.dart';

/// A point normalized against the complete 810×1440 source artwork.
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

/// Logical board topology only. Rendering coordinates live in [BoardGeometry]
/// because the approved artwork has non-uniform arm and centre proportions.
class BoardCell {
  const BoardCell(this.column, this.row);

  final int column;
  final int row;

  bool get isInside => column >= 0 && column < 15 && row >= 0 && row < 15;

  @override
  bool operator ==(Object other) =>
      other is BoardCell && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

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

  static const double sourceWidth = 810;
  static const double sourceHeight = 1440;
  static const double canvasWidth = 576;
  static const double canvasHeight = 1024;

  // Convert measured source-artwork pixels to the app's uniform 9:16 canvas.
  // The artwork itself is never cropped, stretched, recoloured, or modified.
  static NormalizedBoardPoint _sourcePoint(double x, double y) =>
      NormalizedBoardPoint(x / sourceWidth, y / sourceHeight);

  static NormalizedBoardPoint canvasPosition(NormalizedBoardPoint point) =>
      NormalizedBoardPoint(
        point.x * canvasWidth,
        point.y * canvasHeight,
      );

  // Horizontal arm cell centres, measured from the 810×1440 source artwork.
  static const List<double> _leftArmX = <double>[
    48,
    96.5,
    144.5,
    192,
    240,
    287.5,
  ];
  static const List<double> _rightArmX = <double>[
    520.5,
    568,
    616,
    664,
    712,
    760,
  ];
  // The vertical arms are slightly wider than the horizontal arm cells and
  // the lower arm is offset by the artwork's central hub geometry.
  static const List<double> _topArmX = <double>[341, 404, 466.5];
  static const List<double> _bottomArmX = <double>[351, 403, 455];
  static const List<double> _topArmY = <double>[
    326,
    377.5,
    427.5,
    476.5,
    525,
    577,
  ];
  static const List<double> _bottomArmY = <double>[
    785.5,
    837.5,
    888,
    940,
    991.5,
    1045,
  ];
  static const List<double> _horizontalArmY = <double>[625, 677, 729];

  // Logical route order remains the domain contract. Each cell is rendered
  // through its measured source-artwork anchor instead of a false uniform
  // 15×15 transform.
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

  // Centres of the sixteen circular yard wells, measured independently from
  // the canonical source image. Small asymmetries in the artwork are retained.
  static const Map<PlayerColor, List<NormalizedBoardPoint>> _yardSockets = {
    PlayerColor.orange: <NormalizedBoardPoint>[
      NormalizedBoardPoint(114.2 / sourceWidth, 401.4 / sourceHeight),
      NormalizedBoardPoint(215 / sourceWidth, 402.6 / sourceHeight),
      NormalizedBoardPoint(115.4 / sourceWidth, 495 / sourceHeight),
      NormalizedBoardPoint(215 / sourceWidth, 497.4 / sourceHeight),
    ],
    PlayerColor.green: <NormalizedBoardPoint>[
      NormalizedBoardPoint(593 / sourceWidth, 402.6 / sourceHeight),
      NormalizedBoardPoint(692.6 / sourceWidth, 402.6 / sourceHeight),
      NormalizedBoardPoint(593 / sourceWidth, 496.2 / sourceHeight),
      NormalizedBoardPoint(692.6 / sourceWidth, 497.4 / sourceHeight),
    ],
    PlayerColor.blue: <NormalizedBoardPoint>[
      NormalizedBoardPoint(117.8 / sourceWidth, 872.2 / sourceHeight),
      NormalizedBoardPoint(217.4 / sourceWidth, 873.4 / sourceHeight),
      NormalizedBoardPoint(117.8 / sourceWidth, 968.2 / sourceHeight),
      NormalizedBoardPoint(217.4 / sourceWidth, 968.2 / sourceHeight),
    ],
    PlayerColor.magenta: <NormalizedBoardPoint>[
      NormalizedBoardPoint(594.2 / sourceWidth, 874.6 / sourceHeight),
      NormalizedBoardPoint(691.4 / sourceWidth, 873.4 / sourceHeight),
      NormalizedBoardPoint(593 / sourceWidth, 967 / sourceHeight),
      NormalizedBoardPoint(692.6 / sourceWidth, 967 / sourceHeight),
    ],
  };

  static NormalizedBoardPoint trackPosition(int index) {
    if (index < 0 || index >= trackLength) {
      throw RangeError.range(index, 0, trackLength - 1, 'index');
    }
    final cell = sharedTrack[index];
    final column = cell.column;
    final row = cell.row;

    if (row >= 6 && row <= 8 && column >= 0 && column <= 5) {
      return _sourcePoint(_leftArmX[column], _horizontalArmY[row - 6]);
    }
    if (row >= 6 && row <= 8 && column >= 9 && column <= 14) {
      return _sourcePoint(_rightArmX[column - 9], _horizontalArmY[row - 6]);
    }
    if (column >= 6 && column <= 8 && row >= 0 && row <= 5) {
      return _sourcePoint(_topArmX[column - 6], _topArmY[row]);
    }
    if (column >= 6 && column <= 8 && row >= 9 && row <= 14) {
      return _sourcePoint(_bottomArmX[column - 6], _bottomArmY[row - 9]);
    }
    throw StateError('No artwork anchor for shared track cell $cell.');
  }

  static NormalizedBoardPoint homeLanePosition(
    PlayerColor color,
    int laneIndex,
  ) {
    if (laneIndex < 0 || laneIndex >= homeLaneLength) {
      throw RangeError.range(laneIndex, 0, homeLaneLength - 1, 'laneIndex');
    }
    switch (color) {
      case PlayerColor.orange:
        return _sourcePoint(_leftArmX[laneIndex + 1], _horizontalArmY[1]);
      case PlayerColor.green:
        return _sourcePoint(_topArmX[1], _topArmY[laneIndex + 1]);
      case PlayerColor.magenta:
        return _sourcePoint(_rightArmX[4 - laneIndex], _horizontalArmY[1]);
      case PlayerColor.blue:
        return _sourcePoint(_bottomArmX[1], _bottomArmY[4 - laneIndex]);
    }
  }

  static NormalizedBoardPoint get finishPosition => _sourcePoint(403, 681);

  static NormalizedBoardPoint yardPosition(PlayerColor color, int pawnIndex) {
    if (pawnIndex < 0 || pawnIndex > 3) {
      throw RangeError.range(pawnIndex, 0, 3, 'pawnIndex');
    }
    return _yardSockets[color]![pawnIndex];
  }

  static NormalizedBoardPoint normalizedPosition(
    PlayerColor color,
    int progress,
    int pawnIndex,
  ) {
    if (pawnIndex < 0 || pawnIndex > 3) {
      throw RangeError.range(pawnIndex, 0, 3, 'pawnIndex');
    }
    if (progress == -1) return yardPosition(color, pawnIndex);
    if (progress < -1 || progress > 56) {
      throw RangeError.range(progress, -1, 56, 'progress');
    }
    if (progress == 56) return finishPosition;
    if (progress < playerTrackLength) {
      return trackPosition((seats[color]!.entryIndex + progress) % trackLength);
    }
    return homeLanePosition(color, progress - playerTrackLength);
  }

  static int physicalTrackCell(PlayerColor color, int progress) {
    if (progress < 0 || progress >= playerTrackLength) {
      throw RangeError.range(progress, 0, playerTrackLength - 1, 'progress');
    }
    return (seats[color]!.entryIndex + progress) % trackLength;
  }

  static bool get isStructurallyValid {
    if (sharedTrack.length != trackLength ||
        sharedTrack.toSet().length != trackLength ||
        !sharedTrack.every((cell) => cell.isInside) ||
        seats.length != PlayerColor.turnOrder.length ||
        !finishCell.isInside ||
        _yardSockets.length != PlayerColor.turnOrder.length) {
      return false;
    }

    final trackCells = sharedTrack.toSet();
    final allHomeLaneCells = <BoardCell>{};
    for (final color in PlayerColor.turnOrder) {
      final seat = seats[color];
      if (seat == null ||
          seat.entryIndex != color.entryIndex ||
          seat.homeLane.length != homeLaneLength ||
          _yardSockets[color]?.length != 4) {
        return false;
      }
      for (final cell in seat.homeLane) {
        if (!cell.isInside ||
            trackCells.contains(cell) ||
            cell == finishCell ||
            !allHomeLaneCells.add(cell)) {
          return false;
        }
      }
      for (final point in _yardSockets[color]!) {
        if (point.x < 0 || point.x > 1 || point.y < 0 || point.y > 1) {
          return false;
        }
      }
    }

    for (var index = 0; index < trackLength; index++) {
      final point = trackPosition(index);
      if (point.x < 0 || point.x > 1 || point.y < 0 || point.y > 1) {
        return false;
      }
    }

    return safeTrackCells.every(
          (index) => index >= 0 && index < trackLength,
        ) &&
        nonOrthogonalTransitions.toSet().length ==
            nonOrthogonalTransitions.length &&
        nonOrthogonalTransitions.toSet().containsAll(
          cornerConnectorIndexes,
        ) &&
        cornerConnectorIndexes.containsAll(nonOrthogonalTransitions);
  }

  static List<int> get nonOrthogonalTransitions {
    final result = <int>[];
    for (var index = 0; index < sharedTrack.length; index++) {
      final from = sharedTrack[index];
      final to = sharedTrack[(index + 1) % sharedTrack.length];
      final distance =
          (from.column - to.column).abs() + (from.row - to.row).abs();
      if (distance != 1) result.add(index);
    }
    return List<int>.unmodifiable(result);
  }

  // Source measurements and tests are committed; final visual approval is
  // still required before this gate can be closed.
  static const bool visualApprovalPending = true;
}
