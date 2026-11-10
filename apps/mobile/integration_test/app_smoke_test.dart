import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches and survives repeated local-match navigation', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await tester.pumpWidget(const LudoLoversApp());
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pumpAndSettle();
    expect(find.text('WELCOME TO LUDO LOVERS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip_onboarding')));
    await tester.pumpAndSettle();

    expect(find.text('LUDO LOVERS'), findsOneWidget);
    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.tap(find.byKey(const Key('open_game_setup')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('start_local_match')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('match_canvas')), findsOneWidget);
      expect(find.byKey(const Key('roll_dice')), findsOneWidget);
      expect(find.byKey(const Key('pawn_orange_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_green_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_magenta_0')), findsOneWidget);
      expect(find.byKey(const Key('pawn_blue_0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('exit_match')));
      await tester.pumpAndSettle();

      expect(find.text('LUDO LOVERS'), findsOneWidget);
      expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
    }
  });
}
