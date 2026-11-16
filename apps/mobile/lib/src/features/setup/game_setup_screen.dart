import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/ludo_game.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_name.dart';
import '../../game/infrastructure/persistence/player_name_preferences.dart';
import '../board_preview/board_preview_screen.dart';
import '../match/match_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({super.key});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _humanPlayers = 1;
  LudoAiDifficulty _aiDifficulty = LudoAiDifficulty.medium;

  Set<PlayerColor> get _aiPlayers =>
      PlayerColor.turnOrder.skip(_humanPlayers).toSet();

  final Map<PlayerColor, TextEditingController> _names = {
    for (final color in PlayerColor.turnOrder)
      color: TextEditingController(text: color.name.toUpperCase()),
  };
  final _editedNames = <PlayerColor>{};
  final _fieldKeys = {
    for (final color in PlayerColor.turnOrder) color: GlobalKey(),
  };
  final _nameErrors = <PlayerColor, String?>{};
  final _preferences = const PlayerNamePreferences();
  final _scroll = ScrollController();
  bool _showNameEditor = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final names = await _preferences.load();
      if (!mounted) return;
      for (final entry in names.entries) {
        if (!_editedNames.contains(entry.key)) {
          _names[entry.key]!.text = entry.value;
        }
      }
    } catch (error) {
      debugPrint('Could not load preferred player names: $error');
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final controller in _names.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _startMatch({required bool withAi}) async {
    if (_starting) return;
    final aiPlayers = withAi ? _aiPlayers : <PlayerColor>{};
    final names = <PlayerColor, String>{};
    var invalid = false;
    for (final color in PlayerColor.turnOrder) {
      final error = PlayerName.errorFor(_names[color]!.text);
      _nameErrors[color] = aiPlayers.contains(color) ? null : error;
      if (!aiPlayers.contains(color) && error != null) invalid = true;
      if (error == null) names[color] = PlayerName.parse(_names[color]!.text);
    }
    if (invalid) {
      setState(() => _showNameEditor = true);
      if (_scroll.hasClients) _scroll.jumpTo(0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final color = PlayerColor.turnOrder
            .firstWhere((color) => _nameErrors[color] != null);
        final context = _fieldKeys[color]!.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 200),
          );
        }
      });
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _starting = true);
    try {
      try {
        await _preferences.save(names);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Names could not be saved for your next match.'),
            ),
          );
        }
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MatchScreen(
            initialGame:
                LudoGame.initial(ruleProfile: LudoRuleProfile.currentV1),
            aiPlayers: aiPlayers,
            aiSeed: 20261110,
            aiDifficulty: _aiDifficulty,
            profiles:
                MatchPlayerProfile.local(aiPlayers: aiPlayers, names: names),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Widget _nameEditor() => Card(
        color: const Color(0xFF17130D),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                key: const Key('edit_player_names'),
                onPressed: () =>
                    setState(() => _showNameEditor = !_showNameEditor),
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  _showNameEditor ? 'HIDE PLAYER NAMES' : 'EDIT PLAYER NAMES',
                ),
              ),
              if (_showNameEditor) ...[
                const Text(
                  'Human names · up to 20 characters. AI seats use labelled bot names. '
                  'Matching names are distinguished by seat numbers.',
                  style: TextStyle(color: Colors.white70),
                ),
                for (final color in PlayerColor.turnOrder)
                  Padding(
                    key: _fieldKeys[color],
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      key: Key('player_name_${color.name}'),
                      controller: _names[color],
                      maxLength: PlayerName.maxGraphemes,
                      maxLengthEnforcement: MaxLengthEnforcement.none,
                      textCapitalization: TextCapitalization.words,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText:
                            'Seat ${PlayerColor.turnOrder.indexOf(color) + 1} · ${color.name.toUpperCase()}',
                        labelStyle: const TextStyle(color: Color(0xFFFFC857)),
                        errorText: _nameErrors[color],
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _editedNames.add(color);
                        setState(
                          () => _nameErrors[color] = PlayerName.errorFor(value),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      );

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
            controller: _scroll,
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
              const SizedBox(height: 12),
              _nameEditor(),
              const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'AI difficulty',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          DropdownButton<LudoAiDifficulty>(
                            key: const Key('ai_difficulty'),
                            value: _aiDifficulty,
                            dropdownColor: const Color(0xFF17130D),
                            items: LudoAiDifficulty.values
                                .map(
                                  (difficulty) =>
                                      DropdownMenuItem<LudoAiDifficulty>(
                                    value: difficulty,
                                    child: Text(
                                      difficulty.name.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _aiDifficulty = value);
                              }
                            },
                          ),
                        ],
                      ),
                      Text(
                        switch (_aiDifficulty) {
                          LudoAiDifficulty.easy =>
                            'Easy · Random legal moves; best for casual play.',
                          LudoAiDifficulty.medium =>
                            'Medium · Balances progress, safety and captures.',
                          LudoAiDifficulty.hard =>
                            'Hard · More strongly prioritises tactics and safety.',
                        },
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
                      color: enabled ? const Color(0xFFFFC857) : Colors.white38,
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
