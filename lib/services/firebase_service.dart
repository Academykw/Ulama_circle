import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/category_model.dart';
import '../models/lecture_model.dart';
import '../models/reciter_model.dart';
import '../models/recitation_model.dart';
import '../models/sheikh_model.dart';

/// One page of results plus the cursor needed to fetch the next page.
///
/// [lastDoc] is the raw Firestore snapshot of the final item — pass it back in
/// as `startAfter` to continue. [hasMore] is false once a page comes back
/// smaller than the requested size (the end of the collection).
class PaginatedResult<T> {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  static PaginatedResult<T> empty<T>() =>
      const PaginatedResult(items: [], lastDoc: null, hasMore: false);
}

/// All Firestore *reads* for content (lectures, sheikhs, categories) live here.
/// Writes are the admin panel's job (Week 4); this service is read-only so the
/// mobile app never accidentally mutates content.
///
/// Design rules from the spec's scaling notes:
///   - Never `.get()` a whole collection — every lecture list is paginated.
///   - Sheikhs and categories are small, bounded sets, so those stream whole.
class FirebaseService {
  FirebaseService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lectures =>
      _db.collection(AppConstants.lecturesCollection);
  CollectionReference<Map<String, dynamic>> get _sheikhs =>
      _db.collection(AppConstants.sheikhsCollection);
  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection(AppConstants.categoriesCollection);
  CollectionReference<Map<String, dynamic>> get _reciters =>
      _db.collection(AppConstants.recitersCollection);
  CollectionReference<Map<String, dynamic>> get _recitations =>
      _db.collection(AppConstants.recitationsCollection);

  // ---------------------------------------------------------------------------
  // Sheikhs & categories — small bounded sets, safe to stream whole (ordered).
  // ---------------------------------------------------------------------------

  Stream<List<SheikhModel>> watchSheikhs() => _sheikhs
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(SheikhModel.fromFirestore).toList());

  Future<List<SheikhModel>> getSheikhs() async {
    final snap = await _sheikhs.orderBy('order').get();
    return snap.docs.map(SheikhModel.fromFirestore).toList();
  }

  Future<SheikhModel?> getSheikh(String id) async {
    final doc = await _sheikhs.doc(id).get();
    return doc.exists ? SheikhModel.fromFirestore(doc) : null;
  }

  /// Server-side count of a sheikh's lectures (aggregate query — cheap, doesn't
  /// read the docs). Powers the "X lectures" header.
  Future<int> getSheikhLectureCount(String sheikhId) async {
    final snap =
        await _lectures.where('sheikhId', isEqualTo: sheikhId).count().get();
    return snap.count ?? 0;
  }

  Stream<List<CategoryModel>> watchCategories() => _categories
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(CategoryModel.fromFirestore).toList());

  Future<List<CategoryModel>> getCategories() async {
    final snap = await _categories.orderBy('order').get();
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  // ---------------------------------------------------------------------------
  // Quran reciters & recitations — reciters stream whole (small bounded set);
  // a reciter's surahs are bounded (≤114), so we read them in one ordered query.
  // ---------------------------------------------------------------------------

  Stream<List<ReciterModel>> watchReciters() => _reciters
      .orderBy('order')
      .snapshots()
      .map((s) => s.docs.map(ReciterModel.fromFirestore).toList());

  Future<List<ReciterModel>> getReciters() async {
    final snap = await _reciters.orderBy('order').get();
    return snap.docs.map(ReciterModel.fromFirestore).toList();
  }

  /// A reciter's surahs. Bounded by [limit] (a full mushaf is 114), so we sort
  /// by `order` client-side — avoids a composite index for one equality query.
  Future<List<RecitationModel>> getRecitationsByReciter(
    String reciterId, {
    int limit = 200,
  }) async {
    final snap = await _recitations
        .where('reciterId', isEqualTo: reciterId)
        .limit(limit)
        .get();
    final list = snap.docs.map(RecitationModel.fromFirestore).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  // ---------------------------------------------------------------------------
  // Lectures — always paginated or limited.
  // ---------------------------------------------------------------------------

  /// Featured lectures for the home banner. Bounded by [limit] (default 10) so
  /// it's cheap; ordered newest-first.
  Future<List<LectureModel>> getFeaturedLectures({
    int limit = AppConstants.featuredLecturesLimit,
  }) async {
    final snap = await _lectures
        .where('isFeatured', isEqualTo: true)
        .orderBy('dateAdded', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(LectureModel.fromFirestore).toList();
  }

  /// Most-played lectures for the "Trending Now" home row. Bounded by [limit];
  /// ordered by playCount desc. Single-field order — no composite index needed.
  Future<List<LectureModel>> getTrendingLectures({int limit = 12}) async {
    final snap = await _lectures
        .orderBy('playCount', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(LectureModel.fromFirestore).toList();
  }

  /// A single lecture (e.g. resolving a deep link or a search hit).
  Future<LectureModel?> getLecture(String id) async {
    final doc = await _lectures.doc(id).get();
    return doc.exists ? LectureModel.fromFirestore(doc) : null;
  }

  /// Resolve several lectures by id (used by playlists / favorites). Firestore
  /// `whereIn` caps at 30 ids, so we chunk. Order of the returned list is not
  /// guaranteed to match [ids].
  Future<List<LectureModel>> getLecturesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    const chunkSize = 30;
    final results = <LectureModel>[];
    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
          i, i + chunkSize > ids.length ? ids.length : i + chunkSize);
      final snap =
          await _lectures.where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snap.docs.map(LectureModel.fromFirestore));
    }
    return results;
  }

  /// Latest lectures across all sheikhs — paginated. Pass the previous page's
  /// [startAfter] cursor to load the next page.
  Future<PaginatedResult<LectureModel>> getLatestLectures({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    var query =
        _lectures.orderBy('dateAdded', descending: true).limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return _runPaged(query, pageSize);
  }

  /// Lectures by a given sheikh — paginated, newest-first.
  Future<PaginatedResult<LectureModel>> getLecturesBySheikh(
    String sheikhId, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    var query = _lectures
        .where('sheikhId', isEqualTo: sheikhId)
        .orderBy('dateAdded', descending: true)
        .limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return _runPaged(query, pageSize);
  }

  /// Lectures in a given category — paginated, newest-first.
  Future<PaginatedResult<LectureModel>> getLecturesByCategory(
    String category, {
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = AppConstants.defaultPageSize,
  }) {
    var query = _lectures
        .where('category', isEqualTo: category)
        .orderBy('dateAdded', descending: true)
        .limit(pageSize);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return _runPaged(query, pageSize);
  }

  /// Runs a limited query and wraps it in a [PaginatedResult]. [hasMore] is
  /// inferred from whether the page came back full.
  Future<PaginatedResult<LectureModel>> _runPaged(
    Query<Map<String, dynamic>> query,
    int pageSize,
  ) async {
    final snap = await query.get();
    final items = snap.docs.map(LectureModel.fromFirestore).toList();
    return PaginatedResult(
      items: items,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }
}
