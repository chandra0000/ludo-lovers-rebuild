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
    this.enableHardBlockade = false,
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
    enableHardBlockade: true,
  );

  final String id;
  final int version;
  final bool extraTurnOnSix;
  final bool extraTurnOnCapture;
  final bool extraTurnOnFinish;
  final bool threeConsecutiveSixesPenalty;
  final bool captureOnlySingleOpponentPawn;
  final bool enableHardBlockade;

  @override
  bool operator ==(Object other) =>
      other is LudoRuleProfile &&
      other.id == id &&
      other.version == version &&
      other.extraTurnOnSix == extraTurnOnSix &&
      other.extraTurnOnCapture == extraTurnOnCapture &&
      other.extraTurnOnFinish == extraTurnOnFinish &&
      other.threeConsecutiveSixesPenalty == threeConsecutiveSixesPenalty &&
      other.captureOnlySingleOpponentPawn == captureOnlySingleOpponentPawn &&
      other.enableHardBlockade == enableHardBlockade;

  @override
  int get hashCode => Object.hash(
        id,
        version,
        extraTurnOnSix,
        extraTurnOnCapture,
        extraTurnOnFinish,
        threeConsecutiveSixesPenalty,
        captureOnlySingleOpponentPawn,
        enableHardBlockade,
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

class NoLegalMoveEvent extends LudoGameEvent {
  const NoLegalMoveEvent(
    super.sequence,
    super.stateVersion,
    this.player,
    this.diceValue,
  );
  final PlayerColor player;
  final int diceValue;
}

class ExtraTurnGranted extends LudoGameEvent {
  const ExtraTurnGranted(super.sequence, super.stateVersion, this.player);
  final PlayerColor player;
}

class PawnFinished extends LudoGameEvent {
  const PawnFinished(
    super.sequence,
    super.stateVersion,
    this.player,
    this.pawnIndex,
  );
  final PlayerColor player;
  final int pawnIndex;
}

class GameCompleted extends LudoGameEvent {
  const GameCompleted(super.sequence, super.stateVersion, this.winner);
  final PlayerColor winner;
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

/// Explains why a pawn cannot use the current roll.
enum MoveInvalidReason {
  pawnInYardNeedsSix,
  overshootsHome,
  pathBlockedByBlockade,
  landingOnProtectedStack,
  noPendingRoll,
  invalidPawnIndex,
  invalidDice,
}

/// Result of evaluating one pawn against an immutable game snapshot.
sealed class MoveEvaluationResult {
  const MoveEvaluationResult();
}

/// A legal route. pathTiles contains player-relative progress positions,
/// including the destination; it is not a list of screen coordinates.
class ValidMove extends MoveEvaluationResult {
  const ValidMove({
    required this.pathTiles,
    this.isCapture = false,
    this.capturedPawnColor,
    this.capturedPawnIndex,
  });
  final List<int> pathTiles;
  final bool isCapture;
  final PlayerColor? capturedPawnColor;
  final int? capturedPawnIndex;
}

class InvalidMove extends MoveEvaluationResult {
  const InvalidMove(this.reason);
  final MoveInvalidReason reason;
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

  /// Whether the current roll has no legal move and must be passed.
  bool get awaitingPass =>
      diceValue != null && winner == null && legalPawnIndices().isEmpty;

  /// Encodes the authoritative match state for local resume (schema v2).
  ///
  /// Presentation-only animation progress and transient events are purposely
  /// excluded. The state version and accepted command IDs survive restoration
  /// so stale/duplicate commands remain rejectable after an app restart.
  Map<String, Object?> toSnapshot() => {
        'schemaVersion': 3,
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
          'enableHardBlockade': ruleProfile.enableHardBlockade,
        },
        'stateVersion': stateVersion,
        'consecutiveSixes': consecutiveSixes,
        'appliedCommandIds': appliedCommandIds.toList()..sort(),
      };

  String encodeSnapshot() => jsonEncode(toSnapshot());

  /// Restores schema-v1, schema-v2 or schema-v3 snapshots. Malformed
  /// snapshots fail closed; callers should start a fresh match instead.
  factory LudoGame.fromSnapshot(Map<String, dynamic> snapshot) {
    final schemaVersion = snapshot['schemaVersion'];
    if (schemaVersion != 1 && schemaVersion != 2 && schemaVersion != 3) {
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

    PlayerColor parseColor(Object? value, String field) {
      if (value is! String) {
        throw FormatException('Invalid player field: $field.');
      }
      try {
        return PlayerColor.values.byName(value);
      } on ArgumentError {
        throw FormatException('Unknown player color: $value.');
      }
    }

    final progressByColor = <PlayerColor, List<int>>{};
    for (final rawPlayer in rawPlayers) {
      if (rawPlayer is! Map ||
          rawPlayer['color'] is! String ||
          rawPlayer['pawnProgress'] is! List) {
        throw const FormatException('Malformed player snapshot.');
      }
      final color = parseColor(rawPlayer['color'], 'color');
      final rawProgress = rawPlayer['pawnProgress'] as List;
      if (rawProgress.length != 4 ||
          rawProgress.any((value) => value is! int)) {
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
    if (profileId is! String ||
        profileId.trim().isEmpty ||
        profileVersion is! int ||
        profileVersion < 1) {
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
      // Hard-blockade semantics were added in schema v3. Older saves retain
      // their previous pass-through behaviour.
      enableHardBlockade:
          schemaVersion < 3 ? false : requiredBool('enableHardBlockade'),
    );

    final activeName = snapshot['activePlayer'];
    final winnerName = snapshot['winner'];
    final savedDice = snapshot['diceValue'];
    final savedVersion = snapshot['stateVersion'];
    final savedSixes = snapshot['consecutiveSixes'];
    if ((savedDice != null &&
            (savedDice is! int || savedDice < 1 || savedDice > 6)) ||
        savedVersion is! int ||
        savedVersion < 0 ||
        savedSixes is! int ||
        savedSixes < 0 ||
        (profile.threeConsecutiveSixesPenalty && savedSixes > 2) ||
        rawCommandIds.any(
          (value) => value is! String || value.trim().isEmpty,
        )) {
      throw const FormatException('Invalid Ludo snapshot state.');
    }
    final activeColor = parseColor(activeName, 'activePlayer');
    final winnerColor =
        winnerName == null ? null : parseColor(winnerName, 'winner');
    final restoredPlayers = <LudoPlayer>[
      for (final color in PlayerColor.turnOrder)
        LudoPlayer(color, pawnProgress: progressByColor[color]),
    ];
    final completed = restoredPlayers.where((player) => player.hasWon).toList();
    if ((winnerColor == null && completed.isNotEmpty) ||
        (winnerColor != null &&
            (completed.length != 1 ||
                completed.single.color != winnerColor ||
                activeColor != winnerColor ||
                savedDice != null))) {
      throw const FormatException(
        'Inconsistent winner/completed-player snapshot state.',
      );
    }
    final commands = rawCommandIds.cast<String>();
    if (commands.toSet().length != commands.length) {
      throw const FormatException('Duplicate command IDs in Ludo snapshot.');
    }

    return LudoGame._(
      players: List<LudoPlayer>.unmodifiable(restoredPlayers),
      activePlayer: activeColor,
      diceValue: savedDice as int?,
      winner: winnerColor,
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
    if (expectedStateVersion != null && expectedStateVersion != stateVersion) {
      throw StateError(
        'Stale command: expected $expectedStateVersion, found $stateVersion.',
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

  /// Evaluates a pawn move without mutating the game.
  /// Hard blockades are checked on intermediate shared-track cells only.
  MoveEvaluationResult evaluatePawnMove(int pawnIndex, {int? roll}) {
    final value = roll ?? diceValue;
    if (value != null && (value < 1 || value > 6)) {
      return const InvalidMove(MoveInvalidReason.invalidDice);
    }
    if (value == null || winner != null) {
      return const InvalidMove(MoveInvalidReason.noPendingRoll);
    }
    if (pawnIndex < 0 || pawnIndex >= currentPlayer.pawnProgress.length) {
      return const InvalidMove(MoveInvalidReason.invalidPawnIndex);
    }
    final current = currentPlayer.pawnProgress[pawnIndex];
    if (current == -1 && value != 6) {
      return const InvalidMove(MoveInvalidReason.pawnInYardNeedsSix);
    }
    final target = current == -1 ? 0 : current + value;
    if (target > finishProgress) {
      return const InvalidMove(MoveInvalidReason.overshootsHome);
    }
    final path = List<int>.unmodifiable(
      List<int>.generate(target - current, (index) => current + index + 1),
    );
    if (ruleProfile.enableHardBlockade) {
      for (final progress in path) {
        if (progress >= playerTrackLength || progress == target) break;
        final cell = _trackCell(activePlayer, progress);
        for (final opponent in players) {
          if (opponent.color == activePlayer) continue;
          var count = 0;
          for (final opponentProgress in opponent.pawnProgress) {
            if (opponentProgress >= 0 &&
                opponentProgress < playerTrackLength &&
                _trackCell(opponent.color, opponentProgress) == cell) {
              count++;
            }
          }
          if (count >= 2) {
            return const InvalidMove(
              MoveInvalidReason.pathBlockedByBlockade,
            );
          }
        }
      }
    }
    if (target >= playerTrackLength) return ValidMove(pathTiles: path);
    final destination = _trackCell(activePlayer, target);
    final occupants = <({PlayerColor color, int pawnIndex})>[];
    for (final player in players) {
      if (player.color == activePlayer) continue;
      for (var index = 0; index < player.pawnProgress.length; index++) {
        final progress = player.pawnProgress[index];
        if (progress >= 0 &&
            progress < playerTrackLength &&
            _trackCell(player.color, progress) == destination) {
          occupants.add((color: player.color, pawnIndex: index));
        }
      }
    }
    if (ruleProfile.captureOnlySingleOpponentPawn && occupants.length >= 2) {
      return const InvalidMove(MoveInvalidReason.landingOnProtectedStack);
    }
    if (occupants.isNotEmpty &&
        !BoardGeometry.safeTrackCells.contains(destination)) {
      // Classic has already rejected a protected pair above. The legacy
      // compatibility profile can capture a whole stack, so expose that
      // destination as a capture even though the result's singular victim
      // fields identify only the first target for concise UI feedback.
      final victim = occupants.first;
      return ValidMove(
        pathTiles: path,
        isCapture: true,
        capturedPawnColor: victim.color,
        capturedPawnIndex: victim.pawnIndex,
      );
    }
    return ValidMove(pathTiles: path);
  }

  List<int> legalPawnIndices({int? roll}) {
    final value = roll ?? diceValue;
    if (value == null || winner != null) {
      return const [];
    }
    final result = <int>[];
    for (var i = 0; i < currentPlayer.pawnProgress.length; i++) {
      if (evaluatePawnMove(i, roll: value) is ValidMove) result.add(i);
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

    final version = stateVersion + 1;
    final nextGame = LudoGame._(
      players: players,
      activePlayer: activePlayer,
      diceValue: value,
      ruleProfile: ruleProfile,
      stateVersion: version,
      consecutiveSixes: nextSixes,
      appliedCommandIds: _nextCommandIds(commandId),
      events: List<LudoGameEvent>.unmodifiable([
        DiceRolled(0, version, activePlayer, value),
      ]),
      winner: winner,
    );
    if (!nextGame.awaitingPass) return nextGame;
    return nextGame._withEvents([
      ...nextGame.events,
      NoLegalMoveEvent(1, version, activePlayer, value),
    ]);
  }

  LudoGame _withEvents(List<LudoGameEvent> nextEvents) => LudoGame._(
        players: players,
        activePlayer: activePlayer,
        diceValue: diceValue,
        winner: winner,
        ruleProfile: ruleProfile,
        stateVersion: stateVersion,
        consecutiveSixes: consecutiveSixes,
        appliedCommandIds: appliedCommandIds,
        events: List<LudoGameEvent>.unmodifiable(nextEvents),
      );

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
    if (!awaitingPass) {
      throw StateError('A legal pawn move is available.');
    }
    final nextPlayer = ruleProfile.extraTurnOnSix && diceValue == 6
        ? activePlayer
        : _nextActivePlayer();
    final events = <LudoGameEvent>[];
    if (nextPlayer != activePlayer) {
      events.add(TurnChanged(0, stateVersion + 1, activePlayer, nextPlayer));
    } else if (ruleProfile.extraTurnOnSix && diceValue == 6) {
      events.add(ExtraTurnGranted(0, stateVersion + 1, activePlayer));
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
    final evaluation = evaluatePawnMove(pawnIndex, roll: rollValue);
    if (evaluation is! ValidMove) {
      final reason = (evaluation as InvalidMove).reason.name;
      throw StateError('Pawn $pawnIndex cannot move: $reason.');
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
    if (finishedPawn) {
      emitted.add(
        PawnFinished(
          emitted.length,
          stateVersion + 1,
          activePlayer,
          pawnIndex,
        ),
      );
    }
    final bonusTurn = (ruleProfile.extraTurnOnSix && rollValue == 6) ||
        (ruleProfile.extraTurnOnCapture && captured) ||
        (ruleProfile.extraTurnOnFinish && finishedPawn);
    final nextPlayer =
        gameWinner != null || bonusTurn ? activePlayer : _nextActivePlayer();
    if (gameWinner != null) {
      emitted.add(
        PlayerWon(emitted.length, stateVersion + 1, activePlayer),
      );
      emitted.add(
        GameCompleted(emitted.length, stateVersion + 1, activePlayer),
      );
    } else if (bonusTurn) {
      emitted.add(
        ExtraTurnGranted(emitted.length, stateVersion + 1, activePlayer),
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