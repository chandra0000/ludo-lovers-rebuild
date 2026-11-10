import 'board_geometry.dart';
import 'player_color.dart';

const int sharedTrackLength = BoardGeometry.trackLength;
const int playerTrackLength = BoardGeometry.playerTrackLength;
const int finishProgress = 56;

/// Immutable, named rules configuration. Profiles are versioned so a saved
/// match can retain the exact rules under which it was started.
class LudoRuleProfile {
  const LudoRuleProfile({
    required this.id,
    required this.version,
    this.extraTurnOnSix = true,
    this.extraTurnOnCapture = true,
    this.extraTurnOnFinish = false,
    this.threeConsecutiveSixesPenalty = false,
  });

  /// Compatibility profile: preserves the behaviour of the original rebuild.
  static const currentV1 = LudoRuleProfile(
    id: 'ludo-lovers-current',
    version: 1,
  );

  /// Proposed Classic profile from the legacy rules specification.
  /// It remains opt-in until the product owner confirms this variant.
  static const classicV1 = LudoRuleProfile(
    id: 'classic',
    version: 1,
    extraTurnOnFinish: true,
    threeConsecutiveSixesPenalty: true,
  );

  final String id;
  final int version;
  final bool extraTurnOnSix;
  final bool extraTurnOnCapture;
  final bool extraTurnOnFinish;
  final bool threeConsecutiveSixesPenalty;

  @override
  bool operator ==(Object other) =>
      other is LudoRuleProfile &&
      other.id == id &&
      other.version == version &&
      other.extraTurnOnSix == extraTurnOnSix &&
      other.extraTurnOnCapture == extraTurnOnCapture &&
      other.extraTurnOnFinish == extraTurnOnFinish &&
      other.threeConsecutiveSixesPenalty == threeConsecutiveSixesPenalty;

  @override
  int get hashCode => Object.hash(
        id,
        version,
        extraTurnOnSix,
        extraTurnOnCapture,
        extraTurnOnFinish,
        threeConsecutiveSixesPenalty,
      );
}

sealed class LudoGameEvent {
  const LudoGameEvent(this.sequence, this.stateVersion);
  final int sequence;
  final int stateVersion;
}

class DiceRolled extends LudoGameEvent {
  const DiceRolled(super.sequence, super.stateVersion, this.player, this.value);
  final PlayerColor player;
  final int value;
}

class PawnMoved extends LudoGameEvent {
  const PawnMoved(
    super.sequence,
    super.stateVersion,
    this.player,
    this.pawnIndex,
    this.from,
    this.to,
  );
  final PlayerColor player;
  final int pawnIndex;
  final int from;
  final int to;
}

class PawnCaptured extends LudoGameEvent {
  const PawnCaptured(super.sequence, super.stateVersion, this.by, this.victim, this.pawnIndex);
  final PlayerColor by;
  final PlayerColor victim;
  final int pawnIndex;
}

class TurnChanged extends LudoGameEvent {
  const TurnChanged(super.sequence, super.stateVersion, this.from, this.to);
  final PlayerColor from;
  final PlayerColor to;
}

class ConsecutiveSixPenalty extends LudoGameEvent {
  const ConsecutiveSixPenalty(super.sequence, super.stateVersion, this.player);
  final PlayerColor player;
}

class PlayerWon extends LudoGameEvent {
  const PlayerWon(super.sequence, super.stateVersion, this.player);
  final PlayerColor player;
}

class LudoPlayer {
  LudoPlayer(
    this.color, {
    List<int>? pawnProgress,
  }) : pawnProgress = List<int>.unmodifiable(
          pawnProgress ?? List<int>.filled(4, -1),
        ) {
    if (this.pawnProgress.length != 4 ||
        this.pawnProgress.any(
          (step) => step < -1 || step > finishProgress,
        )) {
      throw ArgumentError(
        'Each player must have four pawns with progress -1..$finishProgress.',
      );
    }
  }

  final PlayerColor color;
  final List<int> pawnProgress;

  LudoPlayer withPawn(int pawnIndex, int progress) {
    final next = List<int>.of(pawnProgress)..[pawnIndex] = progress;
    return LudoPlayer(color, pawnProgress: next);
  }

  bool get hasWon => pawnProgress.every((step) => step == finishProgress);
}

class LudoGame {
  LudoGame._({
    required this.players,
    required this.activePlayer,
    required this.ruleProfile,
    required this.stateVersion,
    required this.consecutiveSixes,
    required this.appliedCommandIds,
    required this.events,
    this.diceValue,
    this.winner,
  });

