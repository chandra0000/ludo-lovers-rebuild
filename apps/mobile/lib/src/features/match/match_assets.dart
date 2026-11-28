import 'package:flutter/painting.dart';
import 'match_board_artwork.dart';

/// Exact providers shared by preparation and the live composition.
abstract final class MatchAssets {
  static const board = AssetImage(MatchBoardArtwork.assetPath);
  static const logo = ResizeImage(
    AssetImage('assets/images/branding/ludo_lovers_icon.webp'),
    width: 216,
  );
}
