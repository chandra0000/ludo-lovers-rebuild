import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/application/match_session.dart';
import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/persistence/saved_match_store.dart';
import '../../game/presentation/destination_preview_painter.dart';
import '../../game/presentation/glassy_pawn.dart';
import '../../game/presentation/player_color_theme.dart';
import '../../game/presentation/shake_feedback_wrapper.dart';

import 'game/systems/pawn_animator.dart';
import 'game/systems/pawn_layout_solver.dart';
import 'dice_control_dock.dart';
import 'local_match_chat_sheet.dart';
import 'match_board_artwork.dart';
import 'match_board_focus_frame.dart';
import 'match_brand_mark.dart';
import 'match_board_viewport.dart';
import 'match_command_controller.dart';
import 'match_move_presentation_plan.dart';
import 'match_ai_turn_policy.dart';
import 'match_ai_scheduler.dart';
import 'match_animation_lifecycle.dart';
import 'match_turn_resolution_controller.dart';
import 'match_persistence_controller.dart';
import 'match_fx_listener.dart';
import 'match_dialogs.dart';
import 'match_hud_overlay.dart';
import 'match_profiles_layer.dart';
import 'match_reaction_controls.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    this.rollDice,
    this.initialGame,
    this.aiPlayers = const {},
    this.aiSeed = 1,
    this.aiDifficulty = LudoAiDifficulty.medium,
    this.profiles,
    this.showDynamicProfiles = true,
  });

  @visibleForTesting
  final int Function()? rollDice;

  @visibleForTesting
  final LudoGame? initialGame;

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
  late final MatchCommandController _matchController = MatchCommandController(
    _newMatchSession(widget.initialGame ?? LudoGame.initial()),
  );

  MatchSession _newMatchSession(LudoGame game) {
    final matchId =
        'local-${widget.aiSeed}-${DateTime.now().microsecondsSinceEpoch}';
    return MatchSession.local(matchId: matchId, game: game);
  }

  MatchSession get _session => _matchController.session;
  LudoGame get _game => _matchController.game;
  late final math.Random _random = math.Random(widget.aiSeed);
  final SeededLudoAi _ai = const SeededLudoAi();
  final MatchAiTurnPolicy _aiTurnPolicy = const MatchAiTurnPolicy();
  final MatchAiScheduler _aiScheduler = MatchAiScheduler();
  bool _isAppResumed = true;
  final MatchPersistenceController _persistence = MatchPersistenceController();
  late final MatchAnimationLifecycle _animations = MatchAnimationLifecycle(
    vsync: this,
    onMovementTick: _handleMovementTick,
    onMovementStatus: _handleMovementStatus,
  );
  AnimationController get _movementController => _animations.movement;
  AnimationController get _previewController => _animations.preview;
  bool get _isDiceAnimating => _animations.isDiceAnimating;
  int get _diceRollId => _animations.diceRollId;
  final MatchTurnResolutionController _turnResolution =
      MatchTurnResolutionController();
  final Map<String, GlobalKey<ShakeFeedbackWrapperState>> _shakeKeys = {};
  int? _selectedPawnIndex;
  String? _activeReaction;
  Timer? _reactionDismissTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_game.diceValue != null &&
        widget.aiPlayers.contains(_game.activePlayer)) {
      // A saved AI roll is already accepted by the engine. Complete its
      // presentation callback on restore so the AI cannot become stranded.
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

  void _handleMovementTick() {
    if (mounted && _animations.pawn.pawnIndex != null) {
      setState(() {});
    }
  }

  void _handleMovementStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      final feedback = _animations.completePawnMovement();
      setState(() {});
      _scheduleAiTurn();
      if (feedback != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('move_feedback'),
            content: Text(feedback),
            duration: const Duration(milliseconds: 1600),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF211A0D),
          ),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (!_isAppResumed) {
      // Never execute an automatic pawn move or pass while backgrounded.
      final hadPendingTurn = _turnResolution.isPending;
      _turnResolution.cancel();
      if (hadPendingTurn) {
        setState(() {});
      }
      unawaited(_persistMatch());
      return;
    }
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
    return result;
  }

  bool _executeCommand(MatchCommand command) => _applyCommand(command).accepted;

  Future<void> _persistMatch() {
    // Serialize writes so a slower earlier preference write can never
    // overwrite a newer accepted game state.
    final snapshot = SavedMatch(
      game: _game,
      aiPlayers: widget.aiPlayers,
      aiSeed: widget.aiSeed,
      aiDifficulty: widget.aiDifficulty,
    );
    return _persistence.persist(snapshot);
  }

  @override
  void dispose() {
    _reactionDismissTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _aiScheduler.cancel();
    _turnResolution.cancel();
    unawaited(_persistMatch());
    _animations.dispose();
    super.dispose();
  }

  void _scheduleAiTurn() {
    if (!_aiTurnPolicy.canSchedule(
      session: _session,
      aiPlayers: widget.aiPlayers,
      isAppResumed: _isAppResumed,
      isScheduled: _aiScheduler.isScheduled,
      isMovementAnimating: _movementController.isAnimating,
      isDiceAnimating: _isDiceAnimating,
    )) {
      return;
    }
    _aiScheduler.schedule(() {
      if (!mounted ||
          !_isAppResumed ||
          !widget.aiPlayers.contains(_game.activePlayer) ||
          _game.winner != null ||
          _game.diceValue != null ||
          _movementController.isAnimating ||
          _isDiceAnimating) {
        return;
      }
      final command = _aiTurnPolicy.createRoll(
        session: _session,
        aiSeed: widget.aiSeed,
      );
      if (!_executeCommand(command)) return;
      final rolled = _game;
      setState(() {
        _animations.presentAcceptedRoll(
          hasDiceResult: rolled.diceValue != null,
        );
      });
      unawaited(_persistMatch());
      // A third-six penalty is an accepted turn transition, not a dice
      // result to animate. Continue immediately if the next seat is AI.
      if (rolled.diceValue == null) {
        _showConsecutiveSixPenalty();
        _scheduleAiTurn();
      }
    });
  }

  bool _roll({required bool isAi}) {
    // The game engine remains authoritative; UI animation only presents
    // the accepted result and cannot alter rules or generate another value.
    if (_game.diceValue != null ||
        _game.winner != null ||
        _movementController.isAnimating ||
        _isDiceAnimating) {
      return false;
    }
    final value = isAi
        ? math.Random(widget.aiSeed ^ _game.stateVersion).nextInt(6) + 1
        : widget.rollDice?.call() ?? _random.nextInt(6) + 1;
    final command = _matchController.buildRoll(
      value: value,
      isAi: isAi,
      aiSeed: widget.aiSeed,
    );
    if (!_executeCommand(command)) return false;
    final rolled = _game;
    final wasPenalized =
        rolled.events.whereType<ConsecutiveSixPenalty>().isNotEmpty;
    setState(() {
      _animations.presentAcceptedRoll(
        hasDiceResult: rolled.diceValue != null,
      );
    });
    unawaited(_persistMatch());
    if (wasPenalized) {
      _showConsecutiveSixPenalty();
      _scheduleAiTurn();
    }
    return true;
  }

  void _showConsecutiveSixPenalty() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: Key('consecutive_six_penalty'),
        content: Text('THREE SIXES — TURN PASSED'),
        duration: Duration(milliseconds: 1600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF211A0D),
      ),
    );
  }

  void _handleDiceAnimationComplete() {
    if (!mounted || !_isAppResumed || !_isDiceAnimating) return;
    final legal = _game.legalPawnIndices();
    setState(_animations.completeDiceRoll);

    if (_game.diceValue == null) {
      // Defensive recovery: a penalty or restored transition may already
      // have advanced the turn without leaving a pending dice result.
      _scheduleAiTurn();
      return;
    }
    if (legal.isEmpty) {
      _turnResolution.schedulePass(
        matchId: _session.matchId,
        stateVersion: _game.stateVersion,
        currentMatchId: () => _session.matchId,
        currentStateVersion: () => _game.stateVersion,
        canExecute: () => mounted && _isAppResumed && _game.diceValue != null,
        onReady: () {
          final command = _matchController.buildPass();
          final accepted = _executeCommand(command);
          setState(() {});
          if (!accepted) return;
          unawaited(_persistMatch());
          _scheduleAiTurn();
        },
      );
      setState(() {});
      return;
    }

    final isAiTurn = widget.aiPlayers.contains(_game.activePlayer);
    final selected = isAiTurn
        ? _ai.choosePawn(
            _game,
            seed: widget.aiSeed ^ _game.stateVersion,
            difficulty: widget.aiDifficulty,
          )
        : legal.length == 1
            ? legal.single
            : null;
    if (selected != null) {
      _turnResolution.schedulePawn(
        matchId: _session.matchId,
        stateVersion: _game.stateVersion,
        currentMatchId: () => _session.matchId,
        currentStateVersion: () => _game.stateVersion,
        canExecute: () =>
            mounted &&
            _isAppResumed &&
            _game.diceValue != null &&
            !_movementController.isAnimating,
        onReady: () {
          setState(() {});
          _move(selected);
        },
      );
      setState(() {});
    }
  }

  void _showInvalidMoveFeedback(int pawnIndex) {
    final evaluation = _game.evaluatePawnMove(pawnIndex);
    if (evaluation is! InvalidMove || !mounted) return;
    _shakeKeys['${_game.activePlayer.name}-$pawnIndex']
        ?.currentState
        ?.triggerShake();
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

  void _move(int pawnIndex) {
    if (_isDiceAnimating ||
        _turnResolution.isPending ||
        !_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    final movingColor = _game.activePlayer;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final result = _applyCommand(_matchController.buildMove(pawnIndex));
    if (!result.accepted) return;

    // Authoritative movement and feedback are projected from accepted events.
    // The UI must not recalculate capture or bonus rules from pawn snapshots.
    final plan = MatchMovePresentationPlan.fromEvents(
      events: result.events,
      player: movingColor,
      pawnIndex: pawnIndex,
    );
    setState(() {
      _selectedPawnIndex = null;
      _animations.configurePawnMovement(
        color: plan.player,
        pawnIndex: plan.pawnIndex,
        startProgress: plan.startProgress,
        endProgress: plan.endProgress,
        stepCount: plan.stepCount,
        reduceMotion: reduceMotion,
        feedback: plan.feedback,
      );
    });
    unawaited(_persistMatch());
    _animations.startPawnMovement();
  }

  NormalizedBoardPoint _pawnPosition(
    PlayerColor color,
    int pawnIndex,
  ) {
    final player = _game.players.firstWhere((item) => item.color == color);
    return PawnAnimator.position(
      color: color,
      pawnIndex: pawnIndex,
      progress: player.pawnProgress[pawnIndex],
      isMoving: _animations.pawn.color == color &&
          _animations.pawn.pawnIndex == pawnIndex,
      startProgress: _animations.pawn.startProgress,
      endProgress: _animations.pawn.endProgress,
      animationValue: _movementController.value,
    );
  }

  String get _statusText {
    if (_game.winner != null) {
      return '${_game.winner!.name.toUpperCase()} WINS';
    }
    return widget.aiPlayers.contains(_game.activePlayer)
        ? '${_game.activePlayer.name.toUpperCase()} · AI TURN'
        : '${_game.activePlayer.name.toUpperCase()} · YOUR TURN';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const Key('match_screen_capture'),
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        body: SafeArea(
          child: MatchBoardViewport(
            builder: (context, scale) => Stack(
              children: [
                const Positioned.fill(
                  child: MatchBoardArtwork(),
                ),
                const MatchBoardFocusFrame(),
                const MatchBrandMark(),
                if (widget.showDynamicProfiles)
                  Positioned.fill(
                    child: MatchProfilesLayer(
                      profiles: widget.profiles ??
                          MatchPlayerProfile.local(
                            aiPlayers: widget.aiPlayers,
                          ),
                      activeColor: _game.activePlayer,
                    ),
                  ),
                ..._buildPawnsWithClusters(scale),
                if (_selectedPawnIndex != null) _buildDestinationPreview(),
                DiceControlDock(
                  targetValue: _game.diceValue,
                  rollId: _diceRollId,
                  canRoll: !widget.aiPlayers.contains(_game.activePlayer) &&
                      _game.diceValue == null &&
                      !_isDiceAnimating &&
                      !_movementController.isAnimating &&
                      _game.winner == null,
                  isWaitingForRoll: _game.diceValue == null &&
                      _game.winner == null &&
                      !_movementController.isAnimating,
                  onRollRequested: () {
                    if (widget.aiPlayers.contains(_game.activePlayer)) {
                      return;
                    }
                    _roll(isAi: false);
                  },
                  onAnimationComplete: _handleDiceAnimationComplete,
                ),
                MatchHudOverlay(
                  statusText: _statusText,
                  activePlayer: _game.activePlayer,
                ),
                MatchReactionToast(reaction: _activeReaction),
                Positioned(
                  left: 12,
                  top: 12,
                  child: IconButton(
                    key: const Key('exit_match'),
                    tooltip: 'Exit match',
                    constraints: const BoxConstraints.tightFor(
                      width: 72,
                      height: 72,
                    ),
                    padding: EdgeInsets.zero,
                    iconSize: 36,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFFFC857),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 928,
                  width: 84,
                  height: 84,
                  child: Semantics(
                    button: true,
                    label: 'Chat',
                    hint: 'Open local chat and emoji reactions.',
                    child: GestureDetector(
                      key: const Key('chat_button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _showLocalChat,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xE6211A0D),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chat_bubble_outline,
                            size: 32,
                            color: Color(0xFFFFD36B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                MatchReactionButton(onPressed: _showQuickReactions),
                Positioned(
                  right: 12,
                  top: 928,
                  width: 84,
                  height: 84,
                  child: Semantics(
                    button: true,
                    label: 'More options',
                    child: GestureDetector(
                      key: const Key('more_button'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _showMoreMenu,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xE6211A0D),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.more_horiz,
                            size: 32,
                            color: Color(0xFFFFD36B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_game.winner != null)
                  Positioned(
                    left: 150,
                    top: 480,
                    width: 276,
                    height: 80,
                    child: Center(
                      child: FilledButton(
                        onPressed: _restartMatch,
                        child: const Text('PLAY AGAIN'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _displayReaction(String reaction) {
    if (!mounted) return;
    _reactionDismissTimer?.cancel();
    setState(() => _activeReaction = reaction);
    _reactionDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _activeReaction = null);
      }
    });
  }

  void _showQuickReactions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17120B),
      builder: (pickerContext) => MatchReactionPicker(
        onReaction: (reaction) {
          Navigator.of(pickerContext).pop();
          _displayReaction(reaction);
        },
      ),
    );
  }

  void _showMoreMenu() {
    MatchDialogs.showMoreMenu(context).then((action) {
      if (!mounted) return;
      if (action == 'restart') {
        _confirmRestart();
      } else if (action == 'exit') {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _confirmRestart() async {
    final confirmed = await MatchDialogs.confirmRestart(context);
    if (confirmed == true && mounted) _restartMatch();
  }

  void _restartMatch() {
    _aiScheduler.cancel();
    _turnResolution.cancel();
    _animations.resetForNewMatch();
    setState(() {
      _matchController.reset(_newMatchSession(LudoGame.initial()));
      _selectedPawnIndex = null;
    });
    unawaited(_persistMatch());
    _scheduleAiTurn();
  }

  void _selectOrMovePawn(int pawnIndex) {
    // A tap on a legal pawn commits the move immediately. The dice has
    // already been accepted by MatchSession, so a second confirmation tap
    // adds friction without improving rule validation.
    if (_turnResolution.isPending ||
        _isDiceAnimating ||
        _movementController.isAnimating ||
        !_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    setState(() => _selectedPawnIndex = null);
    _previewController.stop();
    _move(pawnIndex);
  }

  Widget _buildDestinationPreview() {
    final pawnIndex = _selectedPawnIndex!;
    final roll = _game.diceValue!;
    final progress = _game.currentPlayer.pawnProgress[pawnIndex];
    final target = progress == -1 ? 0 : progress + roll;
    final point = BoardGeometry.canvasPosition(
      BoardGeometry.normalizedPosition(_game.activePlayer, target, pawnIndex),
    );
    final evaluation = _game.evaluatePawnMove(pawnIndex);
    var type = DestinationPreviewType.standard;
    if (evaluation is ValidMove && evaluation.isCapture) {
      type = DestinationPreviewType.capture;
    } else if (target < BoardGeometry.playerTrackLength) {
      final cell = BoardGeometry.physicalTrackCell(_game.activePlayer, target);
      final hasOpponent = _game.players.any(
        (player) =>
            player.color != _game.activePlayer &&
            player.pawnProgress.any(
              (opponentProgress) =>
                  opponentProgress >= 0 &&
                  opponentProgress < BoardGeometry.playerTrackLength &&
                  BoardGeometry.physicalTrackCell(
                        player.color,
                        opponentProgress,
                      ) ==
                      cell,
            ),
      );
      if (hasOpponent && BoardGeometry.safeTrackCells.contains(cell)) {
        type = DestinationPreviewType.safeCoexist;
      }
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _previewController,
          builder: (context, child) => CustomPaint(
            key: const Key('destination_preview'),
            painter: DestinationPreviewPainter(
              targetCenter: Offset(point.x, point.y),
              cellSize: 36,
              playerColor: _game.activePlayer.color,
              previewType: type,
              animationProgress: _previewController.value,
            ),
          ),
        ),
      ),
    );
  }

  void _handleStackTap(List<int> movablePawnIndices) {
    if (_selectedPawnIndex != null &&
        movablePawnIndices.contains(_selectedPawnIndex)) {
      _selectOrMovePawn(_selectedPawnIndex!);
      return;
    }
    if (movablePawnIndices.isEmpty) {
      return;
    }
    if (movablePawnIndices.length == 1) {
      _selectOrMovePawn(movablePawnIndices.single);
      return;
    }

    showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF17120B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CHOOSE A PAWN',
                style: TextStyle(
                  color: Color(0xFFFFC857),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              for (final index in movablePawnIndices)
                ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: _game.activePlayer.color,
                  ),
                  title: Text(
                    'Pawn ${index + 1}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFFC857),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(index),
                ),
            ],
          ),
        ),
      ),
    ).then((selectedIndex) {
      if (selectedIndex != null && mounted) {
        _selectOrMovePawn(selectedIndex);
      }
    });
  }

  List<Widget> _buildPawnsWithClusters(double canvasScale) {
    // Index players once per frame instead of searching for each pawn.
    final playersByColor = {
      for (final player in _game.players) player.color: player,
    };
    final clusters = <int, List<({PlayerColor color, int pawnIndex})>>{};
    for (final color in PlayerColor.turnOrder) {
      final player = playersByColor[color]!;
      for (var pawnIndex = 0;
          pawnIndex < player.pawnProgress.length;
          pawnIndex++) {
        final point = _pawnPosition(color, pawnIndex);
        final key = PawnLayoutSolver.clusterKey(point);
        clusters.putIfAbsent(key, () => []).add(
          (color: color, pawnIndex: pawnIndex),
        );
      }
    }
    for (final occupants in clusters.values) {
      occupants.sort((a, b) {
        final colorOrder = PlayerColor.turnOrder.indexOf(a.color).compareTo(
              PlayerColor.turnOrder.indexOf(b.color),
            );
        return colorOrder != 0
            ? colorOrder
            : a.pawnIndex.compareTo(b.pawnIndex);
      });
    }
    final legalIndices = _game.legalPawnIndices().toSet();
    return [
      for (final color in PlayerColor.turnOrder)
        for (var pawnIndex = 0; pawnIndex < 4; pawnIndex++)
          _buildPawn(
            color,
            pawnIndex,
            playersByColor[color]!,
            clusters,
            legalIndices,
            canvasScale,
          ),
    ];
  }

  Widget _buildPawn(
    PlayerColor color,
    int pawnIndex,
    LudoPlayer player,
    Map<int, List<({PlayerColor color, int pawnIndex})>> clusters,
    Set<int> legalIndices,
    double canvasScale,
  ) {
    final progress = player.pawnProgress[pawnIndex];
    final normalized = _pawnPosition(color, pawnIndex);
    final canvasPoint = BoardGeometry.canvasPosition(normalized);
    final occupants = clusters[PawnLayoutSolver.clusterKey(normalized)] ??
        [
          (color: color, pawnIndex: pawnIndex),
        ];
    final stackIndex = occupants.indexWhere(
      (item) => item.color == color && item.pawnIndex == pawnIndex,
    );
    final stacked = occupants.length > 1;
    final slot = PawnLayoutSolver.stackOffset(stackIndex, occupants.length);
    final visualOffset = Offset(slot.x, slot.y);
    final size = stacked ? 16.0 : (progress == -1 ? 30.0 : 27.0);
    final isHumanTurn =
        !widget.aiPlayers.contains(color) && color == _game.activePlayer;
    final canMove = !_isDiceAnimating &&
        !_movementController.isAnimating &&
        !_turnResolution.isPending &&
        isHumanTurn &&
        legalIndices.contains(pawnIndex);
    final canExplainInvalidMove = !_isDiceAnimating &&
        !_movementController.isAnimating &&
        !_turnResolution.isPending &&
        isHumanTurn &&
        _game.diceValue != null &&
        !legalIndices.contains(pawnIndex);
    final movableStackIndices = occupants
        .where(
          (item) =>
              item.color == _game.activePlayer &&
              legalIndices.contains(item.pawnIndex),
        )
        .map((item) => item.pawnIndex)
        .toList(growable: false);
    final stackTapIndex = occupants.indexWhere(
      (item) =>
          item.color == _game.activePlayer &&
          legalIndices.contains(item.pawnIndex),
    );
    final isStackTapTarget = stacked && stackIndex == stackTapIndex;
    final isCurrentPlayer = color == _game.activePlayer;
    final tapPosition = stacked
        ? Offset(canvasPoint.x, canvasPoint.y)
        : Offset(canvasPoint.x, canvasPoint.y) + visualOffset;

    // The canvas is scaled to fit the phone. Expand the design-space hitbox
    // inversely so its transformed physical bounds never fall below 44×48 dp.
    final hitTargetWidth = math.max(44.0, 44.0 / canvasScale);
    final hitTargetHeight = math.max(48.0, 48.0 / canvasScale);
    final shakeKey = _shakeKeys.putIfAbsent(
      '${color.name}-$pawnIndex',
      GlobalKey<ShakeFeedbackWrapperState>.new,
    );
    return Positioned(
      left: tapPosition.dx - hitTargetWidth / 2,
      top: tapPosition.dy - hitTargetHeight / 2,
      width: hitTargetWidth,
      height: hitTargetHeight,
      child: IgnorePointer(
        // Inactive/non-legal pawns must not cover a legal pawn's enlarged
        // touch target when adjacent cells overlap on compact screens.
        ignoring:
            stacked ? !isStackTapTarget : !canMove && !canExplainInvalidMove,
        child: Semantics(
          button: stacked ? isStackTapTarget : canMove || canExplainInvalidMove,
          label: stacked
              ? 'Choose a movable pawn from this shared cell'
              : '${color.name} pawn ${pawnIndex + 1}',
          value: progress == -1
              ? 'In yard'
              : progress == 56
                  ? 'Home'
                  : 'Progress $progress of 56',
          hint: stacked
              ? 'Double tap to choose which movable pawn to move.'
              : canMove
                  ? 'Double tap to move this pawn.'
                  : canExplainInvalidMove
                      ? 'Double tap to hear why this pawn cannot move.'
                      : widget.aiPlayers.contains(color)
                          ? 'Controlled by the AI opponent.'
                          : 'Not movable on this turn.',
          child: GestureDetector(
            key: Key('pawn_${color.name}_$pawnIndex'),
            behavior: HitTestBehavior.opaque,
            onTap: stacked
                ? (isStackTapTarget
                    ? () => _handleStackTap(movableStackIndices)
                    : null)
                : canMove
                    ? () => _selectOrMovePawn(pawnIndex)
                    : canExplainInvalidMove
                        ? () => _showInvalidMoveFeedback(pawnIndex)
                        : null,
            child: Center(
              child: Transform.translate(
                offset: visualOffset,
                child: ShakeFeedbackWrapper(
                  key: shakeKey,
                  child: AnimatedScale(
                    scale: canMove ? 1.12 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Transform.rotate(
                      angle: _animations.pawn.color == color &&
                              _animations.pawn.pawnIndex == pawnIndex
                          ? math.sin(_movementController.value * math.pi * 2) *
                              0.08
                          : 0,
                      child: GlassyPawn(
                        color: color.color,
                        size: size,
                        isCurrentPlayer: isCurrentPlayer,
                        isMovable: canMove,
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
}
