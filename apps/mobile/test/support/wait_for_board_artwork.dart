import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_assets.dart';

/// Wait for the real decoder before interacting with a visible pawn.
Future<void> waitForBoardArtwork(WidgetTester tester) async {
  final board = find.byKey(const Key('board_artwork'));
  final context = tester.element(board);
  final image = tester.widget<Image>(
    find.ancestor(of: board, matching: find.byType(Image)),
  );
  final errors = <Object>[];
  await tester.runAsync(
    () => Future.wait([
      for (final provider in [image.image, MatchAssets.logo])
        precacheImage(
          provider,
          context,
          onError: (error, stack) => errors.add(error),
        ),
    ]).timeout(const Duration(seconds: 10)),
  );
  expect(errors, isEmpty);
  // Advance only the frames actually needed to publish decode/readiness.
  // Avoid three expensive live GPU frames on every already-warm route entry.
  for (var frame = 0; frame < 3; frame++) {
    if (find.byKey(const Key('match_preparation_view')).evaluate().isEmpty &&
        find.text('Preparing board').evaluate().isEmpty &&
        find.text('Preparing the board…').evaluate().isEmpty) {
      break;
    }
    await tester.pump();
  }
  expect(find.byKey(const Key('match_preparation_view')), findsNothing);
  expect(find.text('Preparing board'), findsNothing);
  expect(find.text('Preparing the board…'), findsNothing);
}
