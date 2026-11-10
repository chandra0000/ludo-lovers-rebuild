import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/app.dart';

void main() {
  testWidgets('renders the home screen on the first frame', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.byKey(const Key('brand_logo')), findsOneWidget);
    expect(find.byKey(const Key('start_local_match')), findsOneWidget);
  });

  testWidgets('opens a local match from the home screen', (tester) async {
    await tester.pumpWidget(const LudoLoversApp());
    await tester.tap(find.byKey(const Key('start_local_match')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('turn_status')), findsOneWidget);
    expect(find.byKey(const Key('roll_dice')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_green_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
    expect(find.byKey(const Key('pawn_blue_0')), findsOneWidget);
  });
  
  testWidgets('plays a deterministic release and turn-change sequence', (tester) async {
    final rolls = <int>[6, 2];
    var rollIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(rollDice: () => rolls[rollIndex++]),
      ),
    );

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump();
    expect(find.text('6'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('ORANGE · YOUR TURN'), findsOneWidget);

    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pawn_orange_0')));
    await tester.pumpAndSettle();
    expect(find.text('GREEN · YOUR TURN'), findsOneWidget);
  });
}