  factory LudoGame.fromProgress({
    required PlayerColor activePlayer,
    required Map<PlayerColor, List<int>> pawnProgress,
    LudoRuleProfile ruleProfile = LudoRuleProfile.currentV1,
  }) =>
      LudoGame._(
        players: List<LudoPlayer>.unmodifiable(
          PlayerColor.turnOrder.map(
            (color) => LudoPlayer(
              color,
              pawnProgress: pawnProgress[color] ?? List<int>.filled(4, -1),
            ),
          ),
        ),
        activePlayer: activePlayer,
        ruleProfile: ruleProfile,
        stateVersion: 0,
        consecutiveSixes: 0,
        appliedCommandIds: const <String>{},
        events: const <LudoGameEvent>[],
      );

  factory LudoGame.initial({
    LudoRuleProfile ruleProfile = LudoRuleProfile.currentV1,
  }) =>
      LudoGame._(
        players: List<LudoPlayer>.unmodifiable(
          PlayerColor.turnOrder.map((color) => LudoPlayer(color)),
        ),
        activePlayer: PlayerColor.orange,
        ruleProfile: ruleProfile,
        stateVersion: 0,
        consecutiveSixes: 0,
        appliedCommandIds: const <String>{},
        events: const <LudoGameEvent>[],
      );

  final List<LudoPlayer> players;
  final PlayerColor activePlayer;
  final int? diceValue;
  final PlayerColor? winner;
  final LudoRuleProfile ruleProfile;
  final int stateVersion;
  final int consecutiveSixes;
  final Set<String> appliedCommandIds;

  /// Events emitted by the most recent accepted transition, in deterministic
  /// order. Sequence numbers are local to that transition (starting at zero).
  final List<LudoGameEvent> events;

  LudoPlayer get currentPlayer =>
      players.firstWhere((player) => player.color == activePlayer);

  void _validateCommand({
    int? expectedStateVersion,
    String? commandId,
  }) {
    if (expectedStateVersion != null &&
        expectedStateVersion != stateVersion) {
      throw StateError(
        'Stale command: expected state $expectedStateVersion, current state is $stateVersion.',
      );
    }
    if (commandId != null &&
        (commandId.trim().isEmpty || appliedCommandIds.contains(commandId))) {
      throw StateError('Duplicate or empty command id: $commandId.');
    }
  }

  Set<String> _nextCommandIds(String? commandId) {
    if (commandId == null) return appliedCommandIds;
    return Set<String>.unmodifiable({...appliedCommandIds, commandId});
  }

  List<int> legalPawnIndices({int? roll}) {
    final value = roll ?? diceValue;
    if (value == null || winner != null) {
      return const [];
    }
    final result = <int>[];
    for (var i = 0; i < currentPlayer.pawnProgress.length; i++) {
      final progress = currentPlayer.pawnProgress[i];
      if (progress == -1 ? value == 6 : progress + value <= finishProgress) {
        result.add(i);
      }
    }
    return List<int>.unmodifiable(result);
  }

  LudoGame roll(
    int value, {
    int? expectedStateVersion,
    String? commandId,
  }) {
    _validateCommand(
      expectedStateVersion: expectedStateVersion,
      commandId: commandId,
    );
    if (winner != null) {
      throw StateError('The game has already finished.');
    }
    if (diceValue != null) {
      throw StateError('Move a pawn before rolling again.');
    }
    if (value < 1 || value > 6) {
      throw ArgumentError.value(value, 'value', 'Dice must be 1..6.');
    }

    final nextSixes = value == 6 ? consecutiveSixes + 1 : 0;
    if (value == 6 &&
        ruleProfile.threeConsecutiveSixesPenalty &&
        nextSixes >= 3) {
      return LudoGame._(
        players: players,
        activePlayer: activePlayer.next,
        ruleProfile: ruleProfile,
        stateVersion: stateVersion + 1,
        consecutiveSixes: 0,
        appliedCommandIds: _nextCommandIds(commandId),
        events: List<LudoGameEvent>.unmodifiable([
          DiceRolled(0, stateVersion + 1, activePlayer, value),
          ConsecutiveSixPenalty(1, stateVersion + 1, activePlayer),
          TurnChanged(2, stateVersion + 1, activePlayer, activePlayer.next),
        ]),
      );
    }

    return LudoGame._(
      players: players,
      activePlayer: activePlayer,
      diceValue: value,
      ruleProfile: ruleProfile,
      stateVersion: stateVersion + 1,
      consecutiveSixes: nextSixes,
      appliedCommandIds: _nextCommandIds(commandId),
      events: List<LudoGameEvent>.unmodifiable([
        DiceRolled(0, stateVersion + 1, activePlayer, value),
      ]),
      winner: winner,
    );
  }

