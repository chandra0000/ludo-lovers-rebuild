import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

/// Displays a source-exact crop of the approved Ludo board using Flame.
/// No redrawing, procedural cells, altered stars, or AI-generated board.
///
/// Source reference: 864x1536 approved upload; repository artwork is 810x1440.
/// Both have the same 9:16 aspect ratio. The crop rectangle is normalized to
/// the source image dimensions to avoid mixing the two pixel grids.
class ApprovedBoardFlameGame extends FlameGame {
  ApprovedBoardFlameGame();

  static const sourceReferenceWidth = 864.0;
  static const sourceReferenceHeight = 1536.0;
  static const cropLeft = 15.0;
  static const cropTop = 307.0;
  static const cropRight = 850.0;
  static const cropBottom = 1158.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final image = await images.load('board/ludo_board_glass.webp');
    final sourceWidth = image.width.toDouble();
    final sourceHeight = image.height.toDouble();
    final crop = Sprite(
      image,
      srcPosition: Vector2(
        cropLeft / sourceReferenceWidth * sourceWidth,
        cropTop / sourceReferenceHeight * sourceHeight,
      ),
      srcSize: Vector2(
        (cropRight - cropLeft) / sourceReferenceWidth * sourceWidth,
        (cropBottom - cropTop) / sourceReferenceHeight * sourceHeight,
      ),
    );
    await add(
      SpriteComponent(
        sprite: crop,
        size: size,
        position: Vector2.zero(),
      ),
    );
  }
}

class ApprovedBoardFlameView extends StatefulWidget {
  const ApprovedBoardFlameView({super.key});

  @override
  State<ApprovedBoardFlameView> createState() => _ApprovedBoardFlameViewState();
}

class _ApprovedBoardFlameViewState extends State<ApprovedBoardFlameView> {
  late final ApprovedBoardFlameGame _game = ApprovedBoardFlameGame();

  @override
  Widget build(BuildContext context) {
    return GameWidget(game: _game);
  }
}
