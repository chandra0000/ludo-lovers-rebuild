import 'dart:math';

import 'package:flutter/material.dart';

import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  LudoGame _game = LudoGame.initial();
  final Random _random = Random();

  void _roll() {
    if (_game.diceValue != null || _game.winner != null) return;
    setState(() {
      final rolled = _game.roll(_random.nextInt(6) + 1);
      _game = rolled.legalPawnIndices().isEmpty ? rolled.passTurn() : rolled;
    });
  }

  void _move(int index) {
    if (!_game.legalPawnIndices().contains(index)) return;
    setState(() => _game = _game.movePawn(index));
  }

  @override
  Widget build(BuildContext context) {
    final player = _game.currentPlayer;
    final legal = _game.legalPawnIndices().toSet();
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOCAL MATCH'),
        foregroundColor: const Color(0xFFFFC857),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF171717),
                        border: Border.all(color: const Color(0xFFFFC857), width: 2),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        padding: const EdgeInsets.all(18),
                        children: PlayerColor.turnOrder.map((color) {
                          final p = _game.players.firstWhere((item) => item.color == color);
                          return Container(
                            margin: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: color.value.withOpacity(0.14),
                              border: Border.all(color: color.value, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(color.name.toUpperCase(),
                                    style: TextStyle(color: color.value, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  children: List.generate(4, (i) => Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Icon(
                                      Icons.circle,
                                      size: 19,
                                      color: p.pawnProgress[i] == -1 ? color.value : Colors.white,
                                    ),
                                  )),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                _game.winner == null ? '${player.color.name.toUpperCase()} TO PLAY' : '${_game.winner!.name.toUpperCase()} WINS',
                key: const Key('turn_status'),
                style: TextStyle(color: player.color.value, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (_game.diceValue == null)
                FilledButton(
                  key: const Key('roll_dice'),
                  onPressed: _game.winner == null ? _roll : null,
                  child: const Text('ROLL DICE'),
                )
              else ...[
                Text('DICE: ${_game.diceValue}', style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(4, (i) => OutlinedButton(
                    key: Key('pawn_$i'),
                    onPressed: legal.contains(i) ? () => _move(i) : null,
                    child: Text('PAWN ${i + 1}'),
                  )),
                ),
              ],
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _game = LudoGame.initial()),
                child: const Text('RESTART MATCH'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
