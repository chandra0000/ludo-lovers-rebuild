import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wait for the real decoder before interacting with a visible pawn.
Future<void> waitForBoardArtwork(WidgetTester tester) async {
  final board = find.byKey(const Key('board_artwork'));
  final context = tester.element(board);
  final image = tester.widget<Image>(
    find.ancestor(of: board, matching: find.byType(Image)),
  );
  final errors = <Object>[];
  await tester.runAsync(
    () => precacheImage(
      image.image,
      context,
      onError: (error, stack) => errors.add(error),
    ).timeout(const Duration(seconds: 10)),
  );
  expect(errors, isEmpty);
  await tester.pump();
  // Decode/frame publication, post-paint readiness, then the enabled HUD.
  await tester.pump();
  await tester.pump();
}
