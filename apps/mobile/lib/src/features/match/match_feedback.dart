import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../game/domain/feedback_preferences.dart';

enum MatchFeedbackCue {
  roll,
  land,
  capture,
  retreatStep,
  yard,
  finish,
  invalid
}

/// Best-effort device effects emitted after accepted commands/presentation events.
/// No timer, random value, game transition, or animation completion depends on it.
class MatchFeedback {
  MatchFeedback({
    Future<void> Function(SystemSoundType)? sound,
    Future<void> Function(bool important)? haptic,
  })  : _sound = sound,
        _haptic = haptic ??
            ((important) => important
                ? HapticFeedback.mediumImpact()
                : HapticFeedback.selectionClick());
  final Future<void> Function(SystemSoundType)? _sound;
  final Future<void> Function(bool important) _haptic;

  final _pools = <String, Future<AudioPool>>{};
  bool _disposed = false;

  Future<AudioPool> _pool(String clip) => _pools.putIfAbsent(
        clip,
        () => AudioPool.createFromAsset(
          path: 'audio/$clip.wav',
          maxPlayers: 2,
        ),
      );

  Future<void> prepare() async {
    for (final clip in [
      'impact',
      'rattle',
      'yard',
      for (var i = 0; i < 5; i++) 'hop$i',
    ]) {
      if (_disposed) return;
      try {
        await _pool(clip);
      } catch (error) {
        _pools.remove(clip);
        debugPrint('Game sound preparation: $error');
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final future in _pools.values.toList()) {
      try {
        await (await future).dispose();
      } catch (error) {
        debugPrint('Game sound cleanup: $error');
      }
    }
  }

  Future<void> play(
    MatchFeedbackCue cue,
    FeedbackPreferences preferences, {
    int pitchBand = 0,
  }) async {
    final important =
        cue == MatchFeedbackCue.capture || cue == MatchFeedbackCue.finish;
    if (preferences.sound) {
      try {
        final type = important ? SystemSoundType.alert : SystemSoundType.click;
        final clip = switch (cue) {
          MatchFeedbackCue.roll => 'rattle',
          MatchFeedbackCue.capture => 'impact',
          MatchFeedbackCue.retreatStep => 'hop${pitchBand.clamp(0, 4)}',
          MatchFeedbackCue.yard => 'yard',
          _ => null,
        };
        if (_sound != null || clip == null) {
          await (_sound ?? SystemSound.play)(type);
        } else if (!_disposed) {
          final pool = await _pool(clip);
          if (!_disposed) await pool.start();
        }
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
