import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/lecture_model.dart';
import 'auth_provider.dart';
import 'firebase_service_provider.dart';

/// The current user's favorite lecture ids, as a set for O(1) membership checks.
/// Derived from the live `users/{uid}` doc, so it updates reactively after a
/// toggle write.
final favoriteIdsProvider = Provider<Set<String>>((ref) {
  final user = ref.watch(currentUserDocProvider).asData?.value;
  return user?.favorites.toSet() ?? const {};
});

/// Whether a specific lecture is favorited.
final isFavoriteProvider = Provider.family<bool, String>((ref, lectureId) {
  return ref.watch(favoriteIdsProvider).contains(lectureId);
});

/// Full favorite lectures, resolved from ids — powers the Library "Liked" tab.
final likedLecturesProvider = FutureProvider<List<LectureModel>>((ref) async {
  final ids = ref.watch(favoriteIdsProvider).toList();
  if (ids.isEmpty) return const [];
  final lectures =
      await ref.watch(firebaseServiceProvider).getLecturesByIds(ids);
  // Keep newest-added-ish order stable by title as a tiebreaker.
  lectures.sort((a, b) => a.title.compareTo(b.title));
  return lectures;
});

final favoritesControllerProvider =
    Provider<FavoritesController>((ref) => FavoritesController(ref));

class FavoritesController {
  FavoritesController(this._ref);
  final Ref _ref;

  /// Adds/removes a lecture from favorites via an atomic array update on the
  /// user doc. Guests have a user doc too, so this works for them as well.
  Future<void> toggle(String lectureId) async {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) return;
    final isFav = _ref.read(favoriteIdsProvider).contains(lectureId);
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'favorites': isFav
          ? FieldValue.arrayRemove([lectureId])
          : FieldValue.arrayUnion([lectureId]),
    });
  }
}
