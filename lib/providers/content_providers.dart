import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/lecture_model.dart';
import '../models/sheikh_model.dart';
import 'firebase_service_provider.dart';

/// Day 6: Riverpod providers wired to live Firestore data. These are what the
/// Day 8+ home screen and browsing screens consume — screens never call
/// FirebaseService directly.

// --- Sheikhs & categories: live streams (small bounded sets) ---

final sheikhsProvider = StreamProvider<List<SheikhModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchSheikhs();
});

final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(firebaseServiceProvider).watchCategories();
});

/// A single sheikh by id (for detail headers). Resolves from the already-loaded
/// sheikhs stream when possible, so it doesn't cost an extra read.
final sheikhByIdProvider = Provider.family<SheikhModel?, String>((ref, id) {
  final sheikhs = ref.watch(sheikhsProvider).value;
  if (sheikhs == null) return null;
  for (final s in sheikhs) {
    if (s.id == id) return s;
  }
  return null;
});

/// Server-side count of a sheikh's lectures — for the sheikh detail header.
final sheikhLectureCountProvider =
    FutureProvider.family<int, String>((ref, sheikhId) {
  return ref.watch(firebaseServiceProvider).getSheikhLectureCount(sheikhId);
});

// --- Per-sheikh preview: first page of a sheikh's lectures for home rows ---

/// First page (~10) of a sheikh's lectures, for the horizontal row on Home.
/// The full paginated list lives on the sheikh detail screen.
final sheikhPreviewLecturesProvider =
    FutureProvider.family<List<LectureModel>, String>((ref, sheikhId) async {
  final page = await ref
      .watch(firebaseServiceProvider)
      .getLecturesBySheikh(sheikhId, pageSize: 10);
  return page.items;
});

// --- Featured lectures: home banner (bounded, refreshable) ---

final featuredLecturesProvider = FutureProvider<List<LectureModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getFeaturedLectures();
});

// --- Trending: most-played lectures for the home "Trending Now" row ---

final trendingLecturesProvider = FutureProvider<List<LectureModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getTrendingLectures();
});

/// Larger trending list for the full Trending screen (home row uses the small
/// one above).
final allTrendingLecturesProvider = FutureProvider<List<LectureModel>>((ref) {
  return ref.watch(firebaseServiceProvider).getTrendingLectures(limit: 60);
});

// --- Ramadan: curated picks (Tafsir + Seerah) for the Ramadan collection ---

/// Lectures for the Ramadan hub — Tafsir + Seerah, merged and de-duplicated.
/// A dedicated `ramadan` tag can replace this later without touching the UI.
final ramadanLecturesProvider = FutureProvider<List<LectureModel>>((ref) async {
  final svc = ref.watch(firebaseServiceProvider);
  final results = await Future.wait([
    svc.getLecturesByCategory('tafsir'),
    svc.getLecturesByCategory('seerah'),
  ]);
  final seen = <String>{};
  return [
    for (final page in results)
      for (final l in page.items)
        if (seen.add(l.id)) l,
  ];
});

// --- Latest lectures: paginated home feed ---

final latestLecturesProvider =
    AsyncNotifierProvider<LatestLecturesController, List<LectureModel>>(
  LatestLecturesController.new,
);

/// Paginated controller for the "latest lectures" feed. `build()` loads the
/// first page; the UI calls [loadMore] when the user scrolls near the bottom.
///
/// Pagination cursor + hasMore live as fields on the notifier (not in the
/// AsyncValue) so the exposed state stays a clean `List<LectureModel>`.
class LatestLecturesController extends AsyncNotifier<List<LectureModel>> {
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<LectureModel>> build() async {
    final page = await ref.watch(firebaseServiceProvider).getLatestLectures();
    _cursor = page.lastDoc;
    _hasMore = page.hasMore;
    return page.items;
  }

  /// Fetch and append the next page. No-op while a load is in flight or once
  /// the end is reached.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.value ?? const [];
    _isLoadingMore = true;
    try {
      final page = await ref
          .read(firebaseServiceProvider)
          .getLatestLectures(startAfter: _cursor);
      _cursor = page.lastDoc;
      _hasMore = page.hasMore;
      state = AsyncData([...current, ...page.items]);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Pull-to-refresh: reset cursor and reload from the top.
  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref.read(firebaseServiceProvider).getLatestLectures();
      _cursor = page.lastDoc;
      _hasMore = page.hasMore;
      return page.items;
    });
  }
}
