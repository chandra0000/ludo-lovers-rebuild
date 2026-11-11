import 'dart:convert';
import 'dart:io';

import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';

void main(List<String> arguments) {
  final options = _parseOptions(arguments);
  final warmup = options['warmup']!;
  final samples = options['samples']!;
  final iterationsPerSample = options['iterations-per-sample']!;

  final initial = LudoGame.initial().roll(6);
  final movement = LudoGame.fromProgress(
    activePlayer: PlayerColor.orange,
    pawnProgress: {
      PlayerColor.orange: [3, 10, -1, -1],
    },
  ).roll(3);
  final capture = LudoGame.fromProgress(
    activePlayer: PlayerColor.orange,
    ruleProfile: LudoRuleProfile.classicV1,
    pawnProgress: {
      PlayerColor.orange: [3, -1, -1, -1],
      PlayerColor.green: [44, -1, -1, -1],
    },
  ).roll(2);
  final blockade = LudoGame.fromProgress(
    activePlayer: PlayerColor.orange,
    ruleProfile: LudoRuleProfile.classicV1,
    pawnProgress: {
      PlayerColor.orange: [3, -1, -1, -1],
      PlayerColor.green: [44, 44, -1, -1],
    },
  ).roll(4);
  final snapshot = movement.encodeSnapshot();
  const ai = SeededLudoAi();

  final cases = <({String name, void Function() operation})>[
    (name: 'initial_state_creation', operation: () => LudoGame.initial()),
    (name: 'legal_action_enumeration', operation: () => initial.legalPawnIndices()),
    (name: 'single_move_evaluation', operation: () => movement.evaluatePawnMove(0)),
    (name: 'blockade_path_evaluation', operation: () => blockade.evaluatePawnMove(0)),
    (name: 'transition_and_event_generation', operation: () => movement.movePawn(0)),
    (name: 'capture_transition_and_events', operation: () => capture.movePawn(0)),
    (name: 'snapshot_encode', operation: () => movement.encodeSnapshot()),
    (name: 'snapshot_decode', operation: () => LudoGame.decodeSnapshot(snapshot)),
    (name: 'seeded_ai_decision', operation: () => ai.choosePawn(movement, seed: 2026)),
  ];

  final results = <Map<String, Object?>>[];
  for (final benchmark in cases) {
    results.add(
      _measure(
        benchmark.name,
        benchmark.operation,
        warmup: warmup,
        samples: samples,
        iterationsPerSample: iterationsPerSample,
      ),
    );
  }

  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'benchmark': 'ludo_lovers_engine',
      'schemaVersion': 1,
      'timestampUtc': DateTime.now().toUtc().toIso8601String(),
      'environment': {
        'operatingSystem': Platform.operatingSystem,
        'operatingSystemVersion': Platform.operatingSystemVersion,
        'processorCount': Platform.numberOfProcessors,
        'runnerName': Platform.environment['RUNNER_NAME'] ?? 'local',
        'appCommit': Platform.environment['GITHUB_SHA'] ?? 'unknown',
        'runtime': Platform.version,
        'executionMode': 'dart-vm-jit',
        'warmupIterationsPerCase': warmup,
        'samplesPerCase': samples,
        'iterationsPerSample': iterationsPerSample,
        'profiles': {
          'compatibility':
              '${LudoRuleProfile.currentV1.id}@${LudoRuleProfile.currentV1.version}',
          'classic':
              '${LudoRuleProfile.classicV1.id}@${LudoRuleProfile.classicV1.version}',
        },
      },
      'results': results,
    }),
  );
}

Map<String, int> _parseOptions(List<String> arguments) {
  final values = <String, int>{
    'warmup': 1000,
    'samples': 30,
    'iterations-per-sample': 500,
  };
  for (final argument in arguments) {
    final separator = argument.indexOf('=');
    if (!argument.startsWith('--') || separator < 3) {
      throw FormatException('Expected --name=value, received "$argument".');
    }
    final name = argument.substring(2, separator);
    final value = int.tryParse(argument.substring(separator + 1));
    if (!values.containsKey(name) || value == null || value < 1) {
      throw FormatException('Invalid benchmark option "$argument".');
    }
    values[name] = value;
  }
  return values;
}

Map<String, Object?> _measure(
  String name,
  void Function() operation, {
  required int warmup,
  required int samples,
  required int iterationsPerSample,
}) {
  for (var index = 0; index < warmup; index++) {
    operation();
  }

  final microsPerOperation = <double>[];
  for (var sample = 0; sample < samples; sample++) {
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < iterationsPerSample; iteration++) {
      operation();
    }
    stopwatch.stop();
    microsPerOperation.add(
      stopwatch.elapsedMicroseconds / iterationsPerSample,
    );
  }
  microsPerOperation.sort();

  final middle = microsPerOperation.length ~/ 2;
  final median = microsPerOperation.length.isOdd
      ? microsPerOperation[middle]
      : (microsPerOperation[middle - 1] + microsPerOperation[middle]) / 2;
  final p95Index = (microsPerOperation.length * 0.95).ceil() - 1;

  return {
    'name': name,
    'unit': 'microseconds_per_operation',
    'median': double.parse(median.toStringAsFixed(3)),
    'p95': double.parse(microsPerOperation[p95Index].toStringAsFixed(3)),
    'samples': samples,
    'iterationsPerSample': iterationsPerSample,
  };
}
