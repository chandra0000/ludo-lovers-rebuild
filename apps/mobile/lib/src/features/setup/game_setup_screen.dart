import 'package:flutter/material.dart';

import '../../game/domain/ludo_game.dart';
import '../board_preview/board_preview_screen.dart';
import '../match/match_screen.dart';

class GameSetupScreen extends StatelessWidget {
  const GameSetupScreen({super.key});

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
                'Start with the verified four-seat local engine. Player-count '
                'variants and alternate rules stay unavailable until their '
                'engine behaviour is implemented and tested.',
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 22),
              _ModeCard(
                title: 'LOCAL FOUR-PLAYER',
                subtitle: 'Pass-and-play · Current compatibility rules',
                enabled: true,
                label: 'AVAILABLE',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MatchScreen(
                      initialGame: LudoGame.initial(
                        ruleProfile: LudoRuleProfile.currentV1,
                      ),
                    ),
                  ),
                ),
                buttonKey: const Key('start_local_match'),
              ),
              const SizedBox(height: 12),
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
