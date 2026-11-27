import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ludo_lovers/src/features/match/match_persistence_controller.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';
import 'package:ludo_lovers/src/game/infrastructure/persistence/saved_match_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native false write is reported and the next save can recover',
      () async {
    var acceptsWrites = false;
    final durableValues = <String, Object>{};
    const channel = MethodChannel('plugins.flutter.io/shared_preferences');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getAll') return durableValues;
      if (call.method == 'setString') {
        if (acceptsWrites) {
          final args = call.arguments as Map;
          durableValues[args['key'] as String] = args['value'] as String;
        }
        return acceptsWrites;
      }
      throw StateError('Unexpected preferences operation: ${call.method}');
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    const store = SavedMatchStore();
    final saved =
        SavedMatch(game: LudoGame.initial(), aiPlayers: {}, aiSeed: 17);
    final controller = MatchPersistenceController(save: store.save);

    await controller.persist(saved);
    expect(
      controller.lastSaveSucceeded,
      isFalse,
      reason: 'A native false result must not be reported as durable success',
    );
    expect(durableValues, isEmpty);
    await (await SharedPreferences.getInstance()).reload();
    expect(await store.load(), isNull);

    acceptsWrites = true;
    await controller.persist(saved);
    expect(controller.lastSaveSucceeded, isTrue);
    await (await SharedPreferences.getInstance()).reload();
    expect((await store.load())?.aiSeed, 17);
  });
}
