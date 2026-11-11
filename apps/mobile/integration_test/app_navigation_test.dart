import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ludo_lovers/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home to local match navigation survives repeated exits', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed_v1': true,
    });

    await tester.pumpWidget(const LudoLoversApp());
    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open_game_setup')), findsOneWidget);

    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.tap(find.byKey(const Key('open_game_setup')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('start_local_match')), findsOneWidget);

      await tester.tap(find.byKey(const Key('start_local_match')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('board_artwork')), findsOneWidget);
      expect(find.byKey(const Key('roll_dice')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const Key('exit_match')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open_game_setup')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
