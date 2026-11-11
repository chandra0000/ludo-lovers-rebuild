import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';

void main() {
  testWidgets('match uses independent board and interactive dice layers', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    expect(find.byKey(const Key('board_artwork')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byKey(const Key('animated_dice')), findsOneWidget);
    expect(find.byKey(const Key('chat_button')), findsOneWidget);
    expect(find.byKey(const Key('more_button')), findsOneWidget);
  });
}
