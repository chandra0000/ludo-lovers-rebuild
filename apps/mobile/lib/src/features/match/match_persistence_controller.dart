import 'package:flutter/foundation.dart';

import '../../game/domain/persistence/saved_match.dart';
import '../../game/infrastructure/persistence/saved_match_store.dart';

/// Serializes match snapshots so earlier asynchronous writes cannot overwrite
/// newer accepted states. A failed write does not poison subsequent saves.
class MatchPersistenceController {
  MatchPersistenceController({Future<void> Function(SavedMatch)? save})
      : _save = save ?? const SavedMatchStore().save;

  final Future<void> Function(SavedMatch) _save;
  Future<void> _queue = Future<void>.value();

  /// Outcome of the last completed write; null before the first completion.
  bool? get lastSaveSucceeded => _lastSaveSucceeded;
  bool? _lastSaveSucceeded;

  Future<void> persist(SavedMatch snapshot) {
    _queue = _queue.then((_) async {
      try {
        await _save(snapshot);
        _lastSaveSucceeded = true;
      } catch (error) {
        _lastSaveSucceeded = false;
        debugPrint('Could not persist local match: $error');
      }
    });
    return _queue;
  }
}
