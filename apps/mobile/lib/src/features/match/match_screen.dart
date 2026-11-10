import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';
import '../../game/presentation/glassy_pawn.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  static const double _canvasWidth = 576;
  static const double _canvasHeight = 1024;
  static const Rect _boardRect = Rect.fromLTWH(17, 205, 542, 542);

  LudoGame _game = LudoGame.initial();
  final math.Random _random = math.Random();

  void _roll() {
    if (_game.diceValue != null || _game.winner != null) {
      return;
    }
    setState(() {
      final rolled = _game.roll(_random.nextInt(6) + 1);
      _game = rolled.legalPawnIndices().isEmpty ? rolled.passTurn() : rolled;
    });
  }

  void _move(int pawnIndex) {
    if (!_game.legalPawnIndices().contains(pawnIndex)) {
      return;
    }
    setState(() => _game = _game.movePawn(pawnIndex));
  }

  String get _statusText {
    if (_game.winner != null) {
      return '${_game.winner!.name.toUpperCase()} WINS';
    }
    return '${_game.activePlayer.name.toUpperCase()} · YOUR TURN';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = math.min(
              constraints.maxWidth / _canvasWidth,
              constraints.maxHeight / _canvasHeight,
            );
            final width = _canvasWidth * scale;
            final height = _canvasHeight * scale;
            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: SizedBox(
                    width: _canvasWidth,
                    height: _canvasHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/reference/ludo_lovers_full_screen_reference.webp',
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
                        for (final color in PlayerColor.turnOrder)
                          for (var pawnIndex = 0; pawnIndex < 4; pawnIndex++)
                            _buildPawn(color, pawnIndex),
                        Positioned(
                          left: 243,
                          top: 795,
                          width: 90,
                          height: 90,
                          child: Semantics(
                            button: true,
                            label: 'Roll dice',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('roll_dice'),
                                customBorder: const CircleBorder(),
                                onTap: _game.diceValue == null ? _roll : null,
                                child: _game.diceValue == null
                                    ? const SizedBox.expand()
                                    : Center(
                                        child: Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFC857),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF080808),
                                              width: 3,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black54,
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${_game.diceValue}',
                                            style: const TextStyle(
                                              color: Color(0xFF080808),
                                              fontSize: 27,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
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
                                onPressed: () =>
                                    setState(() => _game = LudoGame.initial()),
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
          },
        ),
      ),
    );
  }

  Widget _buildPawn(PlayerColor color, int pawnIndex) {
    final player = _game.players.firstWhere((item) => item.color == color);
    final progress = player.pawnProgress[pawnIndex];
    final normalized = BoardGeometry.normalizedPosition(
      color,
      progress,
      pawnIndex,
    );
    final center = Offset(
      _boardRect.left + normalized.x * _boardRect.width,
      _boardRect.top + normalized.y * _boardRect.height,
    );

    // Fan out pieces sharing a track cell into a compact 2x2 formation.
    // Keep each pawn independently tappable and visually identifiable.
    final occupants = <({PlayerColor color, int pawnIndex, Offset center})>[];
    for (final otherColor in PlayerColor.turnOrder) {
      final otherPlayer = _game.players.firstWhere(
        (item) => item.color == otherColor,
      );
      for (
        var otherIndex = 0;
        otherIndex < otherPlayer.pawnProgress.length;
        otherIndex++
      ) {
        final otherProgress = otherPlayer.pawnProgress[otherIndex];
        final otherPoint = BoardGeometry.normalizedPosition(
          otherColor,
          otherProgress,
          otherIndex,
        );
        final otherCenter = Offset(
          _boardRect.left + otherPoint.x * _boardRect.width,
          _boardRect.top + otherPoint.y * _boardRect.height,
        );
        if ((otherCenter - center).distance < 0.5) {
          occupants.add(
            (color: otherColor, pawnIndex: otherIndex, center: otherCenter),
          );
        }
      }
    }
    occupants.sort((a, b) {
      final colorOrder = PlayerColor.turnOrder.indexOf(a.color).compareTo(
        PlayerColor.turnOrder.indexOf(b.color),
      );
      return colorOrder != 0 ? colorOrder : a.pawnIndex.compareTo(b.pawnIndex);
    });
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
    final position = stacked
        ? center + offsets[stackIndex % offsets.length] * 18
        : center;
    final size = stacked ? 16.0 : (progress == -1 ? 30.0 : 27.0);
    final canMove = color == _game.activePlayer &&
        _game.legalPawnIndices().contains(pawnIndex);
    final isCurrentPlayer = color == _game.activePlayer;

    return Positioned(
      left: position.dx - 22,
      top: position.dy - 24,
      width: 44,
      height: 48,
      child: Semantics(
        button: canMove,
        label: '${color.name} pawn ${pawnIndex + 1}',
        child: GestureDetector(
          key: Key('pawn_${color.name}_$pawnIndex'),
          behavior: HitTestBehavior.opaque,
          onTap: canMove ? () => _move(pawnIndex) : null,
          child: Center(
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
    );
  }
}
