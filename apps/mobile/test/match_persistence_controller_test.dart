import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/features/match/match_persistence_controller.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match_store.dart';

void main() {
  SavedMatch snapshot(int seed) => SavedMatch(
        game: LudoGame.initial(),
        aiPlayers: const {},
        aiSeed: seed,
      );

  test('writes snapshots in order even if the first write is slow', () async {
    final firstWrite = Completer<void>();
    final started = Completer<void>();
    final written = <int>[];
    final controller = MatchPersistenceController(save: (match) async {
      if (match.aiSeed == 1) {
        started.complete();
        await firstWrite.future;
      }
      written.add(match.aiSeed);
    });
    final first = controller.persist(snapshot(1));
    final second = controller.persist(snapshot(2));
    await started.future;
    expect(written, isEmpty);
    firstWrite.complete();
    await Future.wait([first, second]);
    expect(written, [1, 2]);
  });

  test('failed save does not block a later snapshot', () async {
    final written = <int>[];
    final controller = MatchPersistenceController(save: (match) async {
      if (match.aiSeed == 1) throw StateError('temporary failure');
      written.add(match.aiSeed);
    });
    await controller.persist(snapshot(1));
    await controller.persist(snapshot(2));
    expect(written, [2]);
  });
}
