import 'dart:convert';

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
    this.captureOnlySingleOpponentPawn = false,
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
    captureOnlySingleOpponentPawn: true,
  );

  final String id;
  final int version;
  final bool extraTurnOnSix;
  final bool extraTurnOnCapture;
  final bool extraTurnOnFinish;
  final bool threeConsecutiveSixesPenalty;
  final bool captureOnlySingleOpponentPawn;

  @override
  bool operator ==(Object other) =>
      other is LudoRuleProfile &&
      other.id == id &&
      other.version == version &&
      other.extraTurnOnSix == extraTurnOnSix &&
      other.extraTurnOnCapture == extraTurnOnCapture &&
      other.extraTurnOnFinish == extraTurnOnFinish &&
      other.threeConsecutiveSixesPenalty == threeConsecutiveSixesPenalty &&
      other.captureOnlySingleOpponentPawn == captureOnlySingleOpponentPawn;

  @override
  int get hashCode => Object.hash(
        id,
        version,
        extraTurnOnSix,
        extraTurnOnCapture,
        extraTurnOnFinish,
        threeConsecutiveSixesPenalty,
        captureOnlySingleOpponentPawn,
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
  const PawnCaptured(
    super.sequence,
    super.stateVersion,
    this.by,
    this.victim,
    this.pawnIndex,
  );
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

  /// Encodes the authoritative match state for durable local resume (schema v2).
  ///
  /// Presentation-only animation progress and transient events are purposely
  /// excluded. The state version and accepted command IDs survive restoration
  /// so stale/duplicate commands remain rejectable after an app restart.
  Map<String, Object?> toSnapshot() => {
        'schemaVersion': 2,
        'players': <Map<String, Object?>>[
          for (final player in players)
            <String, Object?>{
              'color': player.color.name,
              'pawnProgress': player.pawnProgress,
            },
        ],
        'activePlayer': activePlayer.name,
        'diceValue': diceValue,
        'winner': winner?.name,
        'ruleProfile': <String, Object?>{
          'id': ruleProfile.id,
          'version': ruleProfile.version,
          'extraTurnOnSix': ruleProfile.extraTurnOnSix,
          'extraTurnOnCapture': ruleProfile.extraTurnOnCapture,
          'extraTurnOnFinish': ruleProfile.extraTurnOnFinish,
          'threeConsecutiveSixesPenalty':
              ruleProfile.threeConsecutiveSixesPenalty,
          'captureOnlySingleOpponentPawn':
              ruleProfile.captureOnlySingleOpponentPawn,
        },
        'stateVersion': stateVersion,
        'consecutiveSixes': consecutiveSixes,
        'appliedCommandIds': appliedCommandIds.toList()..sort(),
      };

  String encodeSnapshot() => jsonEncode(toSnapshot());

  /// Restores a validated schema-v1 or schema-v2 snapshot. Unknown or malformed snapshots
  /// fail closed; callers should offer a fresh match rather than guess state.
  factory LudoGame.fromSnapshot(Map<String, dynamic> snapshot) {
    final schemaVersion = snapshot['schemaVersion'];
    if (schemaVersion != 1 && schemaVersion != 2) {
      throw const FormatException('Unsupported Ludo snapshot schema.');
    }
    final rawPlayers = snapshot['players'];
    final rawProfile = snapshot['ruleProfile'];
    final rawCommandIds = snapshot['appliedCommandIds'];
    if (rawPlayers is! List ||
        rawPlayers.length != PlayerColor.turnOrder.length ||
        rawProfile is! Map ||
        rawCommandIds is! List) {
      throw const FormatException('Malformed Ludo snapshot.');
    }

    final progressByColor = <PlayerColor, List<int>>{};
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map ||
          rawPlayer['color'] is! String ||
          rawPlayer['pawnProgress'] is! List) {
        throw const FormatException('Malformed player snapshot.');
      }
      final color = PlayerColor.values.byName(rawPlayer['color'] as String);
      final rawProgress = rawPlayer['pawnProgress'] as List;
      if (rawProgress.length != 4 || rawProgress.any((value) => value is! int)) {
        throw const FormatException('Malformed pawn progress snapshot.');
      }
      if (progressByColor.containsKey(color)) {
        throw const FormatException('Duplicate player in Ludo snapshot.');
      }
      progressByColor[color] = rawProgress.cast<int>();
    }
    if (!PlayerColor.turnOrder.every(progressByColor.containsKey)) {
      throw const FormatException('Ludo snapshot is missing a player.');
    }

    bool requiredBool(String key) {
      final value = rawProfile[key];
      if (value is! bool) {
        throw FormatException('Invalid rule profile field: $key.');
      }
      return value;
    }

    final profileId = rawProfile['id'];
    final profileVersion = rawProfile['version'];
    if (profileId is! String || profileVersion is! int || profileVersion < 1) {
      throw const FormatException('Invalid Ludo rule profile.');
    }
    final profile = LudoRuleProfile(
      id: profileId,
      version: profileVersion,
      extraTurnOnSix: requiredBool('extraTurnOnSix'),
      extraTurnOnCapture: requiredBool('extraTurnOnCapture'),
      extraTurnOnFinish: requiredBool('extraTurnOnFinish'),
      threeConsecutiveSixesPenalty:
          requiredBool('threeConsecutiveSixesPenalty'),
      // Schema v1 predates this rule field and retains its old
      // capture-all-opponents behaviour when restored.
      captureOnlySingleOpponentPawn: schemaVersion == 1
          ? false
          : requiredBool('captureOnlySingleOpponentPawn'),
    );

    final activeName = snapshot['activePlayer'];
    final winnerName = snapshot['winner'];
    final savedDice = snapshot['diceValue'];
    final savedVersion = snapshot['stateVersion'];
    final savedSixes = snapshot['consecutiveSixes'];
    if (activeName is! String ||
        (winnerName != null && winnerName is! String) ||
        (savedDice != null &&
            (savedDice is! int || savedDice < 1 || savedDice > 6)) ||
        savedVersion is! int ||
        savedVersion < 0 ||
        savedSixes is! int ||
        savedSixes < 0 ||
        (profile.threeConsecutiveSixesPenalty && savedSixes > 2) ||
        rawCommandIds.any((value) => value is! String || value.trim().isEmpty)) {
      throw const FormatException('Invalid Ludo snapshot state.');
    }
    final commands = rawCommandIds.cast<String>();
    if (commands.toSet().length != commands.length) {
      throw const FormatException('Duplicate command IDs in Ludo snapshot.');
    }

    return LudoGame._(
      players: List<LudoPlayer>.unmodifiable([
        for (final color in PlayerColor.turnOrder)
          LudoPlayer(color, pawnProgress: progressByColor[color]),
      ]),
      activePlayer: PlayerColor.values.byName(activeName),
      diceValue: savedDice as int?,
      winner: winnerName == null
          ? null
          : PlayerColor.values.byName(winnerName as String),
      ruleProfile: profile,
      stateVersion: savedVersion,
      consecutiveSixes: savedSixes,
      appliedCommandIds: Set<String>.unmodifiable(commands),
      events: const <LudoGameEvent>[],
    );
  }

  factory LudoGame.decodeSnapshot(String encoded) {
    final decoded = jsonDecode(encoded);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Ludo snapshot must be a JSON object.');
    }
    return LudoGame.fromSnapshot(decoded);
  }

  /// Selects the next player who has not already completed all four pawns.
  /// This also keeps restored/custom snapshots with completed players safe.
  PlayerColor _nextActivePlayer([PlayerColor? from]) {
    var candidate = (from ?? activePlayer).next;
    for (var i = 0; i < players.length; i++) {
      final player = players.firstWhere((item) => item.color == candidate);
      if (!player.hasWon) return candidate;
      candidate = candidate.next;
    }
    return from ?? activePlayer;
  }

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
      final nextPlayer = _nextActivePlayer();
      return LudoGame._(
        players: players,
        activePlayer: nextPlayer,
        ruleProfile: ruleProfile,
        stateVersion: stateVersion + 1,
        consecutiveSixes: 0,
        appliedCommandIds: _nextCommandIds(commandId),
        events: List<LudoGameEvent>.unmodifiable([
          DiceRolled(0, stateVersion + 1, activePlayer, value),
          ConsecutiveSixPenalty(1, stateVersion + 1, activePlayer),
          TurnChanged(
            2,
            stateVersion + 1,
            activePlayer,
            nextPlayer,
          ),
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
        : _nextActivePlayer();
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
      PawnMoved(
        0,
        stateVersion + 1,
        activePlayer,
        pawnIndex,
        previous,
        nextProgress,
      ),
    ];
    var captured = false;
    if (nextProgress < playerTrackLength &&
        !BoardGeometry.safeTrackCells.contains(
          _trackCell(activePlayer, nextProgress),
        )) {
      final landingCell = _trackCell(activePlayer, nextProgress);
      final opponentsAtLanding = <({int playerIndex, int pawnIndex})>[];
      for (var i = 0; i < updatedPlayers.length; i++) {
        if (updatedPlayers[i].color == activePlayer) continue;
        final opponent = updatedPlayers[i];
        for (var pawn = 0; pawn < opponent.pawnProgress.length; pawn++) {
          final progress = opponent.pawnProgress[pawn];
          if (progress >= 0 &&
              progress < playerTrackLength &&
              _trackCell(opponent.color, progress) == landingCell) {
            opponentsAtLanding.add((playerIndex: i, pawnIndex: pawn));
          }
        }
      }

      final mayCapture = !ruleProfile.captureOnlySingleOpponentPawn ||
          opponentsAtLanding.length == 1;
      if (mayCapture) {
        for (final target in opponentsAtLanding) {
          final opponent = updatedPlayers[target.playerIndex];
          updatedPlayers[target.playerIndex] =
              opponent.withPawn(target.pawnIndex, -1);
          emitted.add(
            PawnCaptured(
              emitted.length,
              stateVersion + 1,
              activePlayer,
              opponent.color,
              target.pawnIndex,
            ),
          );
          captured = true;
        }
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
        : _nextActivePlayer();
    if (gameWinner != null) {
      emitted.add(
        PlayerWon(emitted.length, stateVersion + 1, activePlayer),
      );
    } else if (nextPlayer != activePlayer) {
      emitted.add(
        TurnChanged(emitted.length, stateVersion + 1, activePlayer, nextPlayer),
      );
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
