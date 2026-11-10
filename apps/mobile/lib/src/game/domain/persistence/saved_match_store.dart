import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../ludo_game.dart';
import '../player_color.dart';

/// Stores one local match so the app can recover after backgrounding or
/// process recreation. This is local-device persistence, not cloud sync.
class SavedMatch {
  const SavedMatch({
    required this.game,
    required this.aiPlayers,
    required this.aiSeed,
  });

  final LudoGame game;
  final Set<PlayerColor> aiPlayers;
  final int aiSeed;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'game': game.toSnapshot(),
        'aiPlayers': aiPlayers.map((player) => player.name).toList()..sort(),
        'aiSeed': aiSeed,
      };

  factory SavedMatch.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json['game'] is! Map<String, dynamic> ||
        json['aiPlayers'] is! List ||
        json['aiSeed'] is! int) {
      throw const FormatException('Malformed saved match.');
    }
    final rawAiPlayers = json['aiPlayers'] as List;
    if (rawAiPlayers.any((value) => value is! String)) {
      throw const FormatException('Malformed saved AI seats.');
    }
    final aiPlayers = rawAiPlayers
        .cast<String>()
        .map((name) => PlayerColor.values.byName(name))
        .toSet();
    if (aiPlayers.length != rawAiPlayers.length) {
      throw const FormatException('Duplicate saved AI seats.');
    }
    return SavedMatch(
      game: LudoGame.fromSnapshot(json['game'] as Map<String, dynamic>),
      aiPlayers: Set<PlayerColor>.unmodifiable(aiPlayers),
      aiSeed: json['aiSeed'] as int,
    );
  }

  String encode() => jsonEncode(toJson());

  factory SavedMatch.decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Saved match must be a JSON object.');
    }
    return SavedMatch.fromJson(decoded);
  }
}

class SavedMatchStore {
  const SavedMatchStore();

  static const _storageKey = 'saved_local_match_v1';

  Future<void> save(SavedMatch match) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, match.encode());
  }

  Future<SavedMatch?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null) return null;
    try {
      return SavedMatch.decode(encoded);
    } on FormatException {
      await preferences.remove(_storageKey);
      return null;
    } on ArgumentError {
      await preferences.remove(_storageKey);
      return null;
    } on StateError {
      await preferences.remove(_storageKey);
      return null;
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
