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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late LudoGame _game = widget.initialGame ?? LudoGame.initial();
  late final math.Random _random = math.Random(widget.aiSeed);
  final SeededLudoAi _ai = const SeededLudoAi();
  bool _aiTurnScheduled = false;
  bool _isDiceAnimating = false;
  bool _isAppResumed = true;
  final SavedMatchStore _savedMatchStore = const SavedMatchStore();
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isAppResumed = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleAiTurn();
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

  Future<void> _persistMatch() async {
    try {
      await _savedMatchStore.save(
        SavedMatch(
          game: _game,
          aiPlayers: widget.aiPlayers,
          aiSeed: widget.aiSeed,
        ),
      );
    } catch (error) {
      debugPrint('Could not persist local match: $error');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_persistMatch());
    _movementController.dispose();
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
            _random.nextInt(6) + 1,
            expectedStateVersion: _game.stateVersion,
            commandId: 'ai-${widget.aiSeed}-${_game.stateVersion}-roll',
          );
          setState(() {
            _game = rolled;
            _isDiceAnimating = true;
            _diceRollId++;
          });
          unawaited(_persistMatch());
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
        ? _random.nextInt(6) + 1
        : widget.rollDice?.call() ?? _random.nextInt(6) + 1;
    final rolled = _game.roll(
      value,
      expectedStateVersion: _game.stateVersion,
      commandId: '${isAi ? 'ai-${widget.aiSeed}' : 'match'}-${_game.stateVersion}-roll',
    );
    setState(() {
      _game = rolled;
      _isDiceAnimating = true;
      _diceRollId++;
    });
    unawaited(_persistMatch());
    return true;
  }

  void _handleDiceAnimationComplete() {
    if (!mounted || !_isAppResumed || !_isDiceAnimating) return;
    final legal = _game.legalPawnIndices();
    setState(() => _isDiceAnimating = false);

    if (_game.diceValue == null) return;
    if (legal.isEmpty) {
      setState(() {
        _game = _game.passTurn(
          expectedStateVersion: _game.stateVersion,
          commandId: 'match-${_game.stateVersion}-pass',
        );
      });
      unawaited(_persistMatch());
      _scheduleAiTurn();
      return;
    }

    if (widget.aiPlayers.contains(_game.activePlayer)) {
      final selected = _ai.choosePawn(
        _game,
        seed: widget.aiSeed ^ _game.stateVersion,
      );
      if (selected != null) _move(selected);
    }
  }

  void _move(int pawnIndex) {
    if (_isDiceAnimating || !_game.legalPawnIndices().contains(pawnIndex)) {
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

  void _handleStackTap(List<int> movablePawnIndices) {
    if (movablePawnIndices.isEmpty) {
      return;
    }
    if (movablePawnIndices.length == 1) {
      _move(movablePawnIndices.single);
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
        _move(selectedIndex);
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
    final canMove = !_isDiceAnimating &&
        !_movementController.isAnimating &&
        color == _game.activePlayer &&
        legalIndices.contains(pawnIndex);
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
    return Positioned(
      left: tapPosition.dx - hitTargetWidth / 2,
      top: tapPosition.dy - hitTargetHeight / 2,
      width: hitTargetWidth,
      height: hitTargetHeight,
      child: IgnorePointer(
        // Inactive/non-legal pawns must not cover a legal pawn's enlarged
        // touch target when adjacent cells overlap on compact screens.
        ignoring: !canMove || (stacked && !isStackTapTarget),
        child: Semantics(
          button: stacked ? isStackTapTarget : canMove,
          label: stacked
              ? 'Choose a movable pawn from this shared cell'
              : '${color.name} pawn ${pawnIndex + 1}',
          child: GestureDetector(
            key: Key('pawn_${color.name}_$pawnIndex'),
            behavior: HitTestBehavior.opaque,
            onTap: stacked
                ? (isStackTapTarget
                    ? () => _handleStackTap(movableStackIndices)
                    : null)
                : (canMove ? () => _move(pawnIndex) : null),
            child: Center(
              child: Transform.translate(
                offset: visualOffset,
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
    );
  }
}
