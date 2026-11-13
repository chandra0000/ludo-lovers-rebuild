import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  testWidgets('board frame is visible without changing the board position', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);

    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await tester.pump();

    expect(find.byKey(const Key('match_board_focus_frame')), findsOneWidget);
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('turn_status')), findsOneWidget);

    final board = tester.getRect(find.byKey(const Key('board_artwork')));
    final frame = tester.getRect(
      find.byKey(const Key('match_board_focus_frame')),
    );
    expect(frame.left, lessThan(board.left));
    expect(frame.top, lessThan(board.top));
    expect(frame.right, greaterThan(board.right));
    expect(frame.bottom, greaterThan(board.bottom));
  });
}
