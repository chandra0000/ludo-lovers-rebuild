import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';

/// Host deterministic roll-count comparison, not measured human match minutes.
void main() {
  const samples = 100;
  const cap = 10000;
  final results = <Map<String, Object>>[];
  for (final count in [2, 3, 4]) {
    for (final mode in [MatchMode.classic, MatchMode.quick]) {
      final lengths = <int>[];
      var capped = 0;
      for (var seed = 0; seed < samples; seed++) {
        var game =
            ModeRegistry.create(mode, playerCount: count, allowInternal: true);
        final random = Random(20261117 + seed);
        var rolls = 0;
        while (game.winner == null && rolls < cap) {
          game = game.roll(random.nextInt(6) + 1);
          rolls++;
          if (game.diceValue == null) continue;
          final pawn = const SeededLudoAi()
              .choosePawn(game, seed: seed ^ game.stateVersion);
          game = pawn == null ? game.passTurn() : game.movePawn(pawn);
        }
        if (game.winner == null) {
          capped++;
        } else {
          lengths.add(rolls);
        }
      }
      lengths.sort();
      int percentile(double p) => lengths[((lengths.length - 1) * p).round()];
      results.add({
        'mode': mode.name,
        'players': count,
        'completed': lengths.length,
        'capped': capped,
        'medianRolls': lengths.isEmpty ? 0 : percentile(.5),
        'p95Rolls': lengths.isEmpty ? 0 : percentile(.95),
        'completedRollCounts': lengths,
      });
    }
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'method': 'deterministic-medium-ai-roll-counts',
      'seedBase': 20261117,
      'samplesPerConfiguration': samples,
      'maxRollsPerMatch': cap,
      'runtime': Platform.version,
      'physicalDevice': false,
      'note':
          'Roll counts measure deterministic simulated match length; no human duration or renderer speed claim.',
      'results': results,
    }),
  );
}
