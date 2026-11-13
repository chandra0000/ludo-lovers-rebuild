import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/local_match_chat_sheet.dart';

void main() {
  testWidgets('local chat sends messages and emoji reactions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocalMatchChatSheet(),
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('local_chat_input')),
      'Hello players',
    );
    await tester.tap(find.byKey(const Key('local_chat_send')));
    await tester.pump();
    expect(find.text('Hello players'), findsOneWidget);
    await tester.tap(find.byTooltip('React 👏'));
    await tester.pump();
    expect(find.text('👏'), findsWidgets);
  });

  testWidgets('emoji reaction notifies the live presentation locally', (
    tester,
  ) async {
    final reactions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocalMatchChatSheet(onReaction: reactions.add),
        ),
      ),
    );

    await tester.tap(find.byTooltip('React 🔥'));
    await tester.pump();
    expect(reactions, <String>['🔥']);
  });
}
