import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/domain/board_geometry.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../../game/presentation/player_color_theme.dart';

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
    final diameter = progress == -1 ? 34.0 : 30.0;
    const hitTarget = 44.0;
    final canMove = color == _game.activePlayer &&
        _game.legalPawnIndices().contains(pawnIndex);
    return Positioned(
      left: center.dx - hitTarget / 2,
      top: center.dy - hitTarget / 2,
      width: hitTarget,
      height: hitTarget,
      child: Semantics(
        button: canMove,
        label: '${color.name} pawn ${pawnIndex + 1}',
        child: GestureDetector(
          key: Key('pawn_${color.name}_$pawnIndex'),
          behavior: HitTestBehavior.opaque,
          onTap: canMove ? () => _move(pawnIndex) : null,
          child: Center(
            child: AnimatedContainer(
              width: diameter,
              height: diameter,
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: color.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: canMove ? const Color(0xFFFFD700) : Colors.white,
                  width: canMove ? 3.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.color.withValues(alpha: 0.7),
                    blurRadius: canMove ? 13 : 5,
                    spreadRadius: canMove ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: diameter * 0.28,
                  height: diameter * 0.28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
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
