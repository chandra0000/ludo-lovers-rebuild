import 'package:flutter/material.dart';
import '../../game/domain/mode_registry.dart';
import 'game_setup_screen.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({
    super.key,
    this.allowInternalModes = ModeRegistry.internalBuild,
  });
  final bool allowInternalModes;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0E0C16),
        appBar: AppBar(title: const Text('CHOOSE YOUR MODE')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final mode in ModeRegistry.definitions)
                Card(
                  color: const Color(0xFF1D1725),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          mode.name,
                          style: const TextStyle(
                            color: Color(0xFFFFD36B),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mode.description,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ModeRegistry.canPlay(
                            mode.mode,
                            allowInternal: allowInternalModes,
                          )
                              ? '${mode.playerCounts.join(' / ')} players · Offline'
                              : 'COMING SOON · Acceptance pending',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          key: Key('mode_${mode.mode.name}'),
                          onPressed: ModeRegistry.canPlay(
                            mode.mode,
                            allowInternal: allowInternalModes,
                          )
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => GameSetupScreen(
                                        mode: mode.mode,
                                        allowInternalModes: allowInternalModes,
                                      ),
                                    ),
                                  )
                              : null,
                          child: Text(
                            ModeRegistry.canPlay(
                              mode.mode,
                              allowInternal: allowInternalModes,
                            )
                                ? 'SET UP MATCH'
                                : 'COMING SOON',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
