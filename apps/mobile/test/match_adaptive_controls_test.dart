import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in const [
    Size(320, 640),
    Size(360, 800),
    Size(393, 873),
    Size(430, 932),
  ]) {
    testWidgets('profiles and status fit at 150 percent text on $size',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const MatchScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final color in const ['orange', 'green', 'magenta', 'blue']) {
        final avatar = tester.getRect(find.byKey(Key('profile_avatar_$color')));
        expect(avatar.width, greaterThanOrEqualTo(31.99));
        expect(avatar.width, closeTo(avatar.height, .01));
      }
      final header = tester.getRect(find.byKey(const Key('match_top_rail')));
      final instruction = tester.getRect(find.textContaining('Roll dice'));
      expect(header.contains(instruction.center), isTrue);
      expect(
        tester.getRect(find.byKey(const Key('exit_match'))).width,
        greaterThanOrEqualTo(48),
      );
    });
  }

  testWidgets('equivalent yard pawns deploy once without opening a sheet',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MatchScreen(
          rollDice: () {
            rolls++;
            return 6;
          },
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accessible_pawn_chooser')), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    final game = (await const SavedMatchStore().load())!.game;
    expect(game.stateVersion, 2);
    expect(game.players.first.pawnProgress[0], 0);
    expect(rolls, 1);

    expect(tester.takeException(), isNull);
  });
}
