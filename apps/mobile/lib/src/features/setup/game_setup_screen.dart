import 'package:flutter/material.dart';

import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../board_preview/board_preview_screen.dart';
import '../match/match_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _humanPlayers = 1;

  Set<PlayerColor> get _aiPlayers => PlayerColor.turnOrder
      .skip(_humanPlayers)
      .toSet();

  void _startMatch({required bool withAi}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchScreen(
          initialGame: LudoGame.initial(
            ruleProfile: LudoRuleProfile.currentV1,
          ),
          aiPlayers: withAi ? _aiPlayers : const {},
          aiSeed: 20261110,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF080808),
        appBar: AppBar(
          title: const Text('GAME SETUP'),
          backgroundColor: const Color(0xFF100D08),
          foregroundColor: const Color(0xFFFFC857),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'CHOOSE YOUR GAME',
                style: TextStyle(
                  color: Color(0xFFFFC857),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Play locally with friends or fill the remaining seats with '
                'seeded AI opponents. All moves are accepted by the same '
                'authoritative game engine.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 22),
              _ModeCard(
                title: 'LOCAL FOUR-PLAYER',
                subtitle: 'Pass-and-play · Current compatibility rules',
                enabled: true,
                label: 'AVAILABLE',
                onTap: () => _startMatch(withAi: false),
                buttonKey: const Key('start_local_match'),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF17130D),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Color(0x99FFC857)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HUMAN VS AI',
                        style: TextStyle(
                          color: Color(0xFFFFC857),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose how many human seats to use. Remaining colours '
                        'are controlled by deterministic AI.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Human players',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownButton<int>(
                            key: const Key('human_player_count'),
                            value: _humanPlayers,
                            dropdownColor: const Color(0xFF17130D),
                            items: [1, 2, 3, 4]
                                .map(
                                  (count) => DropdownMenuItem<int>(
                                    value: count,
                                    child: Text('$count'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _humanPlayers = value);
                              }
                            },
                          ),
                        ],
                      ),
                      Text(
                        '${4 - _humanPlayers} AI opponent(s) · '
                        'Orange → Green → Magenta → Blue',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('start_ai_match'),
                          onPressed: () => _startMatch(withAi: true),
                          child: const Text('START VS AI'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const _ModeCard(
                title: 'TEAM UP · 2 VS 2',
                subtitle: 'Team rules, bonus turns and victory conditions '
                    'are still being recovered.',
                enabled: false,
                label: 'IN DEVELOPMENT',
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const Key('open_board_preview'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const BoardPreviewScreen(),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('PREVIEW BOARD & PAWN ANCHORS'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Preview anchors are diagnostic only. Final visual approval '
                'requires pixel measurement and real-device verification.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.label,
    this.onTap,
    this.buttonKey,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final String label;
  final VoidCallback? onTap;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFF17130D),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: enabled ? const Color(0x99FFC857) : Colors.white12,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFC857),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: enabled
                          ? const Color(0xFFFFC857)
                          : Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
              if (enabled) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: buttonKey,
                    onPressed: onTap,
                    child: const Text('START FOUR-PLAYER GAME'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
