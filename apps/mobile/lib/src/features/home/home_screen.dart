import '../../theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../game/domain/persistence/saved_match.dart';
import '../../game/domain/mode_registry.dart';
import '../../game/domain/match_configuration.dart';
import '../../game/domain/player_color.dart';
import '../../game/infrastructure/persistence/player_name_preferences.dart';
import '../../game/infrastructure/persistence/saved_match_store.dart';
import '../match/match_screen.dart';
import '../setup/game_setup_screen.dart';
import '../setup/mode_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.allowInternalModes = ModeRegistry.internalBuild,
  });
  final bool allowInternalModes;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _gold = Color(0xFFFFC857);
  final SavedMatchStore _savedMatchStore = const SavedMatchStore();
  SavedMatch? _savedMatch;
  String? _playerName;
  bool get _canResumeSaved =>
      _savedMatch != null &&
      ModeRegistry.canPlay(
        _savedMatch!.game.configuration.mode,
        allowInternal: widget.allowInternalModes,
      );

  @override
  void initState() {
    super.initState();
    _loadSavedMatch();
    _loadPlayerName();
  }

  Future<void> _loadSavedMatch() async {
    final saved = await _savedMatchStore.load();
    if (mounted) setState(() => _savedMatch = saved);
  }

  Future<void> _loadPlayerName() async {
    final names = await const PlayerNamePreferences().load();
    if (mounted) setState(() => _playerName = names[PlayerColor.orange]);
  }

  Future<void> _discardSavedMatch() async {
    await _savedMatchStore.clear();
    if (mounted) setState(() => _savedMatch = null);
  }

  static const _background = Color(0xFF080808);

  @override
  Widget build(BuildContext context) {
    final logoSize = (MediaQuery.sizeOf(context).width * .29)
        .clamp(88.0, 132.0)
        .toDouble();

    return Scaffold(
      backgroundColor: _background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF17110A),
              Color(0xFF080808),
              Color(0xFF030303),
            ],
          ),
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 26,
                            backgroundColor: _gold,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundImage: AssetImage(
                                'assets/images/board/extracted/avatar_aldo.webp',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _playerName ?? 'Player',
                                  style: AppTypography.playerName,
                                ),
                                const Text(
                                  'LUDO LOVERS',
                                  style: AppTypography.heading,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: logoSize + 20,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: RadialGradient(
                              radius: .54,
                              colors: [
                                Color(0xCC7B358D),
                                Color(0x887A390C),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/branding/ludo_lovers_icon.webp',
                                key: const Key('brand_logo'),
                                width: logoSize,
                                height: logoSize,
                                fit: BoxFit.cover,
                                semanticLabel: 'Ludo Lovers',
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_savedMatch != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            key: const Key('resume_saved_match'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _gold,
                              side: const BorderSide(color: _gold),
                              minimumSize: const Size.fromHeight(52),
                            ),
                            onPressed: _canResumeSaved
                                ? () => Navigator.of(context)
                                    .push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => MatchScreen(
                                          initialGame: _savedMatch!.game,
                                          aiPlayers: _savedMatch!.aiPlayers,
                                          aiSeed: _savedMatch!.aiSeed,
                                          profiles: _savedMatch!.profiles,
                                          aiDifficulty:
                                              _savedMatch!.aiDifficulty,
                                        ),
                                      ),
                                    )
                                    .then((_) => _loadSavedMatch())
                                : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('RESUME SAVED MATCH'),
                          ),
                        ),
                        if (!_canResumeSaved)
                          const Text(
                            'This saved mode is not enabled in this build.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        TextButton(
                          key: const Key('discard_saved_match'),
                          onPressed: _discardSavedMatch,
                          child: const Text(
                            'DISCARD SAVED MATCH',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      DecoratedBox(
                        decoration: const ShapeDecoration(
                          shape: StadiumBorder(),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFFE48A), Color(0xFFF7A218)],
                          ),
                        ),
                        child: FilledButton(
                          key: const Key('open_game_setup'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF17110A),
                            minimumSize: const Size(double.infinity, 56),
                            shape: const StadiumBorder(
                              side: BorderSide(color: Color(0xFFFFEA9A)),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () => _openSetup(),
                          child: const Text(
                            'PLAY NOW',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              fontSize: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _modeTile(
                              'Classic',
                              Icons.public_rounded,
                              const Color(0xFFA5E651),
                              mode: MatchMode.classic,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _modeTile(
                              'Quick',
                              Icons.bolt_rounded,
                              const Color(0xFFFF72B8),
                              mode: MatchMode.quick,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _modeTile(
                              'Team Up',
                              Icons.groups_rounded,
                              const Color(0xFFC0B6FF),
                              mode: MatchMode.teamUp,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _modeTile(
                              'VS Computer',
                              Icons.smart_toy_rounded,
                              const Color(0xFF72D9FC),
                              computer: true,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _modeTile(
                              'Local',
                              Icons.devices_rounded,
                              const Color(0xFFFFD36B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        key: const Key('open_mode_selection'),
                        onPressed: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute<void>(
                                builder: (_) => ModeSelectionScreen(
                                  allowInternalModes: widget.allowInternalModes,
                                ),
                              ),
                            )
                            .then((_) => _loadSavedMatch()),
                        icon: const Icon(Icons.dashboard_customize_outlined),
                        label: const Text('EXPLORE GAME MODES'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSetup({
    MatchMode mode = MatchMode.compatibility,
    bool computer = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameSetupScreen(
          mode: mode,
          preferComputer: computer,
          allowInternalModes: widget.allowInternalModes,
        ),
      ),
    );
    await Future.wait([_loadSavedMatch(), _loadPlayerName()]);
  }

  Widget _modeTile(
    String title,
    IconData icon,
    Color accent, {
    MatchMode mode = MatchMode.compatibility,
    bool computer = false,
  }) {
    final available = ModeRegistry.canPlay(
      mode,
      allowInternal: widget.allowInternalModes,
    );
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 92),
        foregroundColor: accent,
        disabledForegroundColor: accent.withValues(alpha: .65),
        backgroundColor: accent.withValues(alpha: .10),
        disabledBackgroundColor: accent.withValues(alpha: .06),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        side: BorderSide(color: accent.withValues(alpha: available ? .85 : .4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: available
          ? () => _openSetup(mode: mode, computer: computer)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [accent.withValues(alpha: .28), Colors.transparent],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: computer ? 40 : 32),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center),
          if (!available)
            const Text(
              'Preview',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
        ],
      ),
    );
  }
}