  LudoGame passTurn({
    int? expectedStateVersion,
    String? commandId,
  }) {
    _validateCommand(
      expectedStateVersion: expectedStateVersion,
      commandId: commandId,
    );
    if (diceValue == null) {
      throw StateError('Roll the dice first.');
    }
    if (legalPawnIndices().isNotEmpty) {
      throw StateError('A legal pawn move is available.');
    }
    final nextPlayer = ruleProfile.extraTurnOnSix && diceValue == 6
        ? activePlayer
        : activePlayer.next;
    final events = <LudoGameEvent>[];
    if (nextPlayer != activePlayer) {
      events.add(TurnChanged(0, stateVersion + 1, activePlayer, nextPlayer));
    }
    return LudoGame._(
      players: players,
      activePlayer: nextPlayer,
      ruleProfile: ruleProfile,
      stateVersion: stateVersion + 1,
      consecutiveSixes: nextPlayer == activePlayer ? consecutiveSixes : 0,
      appliedCommandIds: _nextCommandIds(commandId),
      events: List<LudoGameEvent>.unmodifiable(events),
    );
  }

  LudoGame movePawn(
    int pawnIndex, {
    int? expectedStateVersion,
    String? commandId,
  }) {
    _validateCommand(
      expectedStateVersion: expectedStateVersion,
      commandId: commandId,
    );
    final rollValue = diceValue;
    if (rollValue == null) {
      throw StateError('Roll the dice first.');
    }
    if (!legalPawnIndices().contains(pawnIndex)) {
      throw StateError(
        'Pawn $pawnIndex cannot move with a roll of $rollValue.',
      );
    }

    final updatedPlayers = List<LudoPlayer>.of(players);
    final playerIndex = updatedPlayers.indexWhere(
      (player) => player.color == activePlayer,
    );
    final player = updatedPlayers[playerIndex];
    final previous = player.pawnProgress[pawnIndex];
    final nextProgress = previous == -1 ? 0 : previous + rollValue;
    updatedPlayers[playerIndex] = player.withPawn(pawnIndex, nextProgress);

    final emitted = <LudoGameEvent>[
      PawnMoved(0, stateVersion + 1, activePlayer, pawnIndex, previous, nextProgress),
    ];
    var captured = false;
    if (nextProgress < playerTrackLength &&
        !BoardGeometry.safeTrackCells.contains(
          _trackCell(activePlayer, nextProgress),
        )) {
      final landingCell = _trackCell(activePlayer, nextProgress);
      for (var i = 0; i < updatedPlayers.length; i++) {
        if (updatedPlayers[i].color == activePlayer) continue;
        final opponent = updatedPlayers[i];
        var changed = opponent;
        for (var pawn = 0; pawn < opponent.pawnProgress.length; pawn++) {
          final progress = opponent.pawnProgress[pawn];
          if (progress >= 0 &&
              progress < playerTrackLength &&
              _trackCell(opponent.color, progress) == landingCell) {
            changed = changed.withPawn(pawn, -1);
            emitted.add(
              PawnCaptured(
                emitted.length,
                stateVersion + 1,
                activePlayer,
                opponent.color,
                pawn,
              ),
            );
            captured = true;
          }
        }
        updatedPlayers[i] = changed;
      }
    }

    final updatedCurrent = updatedPlayers[playerIndex];
    final gameWinner = updatedCurrent.hasWon ? activePlayer : null;
    final finishedPawn = nextProgress == finishProgress;
    final bonusTurn = (ruleProfile.extraTurnOnSix && rollValue == 6) ||
        (ruleProfile.extraTurnOnCapture && captured) ||
        (ruleProfile.extraTurnOnFinish && finishedPawn);
    final nextPlayer = gameWinner != null || bonusTurn
        ? activePlayer
        : activePlayer.next;
    if (gameWinner != null) {
      emitted.add(PlayerWon(emitted.length, stateVersion + 1, activePlayer));
    } else if (nextPlayer != activePlayer) {
      emitted.add(TurnChanged(emitted.length, stateVersion + 1, activePlayer, nextPlayer));
    }

    return LudoGame._(
      players: List<LudoPlayer>.unmodifiable(updatedPlayers),
      activePlayer: nextPlayer,
      ruleProfile: ruleProfile,
      stateVersion: stateVersion + 1,
      consecutiveSixes: nextPlayer == activePlayer ? consecutiveSixes : 0,
      appliedCommandIds: _nextCommandIds(commandId),
      events: List<LudoGameEvent>.unmodifiable(emitted),
      winner: gameWinner,
    );
  }

  int _trackCell(PlayerColor color, int progress) =>
      BoardGeometry.physicalTrackCell(color, progress);
}
