import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_functions/cloud_functions.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_notification.dart';
import '../../models/category_model.dart';
import '../../models/lecture_model.dart';
import '../../models/reciter_model.dart';
import '../../models/recitation_model.dart';
import '../../models/sheikh_model.dart';
import '../models/daily_stat.dart';

/// All admin *writes* — the mirror of the read-only mobile FirebaseService.
/// Only admins ({admins/{uid}} marker) can run these; the Firestore rules
/// enforce it server-side.
class AdminService {
  AdminService({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  // ---- Sheikhs ----

  CollectionReference<Map<String, dynamic>> get _sheikhs =>
      _db.collection(AppConstants.sheikhsCollection);

  /// Creates a new sheikh (auto id) or updates an existing one (when [id] set).
  /// Returns the document id.
  Future<String> saveSheikh(SheikhModel sheikh, {String? id}) async {
    // Preserve the denormalized counts on edit; they're maintained elsewhere.
    final data = sheikh.toFirestore()
      ..remove('totalViews')
      ..remove('lectureCount');
    if (id == null || id.isEmpty) {
      final ref = await _sheikhs.add({
        ...data,
        'totalViews': 0,
        'lectureCount': 0,
      });
      return ref.id;
    }
    await _sheikhs.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  Future<void> deleteSheikh(String id) => _sheikhs.doc(id).delete();

  // ---- Lectures ----

  CollectionReference<Map<String, dynamic>> get _lectures =>
      _db.collection(AppConstants.lecturesCollection);

  /// Creates or updates a lecture. Keywords are (re)generated from the content
  /// so search stays consistent — the admin never types them by hand.
  Future<String> saveLecture(LectureModel lecture, {String? id}) async {
    final data = lecture.toFirestore()..['keywords'] = _keywords(lecture);
    if (id == null || id.isEmpty) {
      final ref = await _lectures.add(data);
      return ref.id;
    }
    await _lectures.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  Future<void> deleteLecture(String id) => _lectures.doc(id).delete();

  /// Distinct album/series names already used by this scholar's lectures — feeds
  /// the album autocomplete in the editor so admins reuse an exact name instead
  /// of retyping it (a typo would split one series into two albums, since the
  /// app groups albums by exact string match).
  Future<List<String>> albumsForSheikh(String sheikhId) async {
    final snap = await _lectures.where('sheikhId', isEqualTo: sheikhId).get();
    final albums = <String>{};
    for (final d in snap.docs) {
      final a = (d.data()['album'] as String?)?.trim() ?? '';
      if (a.isNotEmpty) albums.add(a);
    }
    final list = albums.toList()..sort();
    return list;
  }

  /// Uploads a lecture's audio to `lectures/{sheikhId}/…` and returns the public
  /// URL + size in MB. [onProgress] reports 0..1.
  Future<({String url, double sizeMb})> uploadAudio(
    String sheikhId,
    Uint8List bytes,
    String filename, {
    void Function(double)? onProgress,
  }) async {
    final safe = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '${AppConstants.lecturesStoragePath}/$sheikhId/${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: _audioType(filename)));
    task.snapshotEvents.listen((s) {
      if (onProgress != null && s.totalBytes > 0) {
        onProgress(s.bytesTransferred / s.totalBytes);
      }
    });
    await task;
    return (url: await ref.getDownloadURL(), sizeMb: bytes.length / (1024 * 1024));
  }

  /// Lowercase keyword set from a lecture's text — mirrors the seed's `kw()`.
  List<String> _keywords(LectureModel l) {
    return '${l.title} ${l.sheikhName} ${l.category} ${l.album}'
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2)
        .toSet()
        .toList();
  }

  /// Correct MIME type from an audio file's extension, so MP3/AAC/M4A/Opus/OGG
  /// all upload with the right content-type (and play reliably).
  String _audioType(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.m4a') || n.endsWith('.m4b') || n.endsWith('.mp4')) {
      return 'audio/mp4';
    }
    if (n.endsWith('.aac')) return 'audio/aac';
    if (n.endsWith('.opus') || n.endsWith('.ogg')) return 'audio/ogg';
    if (n.endsWith('.wav')) return 'audio/wav';
    if (n.endsWith('.flac')) return 'audio/flac';
    return 'audio/mpeg'; // .mp3 and default
  }

  // ---- Reciters & recitations ----

  CollectionReference<Map<String, dynamic>> get _reciters =>
      _db.collection(AppConstants.recitersCollection);
  CollectionReference<Map<String, dynamic>> get _recitations =>
      _db.collection(AppConstants.recitationsCollection);

  /// Create/update a reciter. surahCount/listenCount are denormalized and
  /// maintained elsewhere, so they're preserved on edit.
  Future<String> saveReciter(ReciterModel reciter, {String? id}) async {
    final data = reciter.toFirestore()
      ..remove('surahCount')
      ..remove('listenCount');
    if (id == null || id.isEmpty) {
      final ref = await _reciters.add({
        ...data,
        'surahCount': 0,
        'listenCount': 0,
      });
      return ref.id;
    }
    await _reciters.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  /// Deletes a reciter and all of its recitations (cascade).
  Future<void> deleteReciter(String id) async {
    final recs =
        await _recitations.where('reciterId', isEqualTo: id).get();
    final batch = _db.batch();
    for (final d in recs.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_reciters.doc(id));
    await batch.commit();
  }

  Future<String> saveRecitation(RecitationModel r, {String? id}) async {
    final data = r.toFirestore();
    final String recId;
    if (id == null || id.isEmpty) {
      final ref = await _recitations.add(data);
      recId = ref.id;
    } else {
      await _recitations.doc(id).set(data, SetOptions(merge: true));
      recId = id;
    }
    await _refreshSurahCount(r.reciterId);
    return recId;
  }

  Future<void> deleteRecitation(String id, String reciterId) async {
    await _recitations.doc(id).delete();
    await _refreshSurahCount(reciterId);
  }

  /// Recomputes a reciter's denormalized surah count from its recitations.
  Future<void> _refreshSurahCount(String reciterId) async {
    final snap = await _recitations
        .where('reciterId', isEqualTo: reciterId)
        .count()
        .get();
    await _reciters.doc(reciterId).set(
      {'surahCount': snap.count ?? 0},
      SetOptions(merge: true),
    );
  }

  /// Uploads recitation audio to `recitations/{reciterId}/…`.
  Future<({String url, double sizeMb})> uploadRecitationAudio(
    String reciterId,
    Uint8List bytes,
    String filename, {
    void Function(double)? onProgress,
  }) async {
    final safe = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '${AppConstants.recitationsCollection}/$reciterId/${DateTime.now().millisecondsSinceEpoch}_$safe';
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: _audioType(filename)));
    task.snapshotEvents.listen((s) {
      if (onProgress != null && s.totalBytes > 0) {
        onProgress(s.bytesTransferred / s.totalBytes);
      }
    });
    await task;
    return (url: await ref.getDownloadURL(), sizeMb: bytes.length / (1024 * 1024));
  }

  // ---- Categories ----

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(AppConstants.categoriesCollection);

  Future<String> saveCategory(CategoryModel c, {String? id}) async {
    final data = c.toFirestore();
    if (id == null || id.isEmpty) {
      final ref = await _categories.add(data);
      return ref.id;
    }
    await _categories.doc(id).set(data, SetOptions(merge: true));
    return id;
  }

  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  // ---- Push (via the sendTopicNotification Cloud Function; admin-checked there) ----

  /// Sends a push AND saves the message to `announcements`, which is what the
  /// app's in-app inbox reads. Returns the push error when the notification
  /// itself failed — the announcement is saved either way, so the message still
  /// reaches the inbox and the caller can say so.
  Future<String?> sendTopicNotification({
    required String topic,
    required String title,
    required String body,
    String type = 'general',
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('sendTopicNotification');
    final res = await callable.call<dynamic>({
      'topic': topic,
      'title': title,
      'body': body,
      'type': type,
    });
    final data = res.data;
    if (data is Map && data['pushError'] != null) {
      return data['pushError'].toString();
    }
    return null;
  }

  CollectionReference<Map<String, dynamic>> get _announcements =>
      _db.collection(AppConstants.announcementsCollection);

  /// The messages users see in the app's bell inbox, newest first.
  Stream<List<AppNotification>> watchAnnouncements() => _announcements
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.announcementsInboxLimit)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromFirestore).toList());

  /// Removes a message from every user's inbox (the push already sent can't be
  /// recalled, but the in-app copy disappears).
  Future<void> deleteAnnouncement(String id) => _announcements.doc(id).delete();

  // ---- Storage uploads (generic; e.g. scholar/reciter images) ----

  /// Document count of a collection (aggregate — cheap). For the dashboard.
  Future<int> countCollection(String name) async {
    final snap = await _db.collection(name).count().get();
    return snap.count ?? 0;
  }

  /// Count of docs matching an equality filter (aggregate).
  Future<int> countWhere(String collection, String field, Object value) async {
    final snap =
        await _db.collection(collection).where(field, isEqualTo: value).count().get();
    return snap.count ?? 0;
  }

  /// Users active within [window] — the "daily active users" metric. Relies on
  /// the mobile app's lastActiveAt ping.
  Future<int> countActiveUsers(Duration window) async {
    final since = Timestamp.fromDate(DateTime.now().subtract(window));
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('lastActiveAt', isGreaterThanOrEqualTo: since)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Users created within [window] — "new users this week". Only counts signups
  /// that have a createdAt (set from now on).
  Future<int> countNewUsers(Duration window) async {
    final since = Timestamp.fromDate(DateTime.now().subtract(window));
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('createdAt', isGreaterThanOrEqualTo: since)
        .count()
        .get();
    return snap.count ?? 0;
  }

  /// Daily play/listen rollups (from stats_daily, written by Cloud Functions),
  /// oldest-first, for the time-series chart. Empty until functions are live.
  /// Defensive: never lets a missing collection/rule break the whole dashboard.
  Future<List<DailyStat>> dailyStats({int days = 7}) async {
    try {
      final snap = await _db
          .collection('stats_daily')
          .orderBy('date', descending: true)
          .limit(days)
          .get();
      final list = snap.docs.map((d) {
        final data = d.data();
        return DailyStat(
          date: data['date'] as String? ?? d.id,
          plays: (data['plays'] as num?)?.toInt() ?? 0,
          listens: (data['listens'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      return list.reversed.toList();
    } catch (_) {
      return const [];
    }
  }

  static String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// New sign-ups per day for the last [days] days (continuous series, oldest
  /// first). Computed from users.createdAt so it's accurate retroactively.
  Future<List<({String date, int count})>> newUsersByDay({int days = 14}) async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));
      final snap = await _db
          .collection(AppConstants.usersCollection)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final ts = doc.data()['createdAt'];
        if (ts is Timestamp) {
          final key = _dayKey(ts.toDate());
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
      return [
        for (var i = days - 1; i >= 0; i--)
          (
            date: _dayKey(now.subtract(Duration(days: i))),
            count: counts[_dayKey(now.subtract(Duration(days: i)))] ?? 0,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Most-played lectures over the last [days] days (default a week), summed
  /// from the per-lecture daily rollups the Cloud Function writes. Empty until
  /// plays accrue after the functions are deployed.
  Future<List<({String title, String sheikhName, int plays})>> topLecturesInWindow({
    int days = 7,
    int limit = 8,
  }) async {
    try {
      final now = DateTime.now();
      final startKey =
          _dayKey(DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)));
      final snap = await _db
          .collection('lecture_stats_daily')
          .where('date', isGreaterThanOrEqualTo: startKey)
          .get();
      final agg = <String, ({String title, String sheikhName, int plays})>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = data['lectureId'] as String? ?? '';
        if (id.isEmpty) continue;
        final plays = (data['plays'] as num?)?.toInt() ?? 0;
        final prev = agg[id];
        agg[id] = (
          title: data['title'] as String? ?? prev?.title ?? '',
          sheikhName: data['sheikhName'] as String? ?? prev?.sheikhName ?? '',
          plays: (prev?.plays ?? 0) + plays,
        );
      }
      final list = agg.values.toList()
        ..sort((a, b) => b.plays.compareTo(a.plays));
      return list.take(limit).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Sum of a numeric field across a collection (aggregate). e.g. total plays.
  Future<int> sumField(String collection, String field) async {
    final snap = await _db.collection(collection).aggregate(sum(field)).get();
    return (snap.getSum(field) ?? 0).round();
  }

  /// Top lectures by play count (for "most listened").
  Future<List<LectureModel>> topLectures({int limit = 5}) async {
    final snap = await _db
        .collection(AppConstants.lecturesCollection)
        .orderBy('playCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(LectureModel.fromFirestore).toList();
  }

  /// Top recitations by listen count (for "most viewed").
  Future<List<RecitationModel>> topRecitations({int limit = 5}) async {
    final snap = await _db
        .collection(AppConstants.recitationsCollection)
        .orderBy('listenCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(RecitationModel.fromFirestore).toList();
  }

  /// Uploads bytes to [path] in Storage and returns the public download URL.
  Future<String> uploadBytes(
    Uint8List bytes,
    String path, {
    String contentType = 'application/octet-stream',
  }) async {
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }
}
