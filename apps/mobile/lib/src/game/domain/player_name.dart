import 'package:characters/characters.dart';

/// Local display text only; never used as an actor, command, or player ID.
class PlayerName {
  const PlayerName._();

  static const maxGraphemes = 20;
  static final _forbidden = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c\u115f\u1160\u17b4\u17b5\u180b-\u180f\u200b\u200e\u200f\u202a-\u202e\u2060-\u206f\u2800\u3164\ufeff\uffa0]',
    unicode: true,
  );
  static final _visible = RegExp(r'[\p{L}\p{N}\p{P}\p{S}]', unicode: true);

  static String normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+', unicode: true), ' ');

  static String? errorFor(String value) {
    if (_forbidden.hasMatch(value)) {
      return 'Remove invisible or control characters.';
    }
    final normalized = normalize(value);
    if (normalized.isEmpty || !_visible.hasMatch(normalized)) {
      return 'Enter a visible player name.';
    }
    if (normalized.length > 512) {
      return 'Name is too complex. Use fewer combining characters.';
    }
    if (normalized.characters.length > maxGraphemes) {
      return 'Use at most $maxGraphemes characters.';
    }
    return null;
  }

  static String parse(String value) {
    final error = errorFor(value);
    if (error != null) throw FormatException(error);
    return normalize(value);
  }
}
