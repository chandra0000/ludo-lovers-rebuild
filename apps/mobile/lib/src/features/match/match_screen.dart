import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/persistence/saved_match_store.dart';

import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';
import '../../game/presentation/luxury_dice.dart';
import '../../game/presentation/glassy_pawn.dart';
import '../../game/presentation/shake_feedback_wrapper.dart';
import '../../game/presentation/destination_preview_painter.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({
    super.key,
    this.rollDice,
    this.initialGame,
    this.aiPlayers = const {},
    this.aiSeed = 1,
  });

  @visibleForTesting
  final int Function()? rollDice;

  @visibleForTesting
  final LudoGame? initialGame;

  final Set<PlayerColor> aiPlayers;
  final int aiSeed;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late LudoGame _game = widget.initialGame ?? LudoGame.initial();
  late final math.Random _random = math.Random(widget.aiSeed);
  final SeededLudoAi _ai = const SeededLudoAi();
  bool _aiTurnScheduled = false;
  bool _isDiceAnimating = false;
  bool _isAppResumed = true;
  final SavedMatchStore _savedMatchStore = const SavedMatchStore();
  Future<void> _persistenceQueue = Future<void>.value();
  int _diceRollId = 0;
  late final AnimationController _movementController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  )..addListener(_handleMovementTick)
      ..addStatusListener(_handleMovementStatus);
  PlayerColor? _movingColor;
  int? _movingPawnIndex;
  int _movementStartProgress = 0;
  int _movementEndProgress = 0;
  String? _pendingMoveFeedback;
  bool _isAutoMovePending = false;
  int _turnResolutionToken = 0;
  final Map<String, GlobalKey<ShakeFeedbackWrapperState>> _shakeKeys = {};
  int? _selectedPawnIndex;
  late final AnimationController _previewController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_game.diceValue != null &&
        widget.aiPlayers.contains(_game.activePlayer)) {
      // A saved AI roll is already accepted by the engine. Complete its
      // presentation callback on restore so the AI cannot become stranded.
      _isDiceAnimating = true;
      _diceRollId = 1;
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
    if (mounted && _movingPawnIndex != null) {
      setState(() {});
    }
  }

  void _handleMovementStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      final feedback = _pendingMoveFeedback;
      setState(() {
        _movingColor = null;
        _movingPawnIndex = null;
        _pendingMoveFeedback = null;
      });
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
      unawaited(_persistMatch());
      return;
    }
    // Flutter's ticker lifecycle handling pauses the in-flight visual
    // animation. Resume AI scheduling only after the app is foregrounded.
    if (!_isDiceAnimating && !_movementController.isAnimating) {
      _scheduleAiTurn();
    }
  }

  Future<void> _persistMatch() {
    // Serialize writes so a slower earlier preference write can never
    // overwrite a newer accepted game state.
    final snapshot = SavedMatch(
      game: _game,
      aiPlayers: widget.aiPlayers,
      aiSeed: widget.aiSeed,
    );
    _persistenceQueue = _persistenceQueue.then((_) async {
      try {
        await _savedMatchStore.save(snapshot);
      } catch (error) {
        debugPrint('Could not persist local match: $error');
      }
    });
    return _persistenceQueue;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistMatch());
    _movementController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  void _scheduleAiTurn() {
    if (!_isAppResumed ||
        !widget.aiPlayers.contains(_game.activePlayer) ||
        _game.winner != null ||
        _game.diceValue != null ||
        _aiTurnScheduled ||
        _movementController.isAnimating ||
        _isDiceAnimating) {
      return;
    }
    _aiTurnScheduled = true;
    unawaited(
      Future<void>.delayed(
        const Duration(milliseconds: 450),
        () {
          _aiTurnScheduled = false;
          if (!mounted ||
              !_isAppResumed ||
              !widget.aiPlayers.contains(_game.activePlayer) ||
              _game.winner != null ||
              _game.diceValue != null ||
              _movementController.isAnimating ||
              _isDiceAnimating) {
            return;
          }
          final rolled = _game.roll(
            math.Random(widget.aiSeed ^ _game.stateVersion).nextInt(6) + 1,
            expectedStateVersion: _game.stateVersion,
            commandId: 'ai-${widget.aiSeed}-${_game.stateVersion}-roll',
          );
          setState(() {
            _game = rolled;
            _isDiceAnimating = rolled.diceValue != null;
            if (rolled.diceValue != null) {
              _diceRollId++;
            }
          });
          unawaited(_persistMatch());
          // A third-six penalty is an accepted turn transition, not a dice
          // result to animate. Continue immediately if the next seat is AI.
          if (rolled.diceValue == null) {
            _showConsecutiveSixPenalty();
            _scheduleAiTurn();
          }
        },
      ),
    );
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
    final rolled = _game.roll(
      value,
      expectedStateVersion: _game.stateVersion,
      commandId: '${isAi ? 'ai-${widget.aiSeed}' : 'match'}-${_game.stateVersion}-roll',
    );
    final wasPenalized =
        rolled.events.whereType<ConsecutiveSixPenalty>().isNotEmpty;
    setState(() {
      _game = rolled;
      _isDiceAnimating = rolled.diceValue != null;
      if (rolled.diceValue != null) {
        _diceRollId++;
      }
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
    setState(() => _isDiceAnimating = false);

    if (_game.diceValue == null) {
      // Defensive recovery: a penalty or restored transition may already
      // have advanced the turn without leaving a pending dice result.
      _scheduleAiTurn();
      return;
    }
    if (legal.isEmpty) {
      final token = ++_turnResolutionToken;
      setState(() => _isAutoMovePending = true);
      unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () {
        if (!mounted || token != _turnResolutionToken || _game.diceValue == null) return;
        setState(() {
          _game = _game.passTurn(
            expectedStateVersion: _game.stateVersion,
            commandId: 'match-${_game.stateVersion}-pass',
          );
          _isAutoMovePending = false;
        });
        unawaited(_persistMatch());
        _scheduleAiTurn();
      }));
      return;
    }

    final isAiTurn = widget.aiPlayers.contains(_game.activePlayer);
    final selected = isAiTurn
        ? _ai.choosePawn(_game, seed: widget.aiSeed ^ _game.stateVersion)
        : legal.length == 1
            ? legal.single
            : null;
    if (selected != null) {
      final token = ++_turnResolutionToken;
      setState(() => _isAutoMovePending = true);
      unawaited(Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || token != _turnResolutionToken ||
            _game.diceValue == null || _movementController.isAnimating) return;
        setState(() => _isAutoMovePending = false);
        _move(selected);
      }));
    }
  }

  void _showInvalidMoveFeedback(int pawnIndex) {
    final evaluation = _game.evaluatePawnMove(pawnIndex);
    if (evaluation is! InvalidMove || !mounted) return;
    _shakeKeys['${_game.activePlayer.name}-$pawnIndex']?.currentState?.triggerShake();
    final message = switch (evaluation.reason) {
      MoveInvalidReason.pawnInYardNeedsSix => 'ROLL A SIX TO ENTER',
      MoveInvalidReason.overshootsHome => 'EXACT ROLL NEEDED TO FINISH',
      MoveInvalidReason.pathBlockedByBlockade => 'PATH BLOCKED BY A PAWN BLOCKADE',
      MoveInvalidReason.landingOnProtectedStack => 'THAT STACK IS PROTECTED',
      MoveInvalidReason.noPendingRoll => 'ROLL THE DICE FIRST',
      MoveInvalidReason.invalidPawnIndex => 'INVALID PAWN SELECTION',
    };
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
    if (_isDiceAnimating || _isAutoMovePending || !_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    final movingColor = _game.activePlayer;
    final player = _game.currentPlayer;
    final startProgress = player.pawnProgress[pawnIndex];
    final roll = _game.diceValue!;
    final endProgress = startProgress == -1 ? 0 : startProgress + roll;
    final stepCount = endProgress - startProgress;
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final nextGame = _game.movePawn(
      pawnIndex,
      expectedStateVersion: _game.stateVersion,
      commandId: 'match-${_game.stateVersion}-move-$pawnIndex',
    );
    var capturedCount = 0;
    for (final previousPlayer in _game.players) {
      if (previousPlayer.color == movingColor) {
        continue;
      }
      final nextPlayer = nextGame.players.firstWhere(
        (player) => player.color == previousPlayer.color,
      );
      for (var index = 0; index < previousPlayer.pawnProgress.length; index++) {
        if (previousPlayer.pawnProgress[index] >= 0 &&
            nextPlayer.pawnProgress[index] == -1) {
          capturedCount++;
        }
      }
    }
    final feedback = nextGame.winner != null
        ? '${movingColor.name.toUpperCase()} WINS!'
        : capturedCount > 0
            ? capturedCount == 1
                ? 'CAPTURE! EXTRA TURN'
                : '$capturedCount CAPTURES! EXTRA TURN'
            : endProgress == 56
                ? 'PAWN HOME!'
                : null;
    setState(() {
      _selectedPawnIndex = null;
      _movingColor = movingColor;
      _movingPawnIndex = pawnIndex;
      _movementStartProgress = startProgress;
      _movementEndProgress = endProgress;
      _pendingMoveFeedback = feedback;
      _game = nextGame;
      _movementController.duration = reduceMotion
          ? Duration.zero
          : Duration(milliseconds: math.max(180, stepCount * 125).toInt());
    });
    unawaited(_persistMatch());
    _previewController.stop();
    _movementController.forward(from: 0);
  }

  NormalizedBoardPoint _pawnPosition(
    PlayerColor color,
    int pawnIndex,
  ) {
    final player = _game.players.firstWhere((item) => item.color == color);
    final progress = player.pawnProgress[pawnIndex];
    if (_movingColor != color || _movingPawnIndex != pawnIndex) {
      return BoardGeometry.normalizedPosition(color, progress, pawnIndex);
    }

    final steps = _movementEndProgress - _movementStartProgress;
    if (steps <= 0) {
      return BoardGeometry.normalizedPosition(color, progress, pawnIndex);
    }
    final travelled = _movementController.value * steps;
    final stepIndex = math.min(travelled.floor(), steps - 1).toInt();
    final fraction = (travelled - stepIndex).clamp(0.0, 1.0).toDouble();
    final fromProgress = _movementStartProgress + stepIndex;
    final toProgress = fromProgress + 1;
    final from = BoardGeometry.normalizedPosition(
      color,
      fromProgress,
      pawnIndex,
    );
    final to = BoardGeometry.normalizedPosition(
      color,
      toProgress,
      pawnIndex,
    );
    // A small parabolic lift makes each square-to-square step read as a hop.
    // It is presentation-only; the engine has already committed the move.
    const hopHeight = 10.0;
    final hopArc = 4 * hopHeight * fraction * (1 - fraction);
    return NormalizedBoardPoint(
      from.x + (to.x - from.x) * fraction,
      from.y + (to.y - from.y) * fraction -
          hopArc / BoardGeometry.canvasHeight,
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
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / BoardGeometry.canvasWidth,
              constraints.maxHeight / BoardGeometry.canvasHeight,
            );
            final width = BoardGeometry.canvasWidth * scale;
            final height = BoardGeometry.canvasHeight * scale;
            return Center(
              child: RepaintBoundary(
                key: const Key('match_canvas_capture'),
                child: SizedBox(
                key: const Key('match_canvas'),
                width: width,
                height: height,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: BoardGeometry.canvasWidth,
                    height: BoardGeometry.canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/board/ludo_board_glass.webp',
                            key: const Key('board_artwork'),
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) =>
                                const ColoredBox(
                              color: Color(0xFF111111),
                              child: Center(
                                child: Text(
                                  'Game artwork could not be loaded.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ..._buildPawnsWithClusters(scale),
                        if (_selectedPawnIndex != null) _buildDestinationPreview(),
                        Positioned(
                          left: 243,
                          top: 795,
                          width: 90,
                          height: 90,
                          child: KeyedSubtree(
                            key: const Key('roll_dice'),
                            child: LuxuryDiceButton(
                              key: const Key('animated_dice'),
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
                          ),
                        ),
                        Positioned(
                          left: 200,
                          top: 924,
                          width: 176,
                          height: 32,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xE6080808),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusText,
                                  key: const Key('turn_status'),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: _game.activePlayer.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          top: 12,
                          child: IconButton(
                            key: const Key('exit_match'),
                            tooltip: 'Exit match',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFFFFC857),
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
                                onPressed: () {
                                  setState(() {
                                    _game = LudoGame.initial();
                                  });
                                  unawaited(_persistMatch());
                                },
                                child: const Text('PLAY AGAIN'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectOrMovePawn(int pawnIndex) {
    if (_isAutoMovePending || _isDiceAnimating ||
        !_game.legalPawnIndices().contains(pawnIndex)) return;
    if (_selectedPawnIndex == pawnIndex) {
      setState(() => _selectedPawnIndex = null);
      _previewController.stop();
      _move(pawnIndex);
      return;
    }
    setState(() => _selectedPawnIndex = pawnIndex);
    _previewController.forward(from: 0);
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
      final hasOpponent = _game.players.any((player) =>
          player.color != _game.activePlayer &&
          player.pawnProgress.any((opponentProgress) =>
              opponentProgress >= 0 &&
              opponentProgress < BoardGeometry.playerTrackLength &&
              BoardGeometry.physicalTrackCell(player.color, opponentProgress) == cell));
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
    final clusters = <int, List<({PlayerColor color, int pawnIndex})>>{};
    for (final color in PlayerColor.turnOrder) {
      final player = _game.players.firstWhere((item) => item.color == color);
      for (var pawnIndex = 0; pawnIndex < player.pawnProgress.length; pawnIndex++) {
        final point = _pawnPosition(color, pawnIndex);
        final key = _clusterKey(point);
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
          _buildPawn(color, pawnIndex, clusters, legalIndices, canvasScale),
    ];
  }

  int _clusterKey(NormalizedBoardPoint point) =>
      (point.x * 1000).round() * 10000 + (point.y * 1000).round();

  Widget _buildPawn(
    PlayerColor color,
    int pawnIndex,
    Map<int, List<({PlayerColor color, int pawnIndex})>> clusters,
    Set<int> legalIndices,
    double canvasScale,
  ) {
    final player = _game.players.firstWhere((item) => item.color == color);
    final progress = player.pawnProgress[pawnIndex];
    final normalized = _pawnPosition(color, pawnIndex);
    final canvasPoint = BoardGeometry.canvasPosition(normalized);
    final occupants = clusters[_clusterKey(normalized)] ?? [
      (color: color, pawnIndex: pawnIndex),
    ];
    final stackIndex = occupants.indexWhere(
      (item) => item.color == color && item.pawnIndex == pawnIndex,
    );
    const offsets = <Offset>[
      Offset(-.48, -.48),
      Offset(.48, -.48),
      Offset(-.48, .48),
      Offset(.48, .48),
    ];
    final stacked = occupants.length > 1;
    final visualOffset = stacked
        ? offsets[stackIndex % offsets.length] * 18
        : Offset.zero;
    final size = stacked ? 16.0 : (progress == -1 ? 30.0 : 27.0);
    final isHumanTurn = !widget.aiPlayers.contains(color) &&
        color == _game.activePlayer;
    final canMove = !_isDiceAnimating &&
        !_movementController.isAnimating &&
        !_isAutoMovePending &&
        isHumanTurn &&
        legalIndices.contains(pawnIndex);
    final canExplainInvalidMove = !_isDiceAnimating &&
        !_movementController.isAnimating &&
        !_isAutoMovePending &&
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
        ignoring: stacked
            ? !isStackTapTarget
            : !canMove && !canExplainInvalidMove,
        child: Semantics(
          button: stacked
              ? isStackTapTarget
              : canMove || canExplainInvalidMove,
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
    );
  }
}
