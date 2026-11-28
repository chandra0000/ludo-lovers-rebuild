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
  invalid,
  hop,
  safeArrival,
}

/// Best-effort device effects emitted after accepted commands/presentation events.
/// No timer, random value, game transition, or animation completion depends on it.
class MatchFeedback {
  MatchFeedback({
    Future<void> Function(SystemSoundType)? sound,
    Future<void> Function(bool important)? haptic,
  })  : _sound = sound,
        _haptic = haptic;
  final Future<void> Function(SystemSoundType)? _sound;
  final Future<void> Function(bool important)? _haptic;

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
      'capture',
      'dice_roll',
      'pawn_hop',
      'safe_star',
      'victory',
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
    if (_disposed) return;
    final important =
        cue == MatchFeedbackCue.capture || cue == MatchFeedbackCue.finish;
    if (preferences.sound) {
      try {
        final type = important ? SystemSoundType.alert : SystemSoundType.click;
        final clip = switch (cue) {
          MatchFeedbackCue.roll => 'dice_roll',
          MatchFeedbackCue.capture => 'capture',
          MatchFeedbackCue.retreatStep => 'hop${pitchBand.clamp(0, 4)}',
          MatchFeedbackCue.yard => 'yard',
          MatchFeedbackCue.hop => 'pawn_hop',
          MatchFeedbackCue.safeArrival => 'safe_star',
          MatchFeedbackCue.finish => 'victory',
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
    if (!_disposed &&
        preferences.haptics &&
        cue != MatchFeedbackCue.retreatStep) {
      try {
        if (_haptic != null) {
          await _haptic(important);
        } else if (important) {
          await HapticFeedback.heavyImpact();
        } else if (cue == MatchFeedbackCue.roll) {
          await HapticFeedback.lightImpact();
        } else {
          await HapticFeedback.selectionClick();
        }
      } catch (error) {
        debugPrint('Game haptics unavailable: $error');
      }
    }
  }
}
