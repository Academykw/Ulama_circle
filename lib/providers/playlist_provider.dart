import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lecture_model.dart';
import '../models/playlist_model.dart';
import '../services/playlist_service.dart';
import 'auth_provider.dart';
import 'firebase_service_provider.dart';

/// Playlist service bound to the current user, or null when signed out.
final playlistServiceProvider = Provider<PlaylistService?>((ref) {
  final uid = ref.watch(currentUidProvider);
  return uid == null ? null : PlaylistService(uid);
});

/// Live list of the user's playlists (most recent first).
final playlistsProvider = StreamProvider<List<PlaylistModel>>((ref) {
  final service = ref.watch(playlistServiceProvider);
  if (service == null) return Stream.value(const []);
  return service.watch();
});

/// A single playlist by id, resolved from the live list.
final playlistByIdProvider =
    Provider.family<PlaylistModel?, String>((ref, id) {
  final list = ref.watch(playlistsProvider).asData?.value ?? const [];
  for (final p in list) {
    if (p.id == id) return p;
  }
  return null;
});

/// Resolves lecture ids (comma-joined, for a stable family key) to lectures,
/// preserving the playlist's order.
final playlistLecturesProvider =
    FutureProvider.family<List<LectureModel>, String>((ref, idsKey) async {
  final ids = idsKey.isEmpty ? const <String>[] : idsKey.split(',');
  if (ids.isEmpty) return const [];
  final lectures = await ref.watch(firebaseServiceProvider).getLecturesByIds(ids);
  final byId = {for (final l in lectures) l.id: l};
  return [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];
});

final playlistControllerProvider =
    Provider<PlaylistController>((ref) => PlaylistController(ref));

class PlaylistController {
  PlaylistController(this._ref);
  final Ref _ref;

  PlaylistService? get _service => _ref.read(playlistServiceProvider);

  Future<String?> create(String name, {String? firstLectureId}) async =>
      _service?.create(name, firstLectureId: firstLectureId);

  Future<void> rename(String id, String name) async =>
      _service?.rename(id, name);

  Future<void> delete(String id) async => _service?.delete(id);

  Future<void> addLecture(String playlistId, String lectureId) async =>
      _service?.addLecture(playlistId, lectureId);

  Future<void> removeLecture(String playlistId, String lectureId) async =>
      _service?.removeLecture(playlistId, lectureId);
}
