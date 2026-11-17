import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/player_color.dart';
import '../../domain/player_name.dart';

/// Preferred human display names for the next local setup, separate from saves.
class PlayerNamePreferences {
  const PlayerNamePreferences();
  static const storageKey = 'preferred_player_names_v1';

  Future<Map<PlayerColor, String>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return {};
    try {
      final value = jsonDecode(encoded);
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid name preferences.');
      }
      final result = <PlayerColor, String>{};
      for (final entry in value.entries) {
        if (entry.value is! String) {
          throw const FormatException('Invalid preferred name.');
        }
        result[PlayerColor.values.byName(entry.key)] =
            PlayerName.parse(entry.value as String);
      }
      return result;
    } on FormatException {
      await preferences.remove(storageKey);
      return {};
    } on ArgumentError {
      await preferences.remove(storageKey);
      return {};
    }
  }

  Future<void> save(Map<PlayerColor, String> names) async {
    final normalized = {
      for (final entry in names.entries)
        entry.key.name: PlayerName.parse(entry.value),
    };
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(storageKey, jsonEncode(normalized))) {
      throw StateError('Player name preferences could not be saved.');
    }
  }
}
