import '../domain/ludo_game.dart';
import '../domain/player_color.dart';

/// Transport-independent commands accepted by a local or future remote match
/// session. Commands carry enough identity to reject stale and duplicate work.
sealed class MatchCommand {
  const MatchCommand({
    required this.matchId,
    required this.actorId,
    required this.expectedStateVersion,
    required this.commandId,
  });

  final String matchId;
  final String actorId;
  final int expectedStateVersion;
  final String commandId;
}

final class RollDiceCommand extends MatchCommand {
  const RollDiceCommand({
    required super.matchId,
    required super.actorId,
    required super.expectedStateVersion,
    required super.commandId,
    required this.value,
  });

  final int value;
}

final class MovePawnCommand extends MatchCommand {
  const MovePawnCommand({
    required super.matchId,
    required super.actorId,
    required super.expectedStateVersion,
    required super.commandId,
    required this.pawnIndex,
  });

  final int pawnIndex;
}

final class PassTurnCommand extends MatchCommand {
  const PassTurnCommand({
    required super.matchId,
    required super.actorId,
    required super.expectedStateVersion,
    required super.commandId,
  });
}

enum MatchCommandRejectionReason {
  wrongMatch,
  wrongActor,
  staleState,
  duplicateCommand,
  invalidCommand,
  gameFinished,
  rollAlreadyPending,
  noPendingRoll,
  invalidDice,
  illegalMove,
  passNotAllowed,
  invalidAction,
}

/// Immutable result of applying one command. Rejections retain the exact
/// original session and expose no partial state mutation.
class MatchCommandResult {
  const MatchCommandResult._({
    required this.session,
    required this.accepted,
    required this.events,
    this.rejectionReason,
    this.message,
    this.moveInvalidReason,
  });

  final MatchSession session;
  final bool accepted;
  final List<LudoGameEvent> events;
  final MatchCommandRejectionReason? rejectionReason;
  final String? message;
  final MoveInvalidReason? moveInvalidReason;
}

/// Application boundary around the authoritative immutable Ludo domain.
///
/// The UI, AI and any future network adapter submit commands here instead of
/// invoking game transitions directly. The session owns actor authorization,
/// match identity, optimistic concurrency and command idempotency.
class MatchSession {
  MatchSession._({
    required this.matchId,
    required this.game,
    required Map<PlayerColor, String> actorIds,
  }) : actorIds = Map<PlayerColor, String>.unmodifiable(actorIds);

  factory MatchSession({
    required String matchId,
    required LudoGame game,
    required Map<PlayerColor, String> actorIds,
  }) {
    if (matchId.trim().isEmpty) {
      throw ArgumentError.value(matchId, 'matchId', 'Must not be empty.');
    }
    if (actorIds.length != PlayerColor.turnOrder.length ||
        !PlayerColor.turnOrder.every(actorIds.containsKey)) {
      throw ArgumentError.value(
        actorIds,
        'actorIds',
        'Exactly one actor must be assigned to every player seat.',
      );
    }
    final values = actorIds.values.toList();
    if (values.any((id) => id.trim().isEmpty) ||
        values.toSet().length != values.length) {
      throw ArgumentError.value(
        actorIds,
        'actorIds',
        'Actor IDs must be non-empty and unique.',
      );
    }
    return MatchSession._(
      matchId: matchId,
      game: game,
      actorIds: actorIds,
    );
  }

  factory MatchSession.local({
    required String matchId,
    required LudoGame game,
  }) =>
      MatchSession(
        matchId: matchId,
        game: game,
        actorIds: {
          for (final color in PlayerColor.turnOrder)
            color: 'local-seat-${color.name}',
        },
      );

  final String matchId;
  final LudoGame game;
  final Map<PlayerColor, String> actorIds;

  String actorFor(PlayerColor player) => actorIds[player]!;

