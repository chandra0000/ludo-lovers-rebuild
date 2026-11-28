import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/mode_registry.dart';
import 'package:ludo_lovers/src/game/domain/persistence/saved_match.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

({String snapshot, int rolls, int restores, int probes}) simulate(
  MatchMode mode,
  int count,
  LudoAiDifficulty difficulty,
  int seed,
  int cap,
) {
  final matchId = '${mode.name}-$count-${difficulty.name}-$seed';
  var session = MatchSession.local(
    matchId: matchId,
    game: ModeRegistry.create(mode, playerCount: count),
  );
  final random = Random(seed);
  var rolls = 0;
  var restores = 0;
  var probes = 0;
  while (session.game.winner == null &&
      (rolls < cap || session.game.diceValue != null)) {
    final before = session.game;
    final actor = session.actorFor(before.activePlayer);
    final id = 'command-${before.stateVersion}';
    final choice = before.diceValue == null
        ? null
        : const SeededLudoAi().choosePawn(
            before,
            seed: seed ^ before.stateVersion,
            difficulty: difficulty,
          );
    final MatchCommand command;
    if (before.diceValue == null) {
      rolls++;
      command = RollDiceCommand(
        matchId: matchId,
        actorId: actor,
        expectedStateVersion: before.stateVersion,
        commandId: id,
        value: random.nextInt(6) + 1,
      );
    } else if (choice == null) {
      require(before.legalPawnIndices().isEmpty, 'AI omitted a legal move');
      command = PassTurnCommand(
        matchId: matchId,
        actorId: actor,
        expectedStateVersion: before.stateVersion,
        commandId: id,
      );
    } else {
      require(
        before.legalPawnIndices().contains(choice),
        'AI chose illegal pawn',
      );
      command = MovePawnCommand(
        matchId: matchId,
        actorId: actor,
        expectedStateVersion: before.stateVersion,
        commandId: id,
        pawnIndex: choice,
      );
    }
    final result = session.execute(command);
    require(
        result.accepted,
        'Legal simulation command rejected: '
        '${result.rejectionReason}');
    session = result.session;
    final game = session.game;
    require(
      game.stateVersion == before.stateVersion + 1,
      'Version discontinuity',
    );
    require(
      game.appliedCommandIds.length == game.stateVersion,
      'Command receipt count mismatch',
    );
    require(
      game.configuration.activePlayers.contains(game.activePlayer),
      'Inactive turn recipient',
    );
    require(game.players.length == count, 'Roster changed');
    for (final player in game.players) {
      require(player.pawnProgress.length == 4, 'Pawn count changed');
      require(
        player.pawnProgress.every((p) => p >= -1 && p <= 56),
        'Pawn outside authoritative progress range',
      );
    }
    var eventSequence = 0;
    for (final event in result.events) {
      require(
        event.stateVersion == game.stateVersion,
        'Event version mismatch',
      );
      require(event.sequence == eventSequence++, 'Event order discontinuity');
    }
    if (game.stateVersion % 100 == 0) {
      final duplicate = session.execute(command);
      require(
        !duplicate.accepted &&
            duplicate.rejectionReason ==
                MatchCommandRejectionReason.duplicateCommand,
        'Duplicate command accepted',
      );
      final stale = session.execute(
        RollDiceCommand(
          matchId: matchId,
          actorId: session.actorFor(game.activePlayer),
          expectedStateVersion: game.stateVersion - 1,
          commandId: 'stale-${game.stateVersion}',
          value: 1,
        ),
      );
      require(
        !stale.accepted &&
            stale.rejectionReason == MatchCommandRejectionReason.staleState,
        'Stale command accepted',
      );
      require(
        identical(stale.session, session),
        'Rejected command mutated state',
      );
      probes += 2;
      final restored = SavedMatch.decode(
        SavedMatch(
          game: game,
          aiPlayers: game.configuration.activePlayers.toSet(),
          aiSeed: seed,
          aiDifficulty: difficulty,
        ).encode(),
      );
      require(
        restored.game.encodeSnapshot() == game.encodeSnapshot(),
        'Saved snapshot changed during restoration',
      );
      session = MatchSession.local(matchId: matchId, game: restored.game);
      restores++;
    }
  }
  require(session.game.winner != null, 'Match reached cap without victory');
  return (
    snapshot: session.game.encodeSnapshot(),
    rolls: rolls,
    restores: restores,
    probes: probes
  );
}

