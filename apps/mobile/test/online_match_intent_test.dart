import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_lovers/src/game/application/match_session.dart';
import 'package:ludo_lovers/src/game/application/online_match_intent.dart';

void main() {
  final roll = <String, dynamic>{
    'protocolVersion': 1,
    'matchId': 'room-match',
    'commandId': 'request-1',
    'expectedVersion': 12,
    'action': 'requestRoll',
    'payload': <String, dynamic>{},
  };

  test('maps a roll to a versioned command with server-owned inputs', () {
    final command = decodeOnlineMatchIntent(
      roll,
      memberActorId: 'seat-A',
      rollDie: () => 5,
    ) as RollDiceCommand;
    expect(command.value, 5);
    expect(command.actorId, 'seat-A');
    expect(command.expectedStateVersion, 12);
    expect(command.commandId, 'request-1');
    expect(command.matchId, 'room-match');
  });

  test('pawn choice preserves the index without drawing a die', () {
    final command = decodeOnlineMatchIntent(
      {
        ...roll,
        'action': 'selectPawn',
        'payload': {'pawnIndex': 3},
      },
      memberActorId: 'seat-B',
      rollDie: () => throw StateError('unexpected draw'),
    ) as MovePawnCommand;
    expect(command.pawnIndex, 3);
    expect(command.actorId, 'seat-B');
  });

  test('rejects unauthorised fields and malformed requests before drawing', () {
    for (final patch in [
      {'actorId': 'seat-B'},
      {'protocolVersion': 1.0},
      {'expectedVersion': -1},
      {'action': 'passTurn'},
      {
        'payload': {'value': 6},
      },
      {
        'action': 'selectPawn',
        'payload': {'pawnIndex': 4},
      },
    ]) {
      expect(
        () => decodeOnlineMatchIntent(
          {...roll, ...patch},
          memberActorId: 'seat-A',
          rollDie: () => throw StateError('unexpected draw'),
        ),
        throwsFormatException,
      );
    }
  });
}
