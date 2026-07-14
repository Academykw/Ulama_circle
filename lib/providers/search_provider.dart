import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lecture_model.dart';
import '../services/search_service.dart';

final searchServiceProvider = Provider<SearchService>((ref) => SearchService());

/// The current search query. The search screen updates this (debounced).
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
}

/// Results for the current query. autoDispose so results reset when the search
/// screen closes. Empty for queries shorter than 2 chars.
final searchResultsProvider =
    FutureProvider.autoDispose<List<LectureModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.length < 2) return const [];
  return ref.watch(searchServiceProvider).search(query);
});