void main(List<String> args) {
  String option(String name, String fallback) => args
      .firstWhere(
        (a) => a.startsWith('--$name='),
        orElse: () => '--$name=$fallback',
      )
      .split('=')
      .skip(1)
      .join('=');
  final samples = int.parse(option('samples', '100'));
  final seedBase = int.parse(option('seed-base', '20261128'));
  final cap = int.parse(option('max-rolls', '10000'));
  final output =
      File(option('output', 'test-artifacts/production-simulation.json'));
  require(
    samples > 0 && samples <= 1000 && cap > 0,
    'Invalid simulation bounds',
  );
  final results = <Map<String, Object>>[];
  var completed = 0;
  var replayed = 0;
  var attempted = 0;
  final report = <String, Object?>{
    'sourceCommit':
        Process.runSync('git', ['rev-parse', 'HEAD']).stdout.toString().trim(),
    'applicationLibTree':
        Process.runSync('git', ['rev-parse', 'HEAD:apps/mobile/lib'])
            .stdout
            .toString()
            .trim(),
    'runnerBlob': Process.runSync(
      'git',
      ['hash-object', 'tool/production_gameplay_simulation.dart'],
    ).stdout.toString().trim(),
    'hostOs': Platform.operatingSystem,
    'counterScope':
        'Restoration/rejection counts cover primary matches; replays are counted separately.',
    'schemaVersion': 1,
    'status': 'running',
    'runtime': Platform.version,
    'seedBase': seedBase,
    'samplesPerConfiguration': samples,
    'maxRollsPerMatch': cap,
    'physicalDevice': false,
    'method':
        'MatchSession seeded legal AI commands with snapshot recovery and rejection probes',
    'results': results,
  };
  try {
    for (final mode in MatchMode.values) {
      for (final count in ModeRegistry.definition(mode).playerCounts) {
        for (final difficulty in LudoAiDifficulty.values) {
          final lengths = <int>[];
          var restores = 0;
          var probes = 0;
          for (var sample = 0; sample < samples; sample++) {
            final seed = seedBase + sample;
            report['currentCase'] =
                '${mode.name}/$count/${difficulty.name}/$seed';
            attempted++;
            final result = simulate(mode, count, difficulty, seed, cap);
            lengths.add(result.rolls);
            restores += result.restores;
            probes += result.probes;
            completed++;
            if (sample == 0) {
              attempted++;
              final replay = simulate(mode, count, difficulty, seed, cap);
              require(
                replay.snapshot == result.snapshot &&
                    replay.rolls == result.rolls,
                'Seed replay differs',
              );
              replayed++;
            }
          }
          lengths.sort();
          results.add({
            'mode': mode.name,
            'players': count,
            'difficulty': difficulty.name,
            'seedFirst': seedBase,
            'seedLast': seedBase + samples - 1,
            'completed': lengths.length,
            'medianRolls': lengths[lengths.length ~/ 2],
            'p95Rolls': lengths[((lengths.length - 1) * .95).round()],
            'snapshotRestorations': restores,
            'rejectedCommandProbes': probes,
          });
          stdout.writeln('Completed ${report['currentCase']}');
        }
      }
    }
    report['status'] = 'passed';
  } catch (error, stack) {
    report['status'] = 'failed';
    report['failure'] = error.toString();
    stderr.writeln('$error\n$stack');
    exitCode = 1;
  } finally {
    report['completedMatches'] = completed;
    report['replayedMatches'] = replayed;
    report['totalExecutedMatches'] = attempted;
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(report)}\n',
    );
    stdout.writeln(
      '${report['status']}: $completed matches, $replayed replays; ${output.path}',
    );
  }
}
