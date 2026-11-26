import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../game/domain/feedback_preferences.dart';

enum MatchFeedbackCue { roll, land, capture, retreatStep, finish, invalid }

/// Best-effort device effects emitted after accepted commands/presentation events.
/// No timer, random value, game transition, or animation completion depends on it.
class MatchFeedback {
  MatchFeedback({
    Future<void> Function(SystemSoundType)? sound,
    Future<void> Function(bool important)? haptic,
  })  : _sound = sound ?? SystemSound.play,
        _haptic = haptic ??
            ((important) => important
                ? HapticFeedback.mediumImpact()
                : HapticFeedback.selectionClick());
  final Future<void> Function(SystemSoundType) _sound;
  final Future<void> Function(bool important) _haptic;

  Future<void> play(
    MatchFeedbackCue cue,
    FeedbackPreferences preferences,
  ) async {
    final important =
        cue == MatchFeedbackCue.capture || cue == MatchFeedbackCue.finish;
    if (preferences.sound) {
      try {
        await _sound(important ? SystemSoundType.alert : SystemSoundType.click);
      } catch (error) {
        debugPrint('Game sound unavailable: $error');
      }
    }
    if (preferences.haptics && cue != MatchFeedbackCue.retreatStep) {
      try {
        await _haptic(important);
      } catch (error) {
        debugPrint('Game haptics unavailable: $error');
      }
    }
  }
}
