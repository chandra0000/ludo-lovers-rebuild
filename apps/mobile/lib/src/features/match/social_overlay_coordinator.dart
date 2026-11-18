import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../game/domain/player_color.dart';

class LocalSocialFeedback {
  const LocalSocialFeedback(this.text, this.sequence);
  final String text;
  final int sequence;
}

/// Local-device presentation only; never schedules AI or sends a network message.
class SocialOverlayCoordinator extends ChangeNotifier {
  final _feedback = <PlayerColor, LocalSocialFeedback>{};
  final _expiry = <PlayerColor, Timer>{};
  int _sequence = 0;
  bool _disposed = false;
  LocalSocialFeedback? forPlayer(PlayerColor player) => _feedback[player];
  void show(PlayerColor player, String text) {
    if (_disposed || text.trim().isEmpty) return;
    _expiry.remove(player)?.cancel();
    _feedback[player] = LocalSocialFeedback(text, ++_sequence);
    _expiry[player] = Timer(const Duration(seconds: 2), () {
      if (_disposed) return;
      _expiry.remove(player);
      _feedback.remove(player);
      notifyListeners();
    });
    notifyListeners();
  }

  void clear() {
    for (final timer in _expiry.values) {
      timer.cancel();
    }
    _expiry.clear();
    _feedback.clear();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}
