import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  for (final viewport in const [
    Size(360, 800),
    Size(393, 873),
    Size(430, 932),
    Size(320, 640),
  ]) {
    testWidgets(
      'match presents board, seats, dice, chat and reactions at $viewport',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;

        await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
        await tester.pump();

        expect(find.byKey(const Key('match_canvas')), findsOneWidget);
        expect(find.byKey(const Key('board_artwork')), findsOneWidget);
        expect(find.byKey(const Key('profile_orange')), findsOneWidget);
        expect(find.byKey(const Key('profile_green')), findsOneWidget);
        expect(find.byKey(const Key('profile_blue')), findsOneWidget);
        expect(find.byKey(const Key('profile_magenta')), findsOneWidget);
        expect(find.byKey(const Key('chat_button')), findsOneWidget);
        expect(find.byKey(const Key('quick_reactions_button')), findsOneWidget);
        expect(find.byKey(const Key('turn_status')), findsOneWidget);
        expect(find.byKey(const Key('exit_match')), findsOneWidget);
        expect(find.byKey(const Key('more_button')), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final key in const [
          Key('chat_button'),
          Key('quick_reactions_button'),
          Key('more_button'),
        ]) {
          final target = tester.getSize(find.byKey(key));
          expect(target.width, greaterThanOrEqualTo(48));
          expect(target.height, greaterThanOrEqualTo(48));
        }

        final canvas = tester.getRect(find.byKey(const Key('match_canvas')));
        expect(canvas.width, lessThanOrEqualTo(viewport.width + .01));
        expect(canvas.height, lessThanOrEqualTo(viewport.height + .01));
        expect(canvas.left, greaterThanOrEqualTo(-.01));
        expect(canvas.top, greaterThanOrEqualTo(-.01));
        final board = tester.getRect(find.byKey(const Key('board_artwork')));
        expect(board.left, greaterThanOrEqualTo(-.01));
        expect(board.right, lessThanOrEqualTo(viewport.width + .01));
        expect(board.top, greaterThanOrEqualTo(-.01));
        expect(board.bottom, lessThanOrEqualTo(viewport.height + .01));
      },
    );
  }
}
