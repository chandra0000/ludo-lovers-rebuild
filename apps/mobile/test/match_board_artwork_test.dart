import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';

void main() {
  testWidgets('board artwork remains a dedicated immutable render layer', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 640,
            child: MatchBoardArtwork(),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
    final artwork = tester.widget<Image>(find.byKey(const Key('board_artwork')));
    expect(
      (artwork.image as AssetImage).assetName,
      MatchBoardArtwork.assetPath,
    );
    expect(
      MatchBoardArtwork.assetPath,
      'assets/images/board/extracted/board_exact.webp',
    );
  });
}
