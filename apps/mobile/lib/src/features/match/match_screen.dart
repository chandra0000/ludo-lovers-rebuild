import '../../theme/app_typography.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/application/match_session.dart';
import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/board_geometry.dart';
import '../../game/domain/team_up_policy.dart';
import '../../game/domain/mode_registry.dart';
import '../../game/domain/feedback_preferences.dart';
import '../../game/infrastructure/persistence/feedback_preferences_store.dart';
import '../../game/domain/persistence/saved_match.dart';
import '../../game/presentation/shake_feedback_wrapper.dart';

import 'local_match_chat_sheet.dart';
import '../../../features/game/presentation/widgets/cached_ludo_board.dart';
import 'match_board_focus_frame.dart';
import 'match_board_artwork.dart';
import 'match_safe_star_layer.dart';
import 'match_command_controller.dart';
import 'match_move_presentation_plan.dart';
import 'match_animation_lifecycle.dart';
import 'match_persistence_controller.dart';
import 'match_fx_listener.dart';
import 'match_dialogs.dart';
import 'match_feedback.dart';
import 'match_feedback_settings.dart';
import 'match_reaction_controls.dart';
import 'match_landing_celebration.dart';
import 'match_pawn_layer.dart';
import 'match_destination_preview.dart';
import 'match_turn_coordinator.dart';
import 'match_result_presentation.dart';
import 'team_progress_panel.dart';
import 'game_board_scaffold.dart';
import 'royal_backdrop.dart';
import 'social_overlay_coordinator.dart';
import 'match_utility_bar.dart';
import '../../game/presentation/luxury_dice.dart';
import 'match_ai_scheduler.dart';
import 'match_turn_resolution_controller.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    this.rollDice,
    this.saveMatch,
    this.initialGame,
    this.aiPlayers = const {},
    this.aiSeed = 1,
    this.aiDifficulty = LudoAiDifficulty.medium,
    this.profiles,
    this.showDynamicProfiles = true,
    this.boardImage = const AssetImage(MatchBoardArtwork.assetPath),
  });

  @visibleForTesting
  final int Function()? rollDice;

  @visibleForTesting
  final Future<void> Function(SavedMatch)? saveMatch;

  @visibleForTesting
  final LudoGame? initialGame;

  @visibleForTesting
  final ImageProvider boardImage;

  /// Optional identities supplied by a local lobby or future online session.
  final List<MatchPlayerProfile>? profiles;

  /// Dynamic profiles are enabled for the board-only artwork by default.
  final bool showDynamicProfiles;

  final Set<PlayerColor> aiPlayers;
  final int aiSeed;
  final LudoAiDifficulty aiDifficulty;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final Set<PlayerColor> _aiPlayers = Set.unmodifiable(widget.aiPlayers);
  PlayerColor get _presentedPlayer =>
      _matchController.turns.snapshot.presentedPlayer;
  late final MatchCommandController _matchController = MatchCommandController(
    _newMatchSession(
      widget.initialGame ??
          LudoGame.initial(ruleProfile: LudoRuleProfile.currentV2),
    ),
  );

  MatchSession _newMatchSession(LudoGame game) {
    final matchId =
        'local-${widget.aiSeed}-${DateTime.now().microsecondsSinceEpoch}';
    return MatchSession.local(matchId: matchId, game: game);
  }

  late final List<MatchPlayerProfile> _profiles = MatchPlayerProfile.roster(
    widget.profiles ?? MatchPlayerProfile.local(aiPlayers: _aiPlayers),
    aiPlayers: _aiPlayers,
  );

  MatchPlayerProfile _profileFor(PlayerColor color) =>
      _profiles.singleWhere((profile) => profile.color == color);

  LudoGame get _game => _matchController.game;
  late final math.Random _random = math.Random(widget.aiSeed);
  late final MatchTurnCoordinator _turns = MatchTurnCoordinator(
    controller: _matchController,
    aiPlayers: _aiPlayers,
    aiSeed: widget.aiSeed,
    difficulty: widget.aiDifficulty,
    isActive: () => mounted && _canAct,
    movementBusy: () => _movementController.isAnimating,
    diceBusy: () => _isDiceAnimating,
    rollHuman: () => widget.rollDice?.call() ?? _random.nextInt(6) + 1,
    execute: _applyCommand,
    onRollAccepted: _presentAcceptedRoll,
    onMoveAccepted: _presentAcceptedMove,
    onDiceSettled: () => setState(_animations.completeDiceRoll),
    onChanged: () {
      if (mounted) setState(() {});
    },
    onPenalty: _showConsecutiveSixPenalty,
  );
  MatchAiScheduler get _aiScheduler => _turns.aiScheduler;
  bool _isAppResumed = true;
  bool _exitDialogOpen = false;
  bool _allowExit = false;
  bool _boardReady = false;
  bool get _canAct => _boardReady && _isAppResumed && !_exitDialogOpen;

  void _onBoardReadinessChanged(bool ready) {
    if (!mounted || _boardReady == ready) return;
    setState(() => _boardReady = ready);
    if (!ready) {
      _turnResolution.cancel();
      _aiScheduler.cancel();
      return;
    }
    _resumeAcceptedTurn();
  }

  late final MatchPersistenceController _persistence =
      MatchPersistenceController(save: widget.saveMatch);
  late final MatchAnimationLifecycle _animations = MatchAnimationLifecycle(
    vsync: this,
    onMovementTick: _handleMovementTick,
    onMovementStatus: _handleMovementStatus,
  );
  late final Listenable _boardMotion =
      Listenable.merge([_animations.movement, _animations.preview]);
  AnimationController get _movementController => _animations.movement;
  AnimationController get _previewController => _animations.preview;
  bool get _isDiceAnimating => _animations.isDiceAnimating;
  int get _diceRollId => _animations.diceRollId;
  MatchTurnResolutionController get _turnResolution => _turns.resolution;
  final Map<String, GlobalKey<ShakeFeedbackWrapperState>> _shakeKeys = {};
  int? _selectedPawnIndex;
  final _social = SocialOverlayCoordinator();
  FeedbackPreferences _feedbackPreferences = const FeedbackPreferences();
  final _feedbackStore = const FeedbackPreferencesStore();
  var _feedback = MatchFeedback();
  Future<void> _feedbackWrites = Future<void>.value();
  bool get _reduceMotion =>
      _feedbackPreferences.reduceMotion ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  bool _feedbackChanged = false;

  Future<void> _loadFeedbackPreferences() async {
    try {
      final value = await _feedbackStore.load();
      if (mounted && !_feedbackChanged) {
        setState(() => _feedbackPreferences = value);
        if (value.sound) unawaited(_feedback.prepare());
      }
    } catch (error) {
      debugPrint('Could not load game feedback settings: $error');
    }
  }

  void _changeFeedbackPreferences(FeedbackPreferences value) {
    _feedbackChanged = true;
    setState(() => _feedbackPreferences = value);
    if (value.sound) unawaited(_feedback.prepare());
    if (_reduceMotion && _movementController.isAnimating) {
      _movementController.value = 1;
    }
    _feedbackWrites = _feedbackWrites.then((_) async {
      try {
        await _feedbackStore.save(value);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game feedback settings could not be saved.'),
            ),
          );
        }
      }
    });
  }

  void _playFeedback(MatchFeedbackCue cue, {int pitchBand = 0}) {
    if (_isAppResumed) {
      unawaited(
        _feedback.play(cue, _feedbackPreferences, pitchBand: pitchBand),
      );
    }
  }

  MatchMovePresentationPlan? _landingPlan;
  MatchMovePresentationPlan? _lastLandingPlan;
  int _landingSequence = 0;

  @override
  void initState() {
    super.initState();
    _social.addListener(_onSocialFeedback);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadFeedbackPreferences());
    if (_game.diceValue != null) {
      // A saved roll is already accepted by the engine. Complete its
      // presentation callback for human and AI seats alike: a restored human
      // roll with no legal move must not become permanently stranded.
      _animations.restorePendingDiceRoll();
    }
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    // Treat the initial detached/null state as active until the first
    // lifecycle notification. This also keeps widget-test bindings usable.
    _isAppResumed = lifecycleState == null ||
        lifecycleState == AppLifecycleState.resumed ||
        lifecycleState == AppLifecycleState.detached;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_persistMatch());
      if (_isDiceAnimating) {
        _handleDiceAnimationComplete();
      } else {
        _scheduleAiTurn();
      }
    });
  }

  void _onSocialFeedback() {
    if (mounted) setState(() {});
  }

  double get _captureShake {
    if (_reduceMotion || _animations.captures.isEmpty) return 0;
    final t = (_animations.elapsedMs - _animations.approachMs) /
        MatchAnimationLifecycle.impactMs;
    return t <= 0 || t >= 1 ? 0 : math.sin(t * 4 * math.pi) * (1 - t) * 2;
  }

  int _retreatBeat = -1;
  int _hopBeat = -1;

  void _handleMovementTick() {
    if (_reduceMotion &&
        _movementController.isAnimating &&
        _movementController.value < 1) {
      _movementController.value = 1;
      return;
    }
    if (mounted && _animations.pawn.pawnIndex != null) {
      final steps =
          _animations.pawn.endProgress - _animations.pawn.startProgress;
      if (steps > 0 && _animations.approach < 1) {
        final beat = (_animations.approach * steps).floor().clamp(0, steps - 1);
        if (beat != _hopBeat) {
          _hopBeat = beat;
          _playFeedback(MatchFeedbackCue.hop);
        }
      }
      if (_animations.captures.isNotEmpty &&
          !_reduceMotion &&
          _animations.elapsedMs >= _animations.approachMs) {
        final sinceImpact = _animations.elapsedMs - _animations.approachMs;
        final beat = sinceImpact < MatchAnimationLifecycle.impactMs
            ? 0
            : 1 +
                ((sinceImpact - MatchAnimationLifecycle.impactMs) ~/
                    MatchAnimationLifecycle.retreatStepMs);
        if (beat != _retreatBeat) {
          if (_retreatBeat < 0) {
            _playFeedback(MatchFeedbackCue.capture);
            _lastLandingPlan = _landingPlan;
            _landingSequence++;
          } else if (_movementController.value < 1) {
            final progress = (sinceImpact - MatchAnimationLifecycle.impactMs) /
                (_movementController.duration!.inMilliseconds -
                    _animations.approachMs -
                    MatchAnimationLifecycle.impactMs);
            _playFeedback(
              MatchFeedbackCue.retreatStep,
              pitchBand: (5 * progress).floor(),
            );
          }
          _retreatBeat = beat;
        }
      }
    }
  }

  void _handleMovementStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _animations.completePawnMovement();
      _matchController.turns.completeMovement();
      final completedPlan = _landingPlan;
      if (completedPlan != null) {
        _playFeedback(
          completedPlan.gameCompleted
              ? MatchFeedbackCue.finish
              : completedPlan.hasCapture
                  ? MatchFeedbackCue.yard
                  : completedPlan.endProgress <=
                              BoardGeometry.playerTrackLength &&
                          BoardGeometry.safeTrackCells.contains(
                            BoardGeometry.physicalTrackCell(
                              completedPlan.player,
                              completedPlan.endProgress,
                            ),
                          )
                      ? MatchFeedbackCue.safeArrival
                      : MatchFeedbackCue.land,
        );
      }
      setState(() {
        _landingPlan = null;
        if (completedPlan != null && _retreatBeat < 0) {
          _lastLandingPlan = completedPlan;
          _landingSequence++;
        }
      });
      _scheduleAiTurn();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (!_isAppResumed) {
      // Never execute an automatic pawn move or pass while backgrounded.
      _turnResolution.cancel();
      if (mounted) setState(() {});
      unawaited(_persistMatch());
      return;
    }
    if (mounted) setState(() {});
    _resumeAcceptedTurn();
  }

  void _resumeAcceptedTurn() {
    if (!_canAct) return;
    // A paused dice widget may never send its animation-complete callback.
    // Resume the already accepted result without generating another roll.
    if (_game.diceValue != null && !_movementController.isAnimating) {
      _animations.resumePendingDiceResult();
      _handleDiceAnimationComplete();
      return;
    }
    // The Flutter ticker resumes an in-flight pawn movement automatically.
    if (!_isDiceAnimating && !_movementController.isAnimating) {
      _scheduleAiTurn();
    }
  }

  MatchCommandResult _applyCommand(MatchCommand command) {
    final result = _matchController.execute(command);
    if (!result.accepted) {
      debugPrint(
        'Rejected match command ${command.commandId}: '
        '${result.rejectionReason?.name} (${result.message})',
      );
    }
    if (result.accepted) {
      unawaited(_persistMatch());
    }
    return result;
  }

  Future<void> _persistMatch() {
    // Serialize writes so a slower earlier preference write can never
    // overwrite a newer accepted game state.
    final snapshot = SavedMatch(
      game: _game,
      aiPlayers: _aiPlayers,
      aiSeed: widget.aiSeed,
      aiDifficulty: widget.aiDifficulty,
      profiles: _profiles,
    );
    return _persistence.persist(snapshot);
  }

  @override
  void dispose() {
    unawaited(_feedback.dispose());
    _social.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _turns.dispose();
    unawaited(_persistMatch());
    _animations.dispose();
    _matchController.dispose();
    super.dispose();
  }

  void _scheduleAiTurn() => _turns.scheduleAi();

  bool _roll() => _turns.roll();

  void _presentAcceptedRoll(LudoGame rolled) {
    _playFeedback(MatchFeedbackCue.roll);
    setState(
      () => _animations.presentAcceptedRoll(
        hasDiceResult: true,
        value: rolled.events.whereType<DiceRolled>().single.value,
      ),
    );
  }

  void _showConsecutiveSixPenalty() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: Key('consecutive_six_penalty'),
        content: Text('Three 6s! Turn passed'),
        duration: Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF211A0D),
      ),
    );
  }

  void _handleDiceAnimationComplete() => _turns.completeDice();

  void _showInvalidMoveFeedback(int pawnIndex) {
    final evaluation = _game.evaluatePawnMove(pawnIndex);
    if (evaluation is! InvalidMove || !mounted) return;
    _shakeKeys['${_game.activePlayer.name}-$pawnIndex']
        ?.currentState
        ?.triggerShake();
    _playFeedback(MatchFeedbackCue.invalid);
    final message = MatchFxListener.invalidMoveMessage(evaluation.reason);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('invalid_move_feedback'),
        content: Text(message),
        duration: const Duration(milliseconds: 1300),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF211A0D),
      ),
    );
  }

  void _move(int pawnIndex) => _turns.move(pawnIndex);

  void _presentAcceptedMove(
    LudoGame before,
    int pawnIndex,
    List<LudoGameEvent> events,
  ) {
    final reduceMotion = _reduceMotion;
    // Authoritative movement and feedback are projected from accepted events.
    // The UI must not recalculate capture or bonus rules from pawn snapshots.
    final plan = MatchMovePresentationPlan.fromEvents(
      events: events,
      isTeamUp: _game.configuration.isTeamUp,
      player: before.activePlayer,
      pawnIndex: pawnIndex,
    );
    setState(() {
      _selectedPawnIndex = null;
      _landingPlan = plan;
      _retreatBeat = -1;
      _animations.configurePawnMovement(
        color: plan.player,
        pawnIndex: plan.pawnIndex,
        startProgress: plan.startProgress,
        endProgress: plan.endProgress,
        stepCount: plan.stepCount,
        retreats: {
          for (final event in events)
            if (event is PawnCaptured)
              (event.victim, event.pawnIndex): before.players
                  .firstWhere((p) => p.color == event.victim)
                  .pawnProgress[event.pawnIndex],
          for (final event in events.whereType<TeamPawnCaptured>())
            (event.victim, event.pawnIndex): before.players
                .firstWhere((p) => p.color == event.victim)
                .pawnProgress[event.pawnIndex],
        },
        reduceMotion: reduceMotion,
        feedback: plan.feedback,
      );
    });
    _hopBeat = -1;
    _animations.startPawnMovement();
  }

  String get _statusText {
    if (_game.winner != null && !_movementController.isAnimating) {
      final winner = _profileFor(_game.winner!);
      final label = winner.displayName == winner.color.name.toUpperCase()
          ? winner.displayName
          : '${winner.displayName} (${winner.color.name.toUpperCase()})';
      if (_game.winningTeam != null) {
        return 'TEAM ${_game.winningTeam!.name.toUpperCase()} WINS · ${winner.displayName}';
      }
      return '$label WINS';
    }
    if (_game.configuration.isTeamUp) {
      final name = _profileFor(_presentedPlayer).displayName;
      return '$name · TEAM ${TeamUpPolicy.teamFor(_game.activePlayer).name.toUpperCase()}';
    }
    return _aiPlayers.contains(_presentedPlayer)
        ? '${_presentedPlayer.name.toUpperCase()} · AI TURN'
        : '${_presentedPlayer.name.toUpperCase()} · YOUR TURN';
  }

  String get _actionInstruction {
    if (!_boardReady) return 'Preparing the board';
    if (_movementController.isAnimating) return 'Pawn moving';
    if (_game.winner != null) return 'Match finished';
    if (_isDiceAnimating) return 'Rolling dice';
    if (_turnResolution.isPending) {
      return _game.legalPawnIndices().isEmpty ? 'No moves' : 'Pawn moving';
    }
    if (_aiPlayers.contains(_game.activePlayer)) return 'AI thinking';
    return _game.diceValue == null ? 'Roll dice' : 'Choose a pawn';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_requestExit());
      },
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: _reduceMotion),
        child: RepaintBoundary(
          key: const Key('match_screen_capture'),
          child: Scaffold(
            backgroundColor: const Color(0xFF080808),
            body: RoyalBackdrop(
              child: SafeArea(
                child: GameBoardScaffold(
                  game: _game,
                  profiles: _profiles,
                  showProfiles: widget.showDynamicProfiles,
                  onExit: _requestExit,
                  teamProgress: _game.configuration.isTeamUp
                      ? TeamProgressPanel(game: _game, profiles: _profiles)
                      : null,
                  teamProgressHeight: () {
                    final scaled = MediaQuery.textScalerOf(context).scale(14);
                    final badge = (scaled * 1.2 * (scaled > 18 ? 1 : 2) + 8)
                        .clamp(40.0, double.infinity);
                    return badge +
                        (_game.scheduledPlayer == _game.activePlayer
                            ? 0
                            : MediaQuery.textScalerOf(context).scale(11) * 1.5 +
                                2);
                  }(),
                  reaction: const SizedBox.shrink(),
                  onPlayerChat: _showPlayerChat,
                  onPlayerEmoji: _showPlayerReactions,
                  social: _social,
                  presentedPlayer: _presentedPlayer,
                  noMovesPlayer: _turnResolution.isPending &&
                          _game.legalPawnIndices().isEmpty
                      ? _game.activePlayer
                      : null,
                  thinkingPlayer: _actionInstruction == 'AI thinking'
                      ? _game.activePlayer
                      : null,
                  dice: SizedBox(
                    key: const Key('roll_dice'),
                    width: 88,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedAlign(
                          duration: _reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          alignment: switch (
                              _landingPlan?.player ?? _game.activePlayer) {
                            PlayerColor.orange => Alignment.topLeft,
                            PlayerColor.green => Alignment.topRight,
                            PlayerColor.magenta => Alignment.bottomRight,
                            PlayerColor.blue => Alignment.bottomLeft,
                          },
                          child: ExcludeSemantics(
                            child: Icon(
                              switch (
                                  _landingPlan?.player ?? _game.activePlayer) {
                                PlayerColor.orange => Icons.north_west,
                                PlayerColor.green => Icons.north_east,
                                PlayerColor.magenta => Icons.south_east,
                                PlayerColor.blue => Icons.south_west,
                              },
                              size: 16,
                              color: const Color(0xFFFFD36B),
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          key: ValueKey(_actionInstruction == 'No legal move'),
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 550),
                          builder: (context, t, child) => Transform.translate(
                            offset: Offset(
                              !_reduceMotion &&
                                      _actionInstruction == 'No legal move'
                                  ? 3 * math.sin(t * math.pi * 6) * (1 - t)
                                  : 0,
                              0,
                            ),
                            child: child,
                          ),
                          child: LuxuryDiceButton(
                            key: const Key('animated_dice'),
                            size: 64,
                            visualScale: .88,
                            targetValue: _isDiceAnimating
                                ? _animations.presentedDiceValue ??
                                    _game.diceValue
                                : _game.diceValue,
                            rollId: _diceRollId,
                            canRoll: _canAct &&
                                !_aiPlayers.contains(_game.activePlayer) &&
                                _game.diceValue == null &&
                                !_isDiceAnimating &&
                                !_movementController.isAnimating &&
                                _game.winner == null,
                            isWaitingForRoll: _canAct &&
                                _game.diceValue == null &&
                                _game.winner == null &&
                                !_movementController.isAnimating,
                            onRollRequested: _roll,
                            onAnimationComplete: _handleDiceAnimationComplete,
                          ),
                        ),
                      ],
                    ),
                  ),
                  result: !_boardReady ||
                          _game.winner == null ||
                          _movementController.isAnimating
                      ? null
                      : MatchResultPresentation(onRematch: _restartMatch),
                  status: Semantics(
                    key: const Key('turn_status'),
                    liveRegion: true,
                    label: _boardReady
                        ? '$_statusText. $_actionInstruction'
                        : 'Preparing the board',
                    child: Center(
                      child: Text(
                        !_boardReady
                            ? 'Preparing board'
                            : _game.winner != null &&
                                    !_movementController.isAnimating
                                ? _statusText
                                : '$_actionInstruction · ${_profileFor(_movementController.isAnimating && _landingPlan != null ? _landingPlan!.player : _presentedPlayer).displayName}',
                        key: const Key('match_action_instruction'),
                        textAlign: TextAlign.center,
                        style: AppTypography.status,
                      ),
                    ),
                  ),
                  utilities: MatchUtilityBar(
                    onChat: _showLocalChat,
                    onMore: _showMoreMenu,
                  ),
                  boardBuilder: (context, scale) => AnimatedBuilder(
                    animation: _boardMotion,
                    builder: (_, __) => Transform.translate(
                      offset: Offset(_captureShake, 0),
                      child: CachedLudoBoard(
                        image: widget.boardImage,
                        onReadinessChanged: _onBoardReadinessChanged,
                        canvasScale: scale,
                        overlays: [
                          const MatchBoardFocusFrame(),
                          const MatchSafeStarLayer(),
                          Positioned.fill(
                            child: MatchPawnLayer(
                              game: _game,
                              animations: _animations,
                              canvasScale: scale,
                              isTurnResolutionPending:
                                  _turnResolution.isPending,
                              aiPlayers: _aiPlayers,
                              shakeKeys: _shakeKeys,
                              reduceMotion: _reduceMotion,
                              lastLandingPlan: _lastLandingPlan,
                              landingSequence: _landingSequence,
                              onMove: _selectOrMovePawn,
                              onInvalidMove: _showInvalidMoveFeedback,
                            ),
                          ),
                          if (_landingSequence > 0 && _lastLandingPlan != null)
                            MatchLandingCelebration(
                              key: ValueKey(_landingSequence),
                              plan: _lastLandingPlan!,
                            ),
                          if (_lastLandingPlan?.feedback
                              case final String message)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: Center(
                                  child: TweenAnimationBuilder<double>(
                                    key: ValueKey(
                                      'event-$_landingSequence',
                                    ),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(
                                      milliseconds: 1500,
                                    ),
                                    builder: (context, progress, child) =>
                                        Opacity(
                                      opacity: 1 -
                                          ((progress - .8) * 5)
                                              .clamp(0.0, 1.0)
                                              .toDouble(),
                                      child: child,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xDD211A0D),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 16,
                                        ),
                                        child: Text(message),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (_selectedPawnIndex != null)
                            MatchDestinationPreview(
                              game: _game,
                              selectedPawnIndex: _selectedPawnIndex!,
                              animation: _previewController,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestExit() async {
    if (!mounted || _exitDialogOpen || _allowExit) return;
    setState(() => _exitDialogOpen = true);
    _aiScheduler.cancel();
    _turnResolution.cancel();
    var saved = false;
    try {
      await _persistMatch().timeout(const Duration(seconds: 3));
      saved = _persistence.lastSaveSucceeded == true;
    } catch (_) {
      // A slow platform store must not trap navigation. Its queued write can
      // still finish; never promise recovery until it has actually succeeded.
    }
    if (!mounted) return;
    final confirmed = await MatchDialogs.confirmExit(context, saved: saved);
    if (!mounted) return;
    if (confirmed == true) {
      setState(() => _allowExit = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _exitDialogOpen = false);
    _resumeAcceptedTurn();
  }

  void _showLocalChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF17120B),
      builder: (context) => LocalMatchChatSheet(
        onReaction: _displayReaction,
      ),
    );
  }

  void _displayReaction(String reaction) =>
      _social.show(_game.activePlayer, reaction);

  void _showPlayerChat(PlayerColor player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF12121A),
      builder: (_) => LocalMatchChatSheet(
        profileName: _profileFor(player).displayName,
        onMessage: (text) => _social.show(player, text),
      ),
    );
  }

  void _showPlayerReactions(PlayerColor player) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121A),
      builder: (pickerContext) => MatchReactionPicker(
        onReaction: (reaction) {
          Navigator.of(pickerContext).pop();
          _social.show(player, reaction);
        },
      ),
    );
  }

  void _showMoreMenu() {
    MatchDialogs.showMoreMenu(context).then((action) {
      if (!mounted) return;
      if (action == 'rules') {
        final profile = _game.ruleProfile;
        final summary =
            '${profile.id == 'ludo-lovers-current' && profile.version == 1 ? 'Legacy local rules retained for this saved match.' : ModeRegistry.definition(_game.configuration.mode).description}\n\n'
            'Profile: ${profile.id}@${profile.version}. Exact finish required.\n'
            'Bonus on six: ${profile.extraTurnOnSix ? 'yes' : 'no'}; '
            'capture: ${profile.extraTurnOnCapture ? 'yes' : 'no'}; '
            'finish: ${profile.extraTurnOnFinish ? 'yes' : 'no'}.\n'
            'Third-six forfeiture: ${profile.threeConsecutiveSixesPenalty ? 'yes' : 'no'}.\n'
            '${_game.configuration.isTeamUp ? 'All eight team pawns must finish. Friendly losses do not earn capture bonuses.' : 'Finish ${_game.configuration.finishTarget} pawns to win.'}';
        showDialog<void>(
          context: context,
          builder: (dialog) => Theme(
            data: ThemeData.dark(),
            child: AlertDialog(
              title: const Text('Match rules'),
              content: SingleChildScrollView(child: Text(summary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop(),
                  child: const Text('CLOSE'),
                ),
              ],
            ),
          ),
        );
      } else if (action == 'feedback') {
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: const Color(0xFF17120B),
          builder: (_) => Theme(
            data: ThemeData.dark(),
            child: MatchFeedbackSettings(
              value: _feedbackPreferences,
              onChanged: _changeFeedbackPreferences,
            ),
          ),
        );
      } else if (action == 'restart') {
        _confirmRestart();
      } else if (action == 'exit') {
        unawaited(_requestExit());
      }
    });
  }

  Future<void> _confirmRestart() async {
    final confirmed = await MatchDialogs.confirmRestart(context);
    if (confirmed == true && mounted) _restartMatch();
  }

  void _restartMatch() {
    final previousFeedback = _feedback;
    _feedback = MatchFeedback();
    unawaited(previousFeedback.dispose());
    if (_feedbackPreferences.sound) unawaited(_feedback.prepare());
    _social.clear();
    _aiScheduler.cancel();
    _turnResolution.cancel();
    _animations.resetForNewMatch();
    setState(() {
      _landingPlan = null;
      _lastLandingPlan = null;
      _landingSequence = 0;
      _matchController.reset(
        _newMatchSession(
          LudoGame.initial(
            ruleProfile: _game.ruleProfile,
            configuration: _game.configuration,
          ),
        ),
      );
      _selectedPawnIndex = null;
    });
    unawaited(_persistMatch());
    _scheduleAiTurn();
  }

  void _selectOrMovePawn(int pawnIndex) {
    // A tap on a legal pawn commits the move immediately. The dice has
    // already been accepted by MatchSession, so a second confirmation tap
    // adds friction without improving rule validation.
    if (!_canAct ||
        _turnResolution.isPending ||
        _isDiceAnimating ||
        _movementController.isAnimating ||
        !_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    setState(() => _selectedPawnIndex = null);
    _previewController.stop();
    _move(pawnIndex);
  }
}
