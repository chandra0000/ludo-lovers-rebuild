import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/domain/ludo_game.dart';
import 'package:ludo_lovers/src/game/domain/board_geometry.dart';
import 'package:ludo_lovers/src/game/domain/match_configuration.dart';
import 'package:ludo_lovers/src/game/domain/player_color.dart';
import 'package:ludo_lovers/src/game/domain/team_up_policy.dart';
import 'package:ludo_lovers/src/game/domain/ai/seeded_ludo_ai.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';

void main() {
  const orange = PlayerColor.orange,
      green = PlayerColor.green,
      magenta = PlayerColor.magenta,
      blue = PlayerColor.blue;
  int at(PlayerColor c, int cell) =>
      (cell - BoardGeometry.seats[c]!.entryIndex + 52) % 52;
  LudoGame game({
    PlayerColor active = orange,
    PlayerColor? scheduled,
    Map<PlayerColor, List<int>> progress = const {},
    Map<int, TeamUpTeam> priority = const {},
  }) =>
      LudoGame.fromProgress(
        activePlayer: active,
        scheduledPlayer: scheduled,
        pawnProgress: progress,
        teamCapturePriority: priority,
        ruleProfile: LudoRuleProfile.teamUpV1,
        configuration: MatchConfiguration.local(MatchMode.teamUp),
      );
  List<int> pawn(int p) => [p, -1, -1, -1];
  List<int> positions(LudoGame g, PlayerColor c) =>
      g.players.singleWhere((p) => p.color == c).pawnProgress;

  test('fixed teams, four seats and four pawns per seat', () {
    final g = game();
    expect(g.players.map((p) => p.color), PlayerColor.turnOrder);
    expect(g.players.every((p) => p.pawnProgress.length == 4), isTrue);
    expect(TeamUpPolicy.teamFor(orange), TeamUpPolicy.teamFor(magenta));
    expect(TeamUpPolicy.teamFor(green), TeamUpPolicy.teamFor(blue));
    expect(TeamUpPolicy.teamFor(orange), isNot(TeamUpPolicy.teamFor(green)));
    expect(
      () => LudoGame.initial(
        ruleProfile: LudoRuleProfile.teamUpV1,
        configuration:
            MatchConfiguration.local(MatchMode.classic, playerCount: 2),
      ),
      throwsFormatException,
    );
  });
  test('scheduled turns alternate in authoritative order', () {
    var g = game();
    for (final color in [...PlayerColor.turnOrder, ...PlayerColor.turnOrder]) {
      expect(g.scheduledPlayer, color);
      expect(g.activePlayer, color);
      g = g.roll(2).passTurn();
    }
  });
  test('teammates share unsafe cells and are never capture targets', () {
    final g = game(progress: {orange: pawn(4), magenta: pawn(at(magenta, 5))})
        .roll(1)
        .movePawn(0);
    expect(positions(g, magenta).first, at(magenta, 5));
    expect(g.teamCapturePriority, isEmpty);
    expect(g.events.whereType<TeamPawnCaptured>(), isEmpty);
    expect(g.activePlayer, green);
  });
  for (final safe in [8, 13]) {
    test('safe cell $safe protects every opposing occupant', () {
      final g = game(
        progress: {
          orange: pawn(safe - 1),
          green: pawn(at(green, safe)),
          blue: pawn(at(blue, safe)),
        },
      ).roll(1).movePawn(0);
      expect(positions(g, green).first, at(green, safe));
      expect(positions(g, blue).first, at(blue, safe));
      expect(g.events.whereType<TeamPawnCaptured>(), isEmpty);
      expect(g.teamCapturePriority, isEmpty);
    });
  }
  test('unequal arrival records last-arriving team without premature capture',
      () {
    final before = game(
      progress: {
        orange: pawn(4),
        green: pawn(at(green, 5)),
        blue: pawn(at(blue, 5)),
      },
    );
    final g = before.roll(1).movePawn(0);
    expect(g.teamCapturePriority, {5: TeamUpTeam.a});
    expect(g.events.whereType<TeamPawnCaptured>(), isEmpty);
    expect(g.events.whereType<TeamStackPriorityChanged>(), hasLength(1));
    expect(before.teamCapturePriority, isEmpty);
    expect(
      () => g.teamCapturePriority[5] = TeamUpTeam.b,
      throwsUnsupportedError,
    );
    expect(
      LudoGame.decodeSnapshot(g.encodeSnapshot()).encodeSnapshot(),
      g.encodeSnapshot(),
    );
  });
  test('protected departure loses remaining friends but grants no loss bonus',
      () {
    final g = game(
      active: green,
      progress: {
        orange: pawn(5),
        green: pawn(at(green, 5)),
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.a,
      },
    ).roll(1).movePawn(0);
    expect(positions(g, green).first, at(green, 6));
    expect(positions(g, blue).first, -1);
    final capture = g.events.whereType<TeamPawnCaptured>().single;
    expect(capture.byTeam, TeamUpTeam.a);
    expect(capture.victim, blue);
    expect(capture.cause, TeamCaptureCause.protectedDeparture);
    expect(g.events.whereType<ExtraTurnGranted>(), isEmpty);
    expect(g.activePlayer, magenta);
    expect(g.teamCapturePriority, isEmpty);
  });
  test(
      'last priority pawn departure protects earlier occupants and clears priority',
      () {
    final g = game(
      progress: {
        orange: pawn(5),
        green: pawn(at(green, 5)),
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.a,
      },
    ).roll(1).movePawn(0);
    expect(g.events.whereType<TeamPawnCaptured>(), isEmpty);
    expect(g.teamCapturePriority, isEmpty);
    expect(positions(g, green).first, at(green, 5));
    expect(positions(g, blue).first, at(blue, 5));
  });
  test('partial priority departure retains priority while that team remains',
      () {
    final g = game(
      progress: {
        orange: [5, 5, -1, -1],
        magenta: pawn(at(magenta, 5)),
        green: pawn(at(green, 5)),
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.a,
      },
    ).roll(1).movePawn(0);
    expect(g.teamCapturePriority, {5: TeamUpTeam.a});
    expect(g.events.whereType<TeamPawnCaptured>(), isEmpty);
    // Equal sizes after departure do not trigger the arrival-only resolution.
    expect(
      LudoGame.decodeSnapshot(g.encodeSnapshot()).teamCapturePriority,
      {5: TeamUpTeam.a},
    );
  });
  test('equal opposing arrival captures every opposing pawn by team', () {
    final g = game(
      progress: {
        orange: pawn(4),
        magenta: pawn(at(magenta, 5)),
        green: pawn(at(green, 5)),
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.b,
      },
    ).roll(1).movePawn(0);
    expect(positions(g, green).first, -1);
    expect(positions(g, blue).first, -1);
    expect(positions(g, magenta).first, at(magenta, 5));
    expect(g.events.whereType<TeamPawnCaptured>(), hasLength(2));
    expect(g.teamCapturePriority, isEmpty);
    expect(g.events.whereType<ExtraTurnGranted>().single.player, orange);
  });
  test(
      'protected stack of more than two occupants resolves all remaining pawns',
      () {
    final g = game(
      active: green,
      progress: {
        orange: pawn(5),
        green: [at(green, 5), at(green, 5), -1, -1],
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.a,
      },
    ).roll(1).movePawn(0);
    expect(g.events.whereType<TeamPawnCaptured>(), hasLength(2));
    expect(positions(g, green)[0], at(green, 6));
    expect(positions(g, green)[1], -1);
    expect(positions(g, blue)[0], -1);
    expect(g.events.whereType<ExtraTurnGranted>(), isEmpty);
  });
  test(
      'finished scheduled seat transfers to teammate and preserves its six bonus',
      () {
    var g = game(
      progress: {
        orange: [56, 56, 56, 56],
      },
    );
    expect(g.activePlayer, magenta);
    expect(g.scheduledPlayer, orange);
    g = g.roll(6).movePawn(0);
    expect(g.activePlayer, magenta);
    expect(g.scheduledPlayer, orange);
    expect(g.events.whereType<ExtraTurnGranted>().single.player, magenta);
    g = g.roll(1).movePawn(0);
    expect(g.activePlayer, green);
    expect(g.scheduledPlayer, green);
  });
  test(
      'own fourth finish transfers eligible bonus without premature team victory',
      () {
    final g = game(
      progress: {
        orange: [56, 56, 56, 55],
      },
    ).roll(1).movePawn(3);
    expect(g.winner, isNull);
    expect(g.winningTeam, isNull);
    expect(g.activePlayer, magenta);
    expect(g.scheduledPlayer, orange);
    expect(g.events.whereType<ExtraTurnGranted>().single.player, magenta);
    final transfer = g.events.whereType<TeamTurnTransferred>().single;
    expect(transfer.bonus, isTrue);
    expect(transfer.recipient, magenta);
    expect(LudoGame.decodeSnapshot(g.encodeSnapshot()).activePlayer, magenta);
  });
  test(
      'consecutive-six penalty survives a bonus transfer and advances scheduled seat',
      () {
    var g = game(
      progress: {
        orange: [56, 56, 56, 50],
      },
    ).roll(6).movePawn(3);
    expect(g.activePlayer, magenta);
    expect(g.consecutiveSixes, 1);
    g = g.roll(6).movePawn(0);
    expect(g.consecutiveSixes, 2);
    g = g.roll(6);
    expect(g.diceValue, isNull);
    expect(g.activePlayer, green);
    expect(g.scheduledPlayer, green);
    expect(g.events.whereType<ConsecutiveSixPenalty>(), hasLength(1));
  });
  test('completed team scheduled seats are skipped by the scheduling policy',
      () {
    final next = TeamUpPolicy.nextTurn(blue, {orange, magenta});
    expect(next.scheduled, green);
    expect(next.active, green);
  });
  for (final team in TeamUpTeam.values) {
    test(
        '${team.name} wins only after all eight; final player and team survive restore',
        () {
      final first = team == TeamUpTeam.a ? orange : green;
      final last = TeamUpPolicy.teammate(first);
      final g = game(
        active: last,
        progress: {
          first: [56, 56, 56, 56],
          last: [56, 56, 56, 55],
        },
      ).roll(1).movePawn(3);
      expect(g.winner, last);
      expect(g.winningTeam, team);
      expect(g.events.whereType<TeamWon>().single.finalPlayer, last);
      expect(g.events.whereType<GameCompleted>(), hasLength(1));
      expect(g.events.whereType<ExtraTurnGranted>(), isEmpty);
      final restored = LudoGame.decodeSnapshot(g.encodeSnapshot());
      expect(restored.winner, last);
      expect(restored.winningTeam, team);
      expect(restored.encodeSnapshot(), g.encodeSnapshot());
    });
  }
  test(
      'priority-less mixed states and corrupt scheduled/outcome snapshots fail closed',
      () {
    expect(
      () => game(
        progress: {
          orange: pawn(5),
          green: pawn(at(green, 5)),
          blue: pawn(at(blue, 5)),
        },
      ),
      throwsFormatException,
    );
    final snapshot = game().toSnapshot();
    snapshot['teamState'] = {
      'scheduledPlayer': 'orange',
      'priorityByCell': {'8': 'a'},
      'winningTeam': null,
    };
    expect(() => LudoGame.fromSnapshot(snapshot), throwsFormatException);
    snapshot['teamState'] = {
      'scheduledPlayer': 'orange',
      'priorityByCell': {},
      'winningTeam': 'a',
    };
    expect(() => LudoGame.fromSnapshot(snapshot), throwsFormatException);
  });
  test('transferred actor commands preserve duplicate and stale rejection', () {
    var session = MatchSession.local(
      matchId: 'team',
      game: game(
        progress: {
          orange: [56, 56, 56, 56],
        },
      ),
    );
    final command = RollDiceCommand(
      matchId: 'team',
      actorId: session.actorFor(magenta),
      expectedStateVersion: 0,
      commandId: 'roll',
      value: 6,
    );
    final accepted = session.execute(command);
    expect(accepted.accepted, isTrue);
    session = accepted.session;
    expect(
      session.execute(command).rejectionReason,
      MatchCommandRejectionReason.duplicateCommand,
    );
    expect(
      session
          .execute(
            MovePawnCommand(
              matchId: 'team',
              actorId: session.actorFor(magenta),
              expectedStateVersion: 0,
              commandId: 'stale',
              pawnIndex: 0,
            ),
          )
          .rejectionReason,
      MatchCommandRejectionReason.staleState,
    );
  });
  test(
      'seeded full Team Up game completes with contiguous typed events and replayable snapshots',
      () {
    var g = game();
    final random = Random(20261117);
    for (var i = 0; i < 20000 && g.winner == null; i++) {
      g = g.roll(random.nextInt(6) + 1, commandId: 'r$i');
      if (g.diceValue == null) continue;
      final pawn = const SeededLudoAi().choosePawn(g, seed: i);
      g = pawn == null
          ? g.passTurn(commandId: 'p$i')
          : g.movePawn(pawn, commandId: 'm$i');
      expect(
        g.events.map((e) => e.sequence),
        List.generate(g.events.length, (j) => j),
      );
      expect(g.events.every((e) => e.stateVersion == g.stateVersion), isTrue);
      expect(
        LudoGame.decodeSnapshot(g.encodeSnapshot()).encodeSnapshot(),
        g.encodeSnapshot(),
      );
    }
    expect(g.winningTeam, isNotNull);
  });
  test('three-versus-three arrival captures the whole opposing team stack', () {
    final before = game(
      progress: {
        orange: [4, 5, -1, -1],
        magenta: pawn(at(magenta, 5)),
        green: [at(green, 5), at(green, 5), -1, -1],
        blue: pawn(at(blue, 5)),
      },
      priority: {
        5: TeamUpTeam.b,
      },
    );
    final evaluation = before.evaluatePawnMove(0, roll: 1) as ValidMove;
    expect(evaluation.isCapture, isTrue);
    final after = before.roll(1).movePawn(0);
    expect(after.events.whereType<TeamPawnCaptured>(), hasLength(3));
    expect(positions(after, green).take(2), [-1, -1]);
    expect(positions(after, blue).first, -1);
    expect(after.teamCapturePriority, isEmpty);
  });
}
