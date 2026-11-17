import 'package:flutter/material.dart';
import '../../game/domain/feedback_preferences.dart';

class MatchFeedbackSettings extends StatefulWidget {
  const MatchFeedbackSettings({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final FeedbackPreferences value;
  final ValueChanged<FeedbackPreferences> onChanged;
  @override
  State<MatchFeedbackSettings> createState() => _MatchFeedbackSettingsState();
}

class _MatchFeedbackSettingsState extends State<MatchFeedbackSettings> {
  late FeedbackPreferences _value = widget.value;
  void _change(FeedbackPreferences value) {
    setState(() => _value = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'GAME FEEDBACK',
                  style: TextStyle(
                    color: Color(0xFFFFC857),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SwitchListTile(
                key: const Key('game_sound'),
                title: const Text('Game sounds'),
                subtitle: const Text('Device sounds, where supported'),
                value: _value.sound,
                onChanged: (v) => _change(_value.copyWith(sound: v)),
              ),
              SwitchListTile(
                key: const Key('game_haptics'),
                title: const Text('Haptic feedback'),
                value: _value.haptics,
                onChanged: (v) => _change(_value.copyWith(haptics: v)),
              ),
              SwitchListTile(
                key: const Key('game_reduce_motion'),
                title: const Text('Reduce game motion'),
                subtitle: const Text(
                  'System reduced-motion settings always take priority',
                ),
                value: _value.reduceMotion,
                onChanged: (v) => _change(_value.copyWith(reduceMotion: v)),
              ),
            ],
          ),
        ),
      );
}
