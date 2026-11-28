import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/ai/seeded_ludo_ai.dart';

/// Optional setup preference, deliberately separate from saved-match authority.
class AiDifficultyPreferences {
  const AiDifficultyPreferences();
  static const storageKey = 'preferred_ai_difficulty_v1';

  Future<LudoAiDifficulty> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.get(storageKey);
    for (final difficulty in LudoAiDifficulty.values) {
      if (raw == difficulty.name) return difficulty;
    }
    return LudoAiDifficulty.medium;
  }

  Future<void> save(LudoAiDifficulty difficulty) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(storageKey, difficulty.name)) {
      throw StateError('Preferred AI difficulty could not be saved.');
    }
  }
}
