import '../../theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/domain/ai/seeded_ludo_ai.dart';
import '../../game/domain/match_configuration.dart';
import '../../game/domain/mode_registry.dart';
import '../../game/domain/player_color.dart';
import '../../game/domain/match_player_profile.dart';
import '../../game/domain/player_name.dart';
import '../../game/infrastructure/persistence/player_name_preferences.dart';
import '../match/match_screen.dart';

class GameSetupScreen extends StatefulWidget {
  const GameSetupScreen({
    super.key,
    this.mode = MatchMode.compatibility,
    this.allowInternalModes = ModeRegistry.internalBuild,
    this.initialPlayerCount = 4,
    this.preferComputer = false,
  });
  final MatchMode mode;
  final bool allowInternalModes;
  final int initialPlayerCount;
  final bool preferComputer;

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  int _humanPlayers = 1;
  int _playerCount = 4;
  List<PlayerColor> get _activeColors =>
      MatchConfiguration.local(widget.mode, playerCount: _playerCount)
          .activePlayers;
  LudoAiDifficulty _aiDifficulty = LudoAiDifficulty.medium;

  Set<PlayerColor> get _aiPlayers => _activeColors.skip(_humanPlayers).toSet();

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
    if (!ModeRegistry.definition(widget.mode)
        .playerCounts
        .contains(widget.initialPlayerCount)) {
      throw ArgumentError('Unsupported setup participant count');
    }
    _playerCount = widget.initialPlayerCount;
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
    if (_starting ||
        !ModeRegistry.canPlay(
          widget.mode,
          allowInternal: widget.allowInternalModes,
        )) {
      return;
    }
    final aiPlayers = withAi ? _aiPlayers : <PlayerColor>{};
    final names = <PlayerColor, String>{};
    var invalid = false;
    for (final color in PlayerColor.turnOrder) {
      final error = PlayerName.errorFor(_names[color]!.text);
      _nameErrors[color] =
          aiPlayers.contains(color) || !_activeColors.contains(color)
              ? null
              : error;
      if (_activeColors.contains(color) &&
          !aiPlayers.contains(color) &&
          error != null) {
        invalid = true;
      }
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
            initialGame: ModeRegistry.create(
              widget.mode,
              playerCount: _playerCount,
              allowInternal: widget.allowInternalModes,
            ),
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
                for (final color in _activeColors)
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
  Widget build(BuildContext context) {
    if (!ModeRegistry.canPlay(
      widget.mode,
      allowInternal: widget.allowInternalModes,
    )) {
      return Scaffold(
        appBar: AppBar(title: Text(ModeRegistry.definition(widget.mode).name)),
        body: const SafeArea(
          child: Center(child: Text('COMING SOON · Acceptance pending')),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: Text(widget.preferComputer ? 'VS COMPUTER SETUP' : 'GAME SETUP'),
        backgroundColor: const Color(0xFF100D08),
        foregroundColor: const Color(0xFFFFC857),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.mode == MatchMode.compatibility
                  ? 'CHOOSE YOUR GAME'
                  : '${ModeRegistry.definition(widget.mode).name.toUpperCase()} RULES',
              style: AppTypography.heading,
            ),
            const SizedBox(height: 8),
            const Text(
              'Play on this device with friends, or add computer opponents. '
              'Two-player matches use opposite orange and magenta seats.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
            const SizedBox(height: 12),
            if (ModeRegistry.definition(widget.mode).playerCounts.length > 1)
              DropdownButtonFormField<int>(
                key: const Key('mode_player_count'),
                initialValue: _playerCount,
                decoration: const InputDecoration(
                  labelText: 'Participating players',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: ModeRegistry.definition(widget.mode)
                    .playerCounts
                    .map(
                      (count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text(
                          '$count players',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (count) {
                  if (count != null) {
                    setState(() {
                      _playerCount = count;
                      _humanPlayers = _humanPlayers.clamp(
                        1,
                        count - (widget.preferComputer ? 1 : 0),
                      );
                    });
                  }
                },
              ),
            _nameEditor(),
            const SizedBox(height: 12),
            if (!widget.preferComputer)
              _ModeCard(
                title: widget.mode == MatchMode.compatibility
                    ? 'LOCAL · $_playerCount PLAYERS'
                    : '${ModeRegistry.definition(widget.mode).name.toUpperCase()} · $_playerCount PLAYERS',
                subtitle: ModeRegistry.definition(widget.mode).description,
                enabled: ModeRegistry.canPlay(
                  widget.mode,
                  allowInternal: widget.allowInternalModes,
                ),
                label: widget.mode == MatchMode.compatibility
                    ? 'AVAILABLE'
                    : 'INTERNAL PREVIEW',
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
                      'Choose how many friends are playing. Bots take the remaining seats.',
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
                          items: List.generate(
                            _playerCount - (widget.preferComputer ? 1 : 0),
                            (index) => index + 1,
                          )
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
                      '${_playerCount - _humanPlayers} AI opponent(s) · '
                      '${_activeColors.map((color) => color.name.toUpperCase()).join(' → ')}',
                      style: const TextStyle(
                        color: Color(0xFFFFF4DF),
                        fontSize: 14,
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
                        color: Color(0xFFFFF4DF),
                        fontSize: 14,
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
            if (widget.mode == MatchMode.compatibility)
              const _ModeCard(
                title: 'TEAM UP · 2 VS 2',
                subtitle: 'Pair up with a teammate for a two-versus-two match.',
                enabled: false,
                label: 'COMING SOON',
              ),
          ],
        ),
      ),
    );
  }
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
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color:
                            enabled ? const Color(0xFFFFC857) : Colors.white38,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
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
                    child: const Text('START LOCAL MATCH'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
