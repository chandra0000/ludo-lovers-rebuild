import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';

/// Immutable visual instructions projected from one *accepted* match command.
///
/// UI widgets and animations must not infer a move result from the die or
/// changes in other pawn lists. MatchSession alone decides the authoritative
/// transition and exposes its ordered events.
class MatchMovePresentationPlan {
  const MatchMovePresentationPlan._({
    required this.player,
    required this.pawnIndex,
    required this.startProgress,
    required this.endProgress,
    required this.stepCount,
    this.feedback,
    required this.captureCount,
  });

  final PlayerColor player;
  final int pawnIndex;
  final int startProgress;
  final int endProgress;
  final int stepCount;
  final String? feedback;

  /// Number of captures confirmed by authoritative accepted events.
  final int captureCount;
  bool get hasCapture => captureCount > 0;

  factory MatchMovePresentationPlan.fromEvents({
    required Iterable<LudoGameEvent> events,
    required PlayerColor player,
    required int pawnIndex,
  }) {
    final recorded = List<LudoGameEvent>.of(events);
    // One accepted move command may animate exactly one pawn. Reject
    // inconsistent event batches rather than silently animating a partial move.
    final moves = recorded.whereType<PawnMoved>().toList();

    if (moves.length != 1 ||
        moves.single.player != player ||
        moves.single.pawnIndex != pawnIndex) {
      throw StateError(
        'Accepted pawn move must emit exactly one matching PawnMoved event.',
      );
    }
    final move = moves.single;
    final steps = move.to - move.from;
    if (move.from < -1 ||
        move.from >= finishProgress ||
        move.to < 0 ||
        move.to > finishProgress ||
        steps <= 0) {
      throw StateError('Accepted pawn movement has invalid progress bounds.');
    }

    final isWinner = recorded
        .whereType<GameCompleted>()
        .any((event) => event.winner == player);
    final captures = recorded
        .whereType<PawnCaptured>()
        .where((event) => event.by == player)
        .length;
    final extraTurn = recorded
        .whereType<ExtraTurnGranted>()
        .any((event) => event.player == player);
    final finished = recorded.whereType<PawnFinished>().any(
          (event) => event.player == player && event.pawnIndex == pawnIndex,
        );

    final String? feedback;
    if (isWinner) {
      feedback = '${player.name.toUpperCase()} WINS!';
    } else if (captures > 0) {
      final label = captures == 1 ? 'CAPTURE!' : '$captures CAPTURES!';
      feedback = extraTurn ? '$label EXTRA TURN' : label;
    } else if (finished) {
      feedback = extraTurn ? 'PAWN HOME! EXTRA TURN' : 'PAWN HOME!';
    } else {
      feedback = null;
    }

    return MatchMovePresentationPlan._(
      player: player,
      pawnIndex: pawnIndex,
      startProgress: move.from,
      endProgress: move.to,
      stepCount: steps,
      feedback: feedback,
      captureCount: captures,
    );
  }
}