  MatchCommandResult execute(MatchCommand command) {
    MatchCommandResult reject(
      MatchCommandRejectionReason reason,
      String message, {
      MoveInvalidReason? moveInvalidReason,
    }) =>
        MatchCommandResult._(
          session: this,
          accepted: false,
          events: const [],
          rejectionReason: reason,
          message: message,
          moveInvalidReason: moveInvalidReason,
        );

    if (command.matchId != matchId) {
      return reject(
        MatchCommandRejectionReason.wrongMatch,
        'Command belongs to a different match.',
      );
    }
    if (command.commandId.trim().isEmpty) {
      return reject(
        MatchCommandRejectionReason.invalidCommand,
        'Command ID must not be empty.',
      );
    }
    if (game.appliedCommandIds.contains(command.commandId)) {
      return reject(
        MatchCommandRejectionReason.duplicateCommand,
        'Command has already been applied.',
      );
    }
    if (command.expectedStateVersion != game.stateVersion) {
      return reject(
        MatchCommandRejectionReason.staleState,
        'Command was created for an older game state.',
      );
    }
    if (command.actorId != actorFor(game.activePlayer)) {
      return reject(
        MatchCommandRejectionReason.wrongActor,
        'Only the active player may issue this command.',
      );
    }

    if (game.winner != null) {
      return reject(
        MatchCommandRejectionReason.gameFinished,
        'The match has already finished.',
      );
    }
    switch (command) {
      case RollDiceCommand(:final value):
        if (game.diceValue != null) {
          return reject(
            MatchCommandRejectionReason.rollAlreadyPending,
            'Resolve the current roll before rolling again.',
          );
        }
        if (value < 1 || value > 6) {
          return reject(
            MatchCommandRejectionReason.invalidDice,
            'Dice value must be between 1 and 6.',
          );
        }
        break;
      case MovePawnCommand(:final pawnIndex):
        if (game.diceValue == null) {
          return reject(
            MatchCommandRejectionReason.noPendingRoll,
            'Roll the dice before moving a pawn.',
          );
        }
        final evaluation = game.evaluatePawnMove(pawnIndex);
        if (evaluation case InvalidMove(:final reason)) {
          return reject(
            MatchCommandRejectionReason.illegalMove,
            'Pawn move rejected: ${reason.name}.',
            moveInvalidReason: reason,
          );
        }
        break;
      case PassTurnCommand():
        if (game.diceValue == null) {
          return reject(
            MatchCommandRejectionReason.noPendingRoll,
            'Roll the dice before passing.',
          );
        }
        if (!game.awaitingPass) {
          return reject(
            MatchCommandRejectionReason.passNotAllowed,
            'A legal pawn move is available.',
          );
        }
        break;
    }

    try {
      final nextGame = switch (command) {
        RollDiceCommand(:final value) => game.roll(
            value,
            expectedStateVersion: command.expectedStateVersion,
            commandId: command.commandId,
          ),
        MovePawnCommand(:final pawnIndex) => game.movePawn(
            pawnIndex,
            expectedStateVersion: command.expectedStateVersion,
            commandId: command.commandId,
          ),
        PassTurnCommand() => game.passTurn(
            expectedStateVersion: command.expectedStateVersion,
            commandId: command.commandId,
          ),
      };
      final nextSession = MatchSession._(
        matchId: matchId,
        game: nextGame,
        actorIds: actorIds,
      );
      return MatchCommandResult._(
        session: nextSession,
        accepted: true,
        events: nextGame.events,
      );
    } on ArgumentError catch (error) {
      return reject(
          MatchCommandRejectionReason.invalidAction, error.message.toString());
    } on StateError catch (error) {
      return reject(MatchCommandRejectionReason.invalidAction, error.message);
    }
  }

  /// Replays a previously accepted command sequence from a known snapshot.
  /// A rejected command aborts replay rather than silently skipping history.
  static MatchSession replay({
    required MatchSession initial,
    required Iterable<MatchCommand> commands,
  }) {
    var session = initial;
    for (final command in commands) {
      final result = session.execute(command);
      if (!result.accepted) {
        throw StateError(
          'Replay stopped at command ${command.commandId}: '
          '${result.rejectionReason?.name} (${result.message}).',
        );
      }
      session = result.session;
    }
    return session;
  }
}
