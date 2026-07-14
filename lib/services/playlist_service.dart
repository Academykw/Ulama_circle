import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/playlist_model.dart';

/// CRUD for a user's playlists at `users/{uid}/playlists/{id}`. Owner-only per
/// the Firestore rules. Works for guests too (they have a user doc).
class PlaylistService {
  PlaylistService(this._uid, {FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String _uid;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col => _db
      .collection(AppConstants.usersCollection)
      .doc(_uid)
      .collection(AppConstants.playlistsSubcollection);

  Stream<List<PlaylistModel>> watch() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(PlaylistModel.fromFirestore).toList());

  Future<String> create(String name, {String? firstLectureId}) async {
    final ref = await _col.add({
      'name': name.trim(),
      'lectureIds': firstLectureId != null ? [firstLectureId] : <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> rename(String id, String name) =>
      _col.doc(id).update({'name': name.trim()});

  Future<void> delete(String id) => _col.doc(id).delete();

  Future<void> addLecture(String playlistId, String lectureId) => _col
      .doc(playlistId)
      .update({'lectureIds': FieldValue.arrayUnion([lectureId])});

  Future<void> removeLecture(String playlistId, String lectureId) => _col
      .doc(playlistId)
      .update({'lectureIds': FieldValue.arrayRemove([lectureId])});
}
