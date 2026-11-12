import 'package:flutter/widgets.dart';

/// Visual coordinates of the approved full-screen 810x1440 reference artwork.
///
/// These rectangles are presentation anchors, not board rules. The pure game
/// engine's 52-cell route, safe squares and command boundary remain unchanged.
class ApprovedArtworkGeometry {
  const ApprovedArtworkGeometry._();

  static const double sourceWidth = 810;
  static const double sourceHeight = 1440;
  static const double canvasWidth = 576;
  static const double canvasHeight = 1024;
  static const double nominalBoardLeft = 17;
  static const double nominalBoardTop = 205;
  static const double nominalBoardSize = 542;
  static const int boardGridSize = 15;

  static const String referenceAsset =
      'assets/images/board/ludo_board_glass.webp';

  static const Rect referenceCanvas = Rect.fromLTWH(
    0,
    0,
    canvasWidth,
    canvasHeight,
  );

  /// Nominal board bounds supplied with the approved design. The actual
  /// route/yard centres remain the measured anchors in BoardGeometry.
  static const Rect nominalBoardRect = Rect.fromLTWH(
    nominalBoardLeft,
    nominalBoardTop,
    nominalBoardSize,
    nominalBoardSize,
  );

  /// The visual die and label positions are measured from the reference.
  static const Rect diceRect = Rect.fromLTWH(243, 795, 90, 90);
  static const Rect turnStatusRect = Rect.fromLTWH(183, 929, 210, 54);
  static const Rect chatTouchRect = Rect.fromLTWH(13, 930, 90, 85);
  static const Rect moreTouchRect = Rect.fromLTWH(473, 930, 90, 85);

  static const Rect orangeLabel = Rect.fromLTWH(14, 153, 145, 50);
  static const Rect greenLabel = Rect.fromLTWH(417, 153, 145, 50);
  static const Rect blueLabel = Rect.fromLTWH(14, 873, 145, 50);
  static const Rect magentaLabel = Rect.fromLTWH(417, 873, 145, 50);

  static Offset sourceToCanvas(Offset source) => Offset(
        source.dx * canvasWidth / sourceWidth,
        source.dy * canvasHeight / sourceHeight,
      );

  static Rect sourceRectToCanvas(Rect source) => Rect.fromLTWH(
        source.left * canvasWidth / sourceWidth,
        source.top * canvasHeight / sourceHeight,
        source.width * canvasWidth / sourceWidth,
        source.height * canvasHeight / sourceHeight,
      );

  static Offset nominalCellCenter(int column, int row) {
    if (column < 0 ||
        column >= boardGridSize ||
        row < 0 ||
        row >= boardGridSize) {
      throw RangeError('Artwork cell must be within the 15x15 board.');
    }
    const pitch = nominalBoardSize / boardGridSize;
    return Offset(
      nominalBoardLeft + (column + 0.5) * pitch,
      nominalBoardTop + (row + 0.5) * pitch,
    );
  }

  /// Used in golden tests: the viewport must scale the *whole* reference
  /// uniformly rather than stretching the board to fill tall phones.
  static double uniformScale(Size safeViewport) {
    if (safeViewport.width <= 0 || safeViewport.height <= 0) {
      throw ArgumentError.value(safeViewport, 'safeViewport');
    }
    final widthScale = safeViewport.width / canvasWidth;
    final heightScale = safeViewport.height / canvasHeight;
    return widthScale < heightScale ? widthScale : heightScale;
  }

  static Offset centeredOrigin(Size safeViewport) {
    final scale = uniformScale(safeViewport);
    return Offset(
      (safeViewport.width - canvasWidth * scale) / 2,
      (safeViewport.height - canvasHeight * scale) / 2,
    );
  }
}
