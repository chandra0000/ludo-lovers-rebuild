import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_feedback.dart';
import 'package:ludo_lovers/src/features/match/match_screen.dart';
import 'package:ludo_lovers/src/game/domain/feedback_preferences.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/feedback_preferences_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'feedback respects independent controls and absorbs async platform failures',
      () async {
    final calls = <String>[];
    final feedback = MatchFeedback(
      sound: (type) async {
        calls.add('sound:$type');
        throw PlatformException(code: 'unsupported');
      },
      haptic: (important) async {
        calls.add('haptic:$important');
      },
    );
    await feedback.play(
      MatchFeedbackCue.finish,
      const FeedbackPreferences(sound: true),
    );
    expect(calls, ['sound:${SystemSoundType.alert}', 'haptic:true']);
    calls.clear();
    await feedback.play(
      MatchFeedbackCue.roll,
      const FeedbackPreferences(haptics: false),
    );
    expect(calls, isEmpty);
    await feedback.play(MatchFeedbackCue.land, const FeedbackPreferences());
    expect(calls, ['haptic:false']);
  });
  test('feedback settings persist and corrupt settings restore safe defaults',
      () async {
    const store = FeedbackPreferencesStore();
    await store.save(
      const FeedbackPreferences(
        sound: true,
        haptics: false,
        reduceMotion: true,
      ),
    );
    final restored = await store.load();
    expect(restored.sound, isTrue);
    expect(restored.haptics, isFalse);
    expect(restored.reduceMotion, isTrue);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(FeedbackPreferencesStore.storageKey, '{bad');
    expect((await store.load()).sound, isFalse);
    expect((await store.load()).haptics, isTrue);
  });
  testWidgets(
      'live game feedback controls persist and reduced motion preserves one roll',
      (tester) async {
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
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Game feedback'));
    await tester.pumpAndSettle();
    for (final key in ['game_sound', 'game_haptics', 'game_reduce_motion']) {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }
    final preferences = await const FeedbackPreferencesStore().load();
    expect(preferences.sound, isTrue);
    expect(preferences.haptics, isFalse);
    expect(preferences.reduceMotion, isTrue);
    Navigator.of(tester.element(find.byKey(const Key('game_sound')))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roll_dice')));
    await tester.pumpAndSettle();
    expect(rolls, 1);
    expect(find.byKey(const Key('accessible_pawn_chooser')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
