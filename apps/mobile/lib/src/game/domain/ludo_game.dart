import 'dart:convert';

import 'board_geometry.dart';
import 'player_color.dart';
import 'match_configuration.dart';
import 'team_up_policy.dart';

const int sharedTrackLength = BoardGeometry.trackLength;
const int playerTrackLength = BoardGeometry.playerTrackLength;
const int finishProgress = BoardGeometry.finishProgress;

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

  /// Approved faster objective; movement/capture rules match Classic v1.
  static const quickV1 = LudoRuleProfile(
    id: 'quick',
    version: 1,
    extraTurnOnFinish: true,
    threeConsecutiveSixesPenalty: true,
    captureOnlySingleOpponentPawn: true,
    enableHardBlockade: true,
  );

  static const teamUpV1 = LudoRuleProfile(
    id: 'team-up',
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

class TeamPawnCaptured extends LudoGameEvent {
  const TeamPawnCaptured(
    super.sequence,
    super.stateVersion,
    this.byTeam,
    this.victim,
    this.pawnIndex,
    this.cause,
  );
  final TeamUpTeam byTeam;
  final PlayerColor victim;
  final int pawnIndex;
  final TeamCaptureCause cause;
}

class TeamStackPriorityChanged extends LudoGameEvent {
  const TeamStackPriorityChanged(
    super.sequence,
    super.stateVersion,
    this.cell,
    this.priority,
  );
  final int cell;
  final TeamUpTeam? priority;
}

class TeamTurnTransferred extends LudoGameEvent {
  const TeamTurnTransferred(
    super.sequence,
    super.stateVersion,
    this.scheduled,
    this.recipient, {
    required this.bonus,
  });
  final PlayerColor scheduled;
  final PlayerColor recipient;
  final bool bonus;
}

class TeamWon extends LudoGameEvent {
  const TeamWon(
    super.sequence,
    super.stateVersion,
    this.team,
    this.finalPlayer,
  );
  final TeamUpTeam team;
  final PlayerColor finalPlayer;
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
    this.configuration = MatchConfiguration.compatibility,
    required this.activePlayer,
    required this.ruleProfile,
    required this.stateVersion,
    required this.consecutiveSixes,
    required this.appliedCommandIds,
    required this.events,
    this.diceValue,
    this.winner,
    PlayerColor? scheduledPlayer,
    Map<int, TeamUpTeam> teamCapturePriority = const {},
    this.winningTeam,
  })  : scheduledPlayer = scheduledPlayer ?? activePlayer,
        teamCapturePriority = Map.unmodifiable(teamCapturePriority);

  static MatchConfiguration _configurationFor(
    LudoRuleProfile profile,
    MatchConfiguration? requested,
  ) {
    final config = requested ??
        (profile.id == 'team-up'
            ? MatchConfiguration.local(MatchMode.teamUp)
            : profile.id == 'quick'
                ? MatchConfiguration.local(MatchMode.quick)
                : profile.id == 'classic'
                    ? MatchConfiguration.local(MatchMode.classic)
                    : MatchConfiguration.compatibility);
    if (config.mode != MatchMode.compatibility &&
        config.mode != MatchMode.classic &&
        config.mode != MatchMode.quick &&
        config.mode != MatchMode.teamUp) {
      throw const FormatException('Mode engine is not implemented');
    }
    if ((profile.id == 'classic' && config.mode != MatchMode.classic) ||
        (profile.id == 'quick' && config.mode != MatchMode.quick) ||
        (profile.id == 'team-up' && config.mode != MatchMode.teamUp)) {
      throw const FormatException(
        'Rule profile cannot be relabelled as another mode',
      );
    }
    if ((config.mode == MatchMode.classic &&
            (profile.id != 'classic' || profile.version != 1)) ||
        (config.mode == MatchMode.quick &&
            profile != LudoRuleProfile.quickV1) ||
        (config.mode == MatchMode.teamUp &&
            profile != LudoRuleProfile.teamUpV1)) {
      throw const FormatException('Mode and rule profile disagree');
    }
    return config;
  }

  factory LudoGame.fromProgress({
    required PlayerColor activePlayer,
    required Map<PlayerColor, List<int>> pawnProgress,
    LudoRuleProfile ruleProfile = LudoRuleProfile.currentV1,
    MatchConfiguration? configuration,
    PlayerColor? scheduledPlayer,
    Map<int, TeamUpTeam> teamCapturePriority = const {},
  }) {
    final config = _configurationFor(ruleProfile, configuration);
    if (!config.activePlayers.contains(activePlayer) ||
        pawnProgress.keys.any((c) => !config.activePlayers.contains(c))) {
      throw ArgumentError('Progress references an inactive seat');
    }
    final players = List<LudoPlayer>.unmodifiable(
      config.activePlayers.map(
        (color) => LudoPlayer(
          color,
          pawnProgress: pawnProgress[color] ?? List<int>.filled(4, -1),
        ),
      ),
    );
    final scheduled = scheduledPlayer ?? activePlayer;
    final finished = players.where((p) => p.hasWon).map((p) => p.color).toSet();
    final recipient = config.isTeamUp
        ? TeamUpPolicy.recipient(scheduled, finished)
        : activePlayer;
    if (recipient == null) {
      throw ArgumentError('Scheduled team has already finished');
    }
    if (config.isTeamUp) {
      TeamUpPolicy.validate(_teamPawns(players), teamCapturePriority);
    } else if (teamCapturePriority.isNotEmpty || scheduled != activePlayer) {
      throw ArgumentError('Team state cannot be applied to another mode');
    }
    return LudoGame._(
      configuration: config,
      players: players,
      scheduledPlayer: scheduled,
      teamCapturePriority: teamCapturePriority,
      activePlayer: recipient,
      ruleProfile: ruleProfile,
      stateVersion: 0,
      consecutiveSixes: 0,
      appliedCommandIds: const <String>{},
      events: const <LudoGameEvent>[],
    );
  }

  factory LudoGame.initial({
    LudoRuleProfile ruleProfile = LudoRuleProfile.currentV1,
    MatchConfiguration? configuration,
  }) =>
      LudoGame.fromProgress(
        activePlayer: PlayerColor.orange,
        pawnProgress: const {},
        ruleProfile: ruleProfile,
        configuration: configuration,
      );

  static List<TeamUpPawn> _teamPawns(List<LudoPlayer> players) => [
        for (final p in players)
          for (var i = 0; i < p.pawnProgress.length; i++)
            (color: p.color, index: i, progress: p.pawnProgress[i]),
      ];
  final PlayerColor scheduledPlayer;
  final Map<int, TeamUpTeam> teamCapturePriority;
  final TeamUpTeam? winningTeam;
  final MatchConfiguration configuration;
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

  /// Encodes the authoritative match state for local resume (schema v4).
  ///
  /// Presentation-only animation progress and transient events are purposely
  /// excluded. The state version and accepted command IDs survive restoration
  /// so stale/duplicate commands remain rejectable after an app restart.
  Map<String, Object?> toSnapshot() => {
        'schemaVersion': 4,
        'configuration': configuration.toJson(),
        if (configuration.isTeamUp)
          'teamState': <String, Object?>{
            'scheduledPlayer': scheduledPlayer.name,
            'priorityByCell': {
              for (final key in teamCapturePriority.keys.toList()..sort())
                '$key': teamCapturePriority[key]!.name,
            },
            'winningTeam': winningTeam?.name,
          },
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

  /// Restores supported schema-v1 through schema-v4 snapshots. Malformed
  /// snapshots fail closed; callers should start a fresh match instead.
  factory LudoGame.fromSnapshot(Map<String, dynamic> snapshot) {
    final schemaVersion = snapshot['schemaVersion'];
    if (schemaVersion != 1 &&
        schemaVersion != 2 &&
        schemaVersion != 3 &&
        schemaVersion != 4) {
      throw const FormatException('Unsupported Ludo snapshot schema.');
    }
    final rawPlayers = snapshot['players'];
    final rawProfile = snapshot['ruleProfile'];
    final rawCommandIds = snapshot['appliedCommandIds'];
    if (rawPlayers is! List ||
        rawPlayers.length < 2 ||
        rawPlayers.length > 4 ||
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

    final config = _configurationFor(
      profile,
      schemaVersion == 4
          ? MatchConfiguration.fromJson(snapshot['configuration'])
          : null,
    );
    if (progressByColor.length != config.activePlayers.length ||
        !config.activePlayers.every(progressByColor.containsKey)) {
      throw const FormatException(
        'Snapshot players disagree with configured seats',
      );
    }

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
      for (final color in config.activePlayers)
        LudoPlayer(color, pawnProgress: progressByColor[color]),
    ];
    if (!config.activePlayers.contains(activeColor) ||
        (winnerColor != null && !config.activePlayers.contains(winnerColor))) {
      throw const FormatException('Active/winning player is not participating');
    }
    PlayerColor scheduled = activeColor;
    final priority = <int, TeamUpTeam>{};
    TeamUpTeam? teamWinner;
    if (config.isTeamUp) {
      final rawTeam = snapshot['teamState'];
      if (rawTeam is! Map || rawTeam['priorityByCell'] is! Map) {
        throw const FormatException('Missing Team Up state');
      }
      scheduled = parseColor(rawTeam['scheduledPlayer'], 'scheduledPlayer');
      final rawPriority = rawTeam['priorityByCell'] as Map;
      for (final entry in rawPriority.entries) {
        final cell = int.tryParse(entry.key.toString());
        if (cell == null || entry.key != '$cell' || entry.value is! String) {
          throw const FormatException('Malformed capture priority');
        }
        try {
          priority[cell] = TeamUpTeam.values.byName(entry.value as String);
        } on ArgumentError {
          throw const FormatException('Unknown priority team');
        }
      }
      final rawWinner = rawTeam['winningTeam'];
      if (rawWinner != null) {
        if (rawWinner is! String) {
          throw const FormatException('Invalid winning team');
        }
        try {
          teamWinner = TeamUpTeam.values.byName(rawWinner);
        } on ArgumentError {
          throw const FormatException('Unknown winning team');
        }
      }
      TeamUpPolicy.validate(_teamPawns(restoredPlayers), priority);
      final finished =
          restoredPlayers.where((p) => p.hasWon).map((p) => p.color).toSet();
      final wonTeams = TeamUpTeam.values
          .where((t) => TeamUpPolicy.hasWon(t, finished))
          .toList();
      if (winnerColor == null) {
        if (teamWinner != null ||
            wonTeams.isNotEmpty ||
            TeamUpPolicy.recipient(scheduled, finished) != activeColor) {
          throw const FormatException(
            'Inconsistent scheduled recipient or team outcome',
          );
        }
      } else if (teamWinner == null ||
          wonTeams.length != 1 ||
          wonTeams.single != teamWinner ||
          TeamUpPolicy.teamFor(winnerColor) != teamWinner ||
          !finished.contains(winnerColor) ||
          activeColor != winnerColor ||
          savedDice != null) {
        throw const FormatException('Inconsistent Team Up winner');
      }
    } else {
      if (snapshot['teamState'] != null) {
        throw const FormatException('Foreign team state');
      }
      final completed = restoredPlayers
          .where(
            (player) =>
                player.pawnProgress.where((p) => p == finishProgress).length >=
                config.finishTarget,
          )
          .toList();
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
    }
    final commands = rawCommandIds.cast<String>();
    if (commands.toSet().length != commands.length) {
      throw const FormatException('Duplicate command IDs in Ludo snapshot.');
    }

    return LudoGame._(
      configuration: config,
      scheduledPlayer: scheduled,
      teamCapturePriority: priority,
      winningTeam: teamWinner,
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
    for (var i = 0; i < PlayerColor.turnOrder.length; i++) {
      final candidates = players.where((item) => item.color == candidate);
      if (candidates.isNotEmpty && !candidates.single.hasWon) return candidate;
      candidate = candidate.next;
    }
    return from ?? activePlayer;
  }

  ({PlayerColor scheduled, PlayerColor active}) _nextTurn([
    List<LudoPlayer>? after,
  ]) {
    if (!configuration.isTeamUp) {
      final next = _nextActivePlayer();
      return (scheduled: next, active: next);
    }
    final finished =
        (after ?? players).where((p) => p.hasWon).map((p) => p.color).toSet();
    return TeamUpPolicy.nextTurn(scheduledPlayer, finished);
  }

  void _transferEvent(
    List<LudoGameEvent> events,
    PlayerColor scheduled,
    PlayerColor recipient, {
    required bool bonus,
  }) {
    if (configuration.isTeamUp && scheduled != recipient) {
      events.add(
        TeamTurnTransferred(
          events.length,
          stateVersion + 1,
          scheduled,
          recipient,
          bonus: bonus,
        ),
      );
    }
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
    if (configuration.isTeamUp) {
      final projected = players
          .map(
            (p) => p.color == activePlayer ? p.withPawn(pawnIndex, target) : p,
          )
          .toList();
      final result = TeamUpPolicy.resolve(
        pawns: _teamPawns(projected),
        actor: activePlayer,
        previous: current,
        destination: target,
        priority: teamCapturePriority,
      );
      final captures = result.captures
          .where((c) => c.byTeam == TeamUpPolicy.teamFor(activePlayer))
          .toList();
      return ValidMove(
        pathTiles: path,
        isCapture: captures.isNotEmpty,
        capturedPawnColor: captures.isEmpty ? null : captures.first.victim,
        capturedPawnIndex: captures.isEmpty ? null : captures.first.pawnIndex,
      );
    }
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
      final next = _nextTurn();
      final nextPlayer = next.active;
      final penaltyEvents = <LudoGameEvent>[
        DiceRolled(0, stateVersion + 1, activePlayer, value),
        ConsecutiveSixPenalty(1, stateVersion + 1, activePlayer),
        TurnChanged(2, stateVersion + 1, activePlayer, nextPlayer),
      ];
      _transferEvent(penaltyEvents, next.scheduled, nextPlayer, bonus: false);
      return LudoGame._(
        configuration: configuration,
        scheduledPlayer: next.scheduled,
        teamCapturePriority: teamCapturePriority,
        winningTeam: winningTeam,
        players: players,
        activePlayer: nextPlayer,
        ruleProfile: ruleProfile,
        stateVersion: stateVersion + 1,
        consecutiveSixes: 0,
        appliedCommandIds: _nextCommandIds(commandId),
        events: List<LudoGameEvent>.unmodifiable(penaltyEvents),
      );
    }

    final version = stateVersion + 1;
    final nextGame = LudoGame._(
      configuration: configuration,
      scheduledPlayer: scheduledPlayer,
      teamCapturePriority: teamCapturePriority,
      winningTeam: winningTeam,
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
        configuration: configuration,
        scheduledPlayer: scheduledPlayer,
        teamCapturePriority: teamCapturePriority,
        winningTeam: winningTeam,
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
    final bonus = ruleProfile.extraTurnOnSix && diceValue == 6;
    final next = bonus
        ? (scheduled: scheduledPlayer, active: activePlayer)
        : _nextTurn();
    final nextPlayer = next.active;
    final events = <LudoGameEvent>[];
    if (nextPlayer != activePlayer) {
      events.add(TurnChanged(0, stateVersion + 1, activePlayer, nextPlayer));
    } else if (ruleProfile.extraTurnOnSix && diceValue == 6) {
      events.add(ExtraTurnGranted(0, stateVersion + 1, activePlayer));
    }
    if (!bonus) {
      _transferEvent(events, next.scheduled, nextPlayer, bonus: false);
    }
    return LudoGame._(
      configuration: configuration,
      scheduledPlayer: next.scheduled,
      teamCapturePriority: teamCapturePriority,
      winningTeam: winningTeam,
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
    final nextProgress = evaluation.pathTiles.last;
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
    var nextPriority = teamCapturePriority;
    if (configuration.isTeamUp) {
      final resolved = TeamUpPolicy.resolve(
        pawns: _teamPawns(updatedPlayers),
        actor: activePlayer,
        previous: previous,
        destination: nextProgress,
        priority: teamCapturePriority,
      );
      nextPriority = resolved.priority;
      for (final capture in resolved.captures) {
        final i = updatedPlayers.indexWhere((p) => p.color == capture.victim);
        updatedPlayers[i] = updatedPlayers[i].withPawn(capture.pawnIndex, -1);
        emitted.add(
          TeamPawnCaptured(
            emitted.length,
            stateVersion + 1,
            capture.byTeam,
            capture.victim,
            capture.pawnIndex,
            capture.cause,
          ),
        );
        if (capture.byTeam == TeamUpPolicy.teamFor(activePlayer)) {
          captured = true;
        }
      }
      final cells = {...teamCapturePriority.keys, ...nextPriority.keys}.toList()
        ..sort();
      for (final cell in cells) {
        if (teamCapturePriority[cell] != nextPriority[cell]) {
          emitted.add(
            TeamStackPriorityChanged(
              emitted.length,
              stateVersion + 1,
              cell,
              nextPriority[cell],
            ),
          );
        }
      }
    }

    if (!configuration.isTeamUp &&
        nextProgress < playerTrackLength &&
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
    final finished =
        updatedPlayers.where((p) => p.hasWon).map((p) => p.color).toSet();
    final teamWinner = configuration.isTeamUp &&
            TeamUpPolicy.hasWon(TeamUpPolicy.teamFor(activePlayer), finished)
        ? TeamUpPolicy.teamFor(activePlayer)
        : null;
    final gameWinner = configuration.isTeamUp
        ? (teamWinner == null ? null : activePlayer)
        : updatedCurrent.pawnProgress
                    .where((p) => p == finishProgress)
                    .length >=
                configuration.finishTarget
            ? activePlayer
            : null;
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
    final next = gameWinner != null
        ? (scheduled: scheduledPlayer, active: activePlayer)
        : bonusTurn
            ? (
                scheduled: scheduledPlayer,
                active: configuration.isTeamUp
                    ? TeamUpPolicy.recipient(activePlayer, finished)!
                    : activePlayer
              )
            : _nextTurn(updatedPlayers);
    final nextPlayer = next.active;
    if (gameWinner != null) {
      if (teamWinner != null) {
        emitted.add(
          TeamWon(
            emitted.length,
            stateVersion + 1,
            teamWinner,
            activePlayer,
          ),
        );
      }
      emitted.add(
        PlayerWon(emitted.length, stateVersion + 1, activePlayer),
      );
      emitted.add(
        GameCompleted(emitted.length, stateVersion + 1, activePlayer),
      );
    } else if (bonusTurn) {
      emitted.add(
        ExtraTurnGranted(emitted.length, stateVersion + 1, nextPlayer),
      );
    } else if (nextPlayer != activePlayer) {
      emitted.add(
        TurnChanged(emitted.length, stateVersion + 1, activePlayer, nextPlayer),
      );
    }

    if (gameWinner == null && (!bonusTurn || nextPlayer != activePlayer)) {
      _transferEvent(emitted, next.scheduled, nextPlayer, bonus: bonusTurn);
    }
    return LudoGame._(
      configuration: configuration,
      scheduledPlayer: next.scheduled,
      teamCapturePriority: nextPriority,
      winningTeam: teamWinner,
      players: List<LudoPlayer>.unmodifiable(updatedPlayers),
      activePlayer: nextPlayer,
      ruleProfile: ruleProfile,
      stateVersion: stateVersion + 1,
      consecutiveSixes: configuration.isTeamUp
          ? (bonusTurn && rollValue == 6 ? consecutiveSixes : 0)
          : nextPlayer == activePlayer
              ? consecutiveSixes
              : 0,
      appliedCommandIds: _nextCommandIds(commandId),
      events: List<LudoGameEvent>.unmodifiable(emitted),
      winner: gameWinner,
    );
  }

  int _trackCell(PlayerColor color, int progress) =>
      BoardGeometry.physicalTrackCell(color, progress);
}
