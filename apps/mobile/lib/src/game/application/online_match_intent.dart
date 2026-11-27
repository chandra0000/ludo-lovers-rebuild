import 'match_session.dart';

/// Adapter for an authenticated room service. The caller resolves membership
/// and supplies the server die. Clients can request only a roll or pawn choice.
MatchCommand decodeOnlineMatchIntent(
  Object? message, {
  required String memberActorId,
  required int Function() rollDie,
}) {
  if (message is! Map<String, dynamic> ||
      message.length != 6 ||
      message['protocolVersion'] is! int ||
      message['protocolVersion'] != 1) {
    throw const FormatException('Invalid match envelope');
  }
  final matchId = message['matchId'];
  final commandId = message['commandId'];
  final version = message['expectedVersion'];
  final payload = message['payload'];
  if (matchId is! String ||
      matchId.trim().isEmpty ||
      commandId is! String ||
      commandId.trim().isEmpty ||
      version is! int ||
      version < 0 ||
      payload is! Map<String, dynamic>) {
    throw const FormatException('Invalid match intent');
  }

  switch (message['action']) {
    case 'requestRoll':
      if (payload.isEmpty) {
        return RollDiceCommand(
          matchId: matchId,
          actorId: memberActorId,
          expectedStateVersion: version,
          commandId: commandId,
          value: rollDie(),
        );
      }
    case 'selectPawn':
      final index = payload['pawnIndex'];
      if (payload.length == 1 && index is int && index >= 0 && index < 4) {
        return MovePawnCommand(
          matchId: matchId,
          actorId: memberActorId,
          expectedStateVersion: version,
          commandId: commandId,
          pawnIndex: index,
        );
      }
  }
  throw const FormatException('Unsupported match action or payload');
}
