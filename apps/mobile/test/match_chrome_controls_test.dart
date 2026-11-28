import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'support/wait_for_board_artwork.dart';

void main() {
  Future<void> pumpMatch(WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 873);
    await tester.pumpWidget(const MaterialApp(home: MatchScreen()));
    await waitForBoardArtwork(tester);
    await tester.pump();
  }

  testWidgets('chat control opens local chat and emoji reactions', (
    tester,
  ) async {
    await pumpMatch(tester);

    await tester.tap(find.byKey(const Key('chat_button')));
    await tester.pump();

    expect(
      find.text('Match chat · On this device'),
      findsOneWidget,
    );
  });

  testWidgets('more artwork target exposes safe restart and exit actions', (
    tester,
  ) async {
    await pumpMatch(tester);

    await tester.tap(find.byKey(const Key('more_button')));
    await tester.pumpAndSettle();

    expect(find.text('Restart match'), findsOneWidget);
    expect(find.text('Exit match'), findsOneWidget);

    await tester.tap(find.text('Restart match'));
    await tester.pumpAndSettle();

    expect(find.text('Restart this match?'), findsOneWidget);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('turn_status')), findsOneWidget);
  });

  testWidgets('exit match retains a full-size accessible hit target', (
    tester,
  ) async {
    await pumpMatch(tester);

    final exitButton = tester.widget<IconButton>(
      find.byKey(const Key('exit_match')),
    );
    expect(exitButton.constraints?.minWidth, 48);
    expect(exitButton.constraints?.minHeight, 48);
  });
}
