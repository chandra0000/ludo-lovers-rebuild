import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/persistence/saved_match.dart';

class SavedMatchStore {
  const SavedMatchStore();

  static const _storageKey = 'saved_local_match_v1';

  Future<void> save(SavedMatch match) async {
    final preferences = await SharedPreferences.getInstance();
    final persisted = await preferences.setString(_storageKey, match.encode());
    if (!persisted) {
      throw StateError('Local match storage rejected the write');
    }
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
