import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/feedback_preferences.dart';

class FeedbackPreferencesStore {
  const FeedbackPreferencesStore();
  static const storageKey = 'game_feedback_preferences_v1';

  Future<FeedbackPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(storageKey);
    if (encoded == null) return const FeedbackPreferences();
    try {
      final json = jsonDecode(encoded);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Invalid feedback settings.');
      }
      return FeedbackPreferences.fromJson(json);
    } on FormatException {
      await preferences.remove(storageKey);
      return const FeedbackPreferences();
    }
  }

  Future<void> save(FeedbackPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setString(storageKey, jsonEncode(value.toJson()))) {
      throw StateError('Game feedback settings could not be saved.');
    }
  }
}
