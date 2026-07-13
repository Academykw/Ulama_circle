import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_entry.dart';
import 'local_db_provider.dart';

/// Bumped whenever history changes so dependents refresh (Hive isn't reactive
/// on its own here). PlaybackController increments it after writes.
final historyRevisionProvider =
    NotifierProvider<HistoryRevision, int>(HistoryRevision.new);

class HistoryRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state = state + 1;
}

/// Most-recent-first listening history — powers the Library "History" tab.
final historyProvider = Provider<List<HistoryEntry>>((ref) {
  ref.watch(historyRevisionProvider);
  return ref.watch(localDbServiceProvider).history();
});

/// The most recent still-in-progress lecture, for the home "Continue listening"
/// section. Null when there's nothing worth resuming.
final continueListeningProvider = Provider<HistoryEntry?>((ref) {
  final history = ref.watch(historyProvider);
  for (final entry in history) {
    if (entry.isResumable) return entry;
  }
  return null;
});
