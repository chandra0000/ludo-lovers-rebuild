import 'dart:convert';

import '../ai/seeded_ludo_ai.dart';
import '../ludo_game.dart';
import '../player_color.dart';
import '../match_player_profile.dart';

/// Stores one local match so the app can recover after backgrounding or
/// process recreation. This is local-device persistence, not cloud sync.
class SavedMatch {
  SavedMatch({
    required this.game,
    required Set<PlayerColor> aiPlayers,
    required this.aiSeed,
    this.aiDifficulty = LudoAiDifficulty.medium,
    List<MatchPlayerProfile>? profiles,
  })  : aiPlayers = Set<PlayerColor>.unmodifiable(aiPlayers),
        profiles = MatchPlayerProfile.roster(
          profiles ?? MatchPlayerProfile.local(aiPlayers: aiPlayers),
          aiPlayers: aiPlayers,
        );

  final LudoGame game;
  final Set<PlayerColor> aiPlayers;
  final int aiSeed;
  final LudoAiDifficulty aiDifficulty;
  final List<MatchPlayerProfile> profiles;

  Map<String, Object?> toJson() => {
        'schemaVersion': 3,
        'profiles': profiles.map((profile) => profile.toJson()).toList(),
        'game': game.toSnapshot(),
        'aiPlayers': aiPlayers.map((player) => player.name).toList()..sort(),
        'aiSeed': aiSeed,
        'aiDifficulty': aiDifficulty.name,
      };

  factory SavedMatch.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if ((schemaVersion != 1 && schemaVersion != 2 && schemaVersion != 3) ||
        json['game'] is! Map<String, dynamic> ||
        json['aiPlayers'] is! List ||
        json['aiSeed'] is! int ||
        (schemaVersion != 1 && json['aiDifficulty'] is! String) ||
        (schemaVersion == 3 && json['profiles'] is! List)) {
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
    final difficultyName = schemaVersion != 1
        ? json['aiDifficulty'] as String
        : LudoAiDifficulty.medium.name;
    final difficulty = LudoAiDifficulty.values.firstWhere(
      (value) => value.name == difficultyName,
      orElse: () => throw const FormatException('Unknown saved AI difficulty.'),
    );
    return SavedMatch(
      game: LudoGame.fromSnapshot(json['game'] as Map<String, dynamic>),
      aiPlayers: Set<PlayerColor>.unmodifiable(aiPlayers),
      aiSeed: json['aiSeed'] as int,
      aiDifficulty: difficulty,
      profiles: schemaVersion == 3
          ? (json['profiles'] as List).map((value) {
              if (value is! Map<String, dynamic>) {
                throw const FormatException('Malformed player profile.');
              }
              return MatchPlayerProfile.fromJson(value);
            }).toList()
          : null,
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
