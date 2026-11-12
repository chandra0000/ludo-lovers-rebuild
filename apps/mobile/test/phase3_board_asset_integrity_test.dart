import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_board_artwork.dart';

void main() {
  testWidgets('Phase 3: canonical board and extracted crop remain bundled',
      (tester) async {
    for (final asset in <String>[
      'assets/images/board/ludo_board_glass.webp',
      MatchBoardArtwork.assetPath,
    ]) {
      final bytes = await rootBundle.load(asset);
      expect(bytes.lengthInBytes, greaterThan(0), reason: asset);
    }
  });

  testWidgets('Phase 3: board artwork renders without asset load errors',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 576,
            height: 1024,
            child: MatchBoardArtwork(),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(
      find.text('Approved board artwork could not be loaded.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
