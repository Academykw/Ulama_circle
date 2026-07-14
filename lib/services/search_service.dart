import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_constants.dart';
import '../models/lecture_model.dart';

/// Lecture search. Backed by Firestore keyword matching (the lowercase
/// `keywords` array on each lecture, which includes title words, sheikh,
/// category, language and album).
///
/// The plan is to later swap this to the "Search with Algolia" Firebase
/// Extension for typo-tolerance and better relevance. That's an isolated change
/// to THIS class only — the search screen/providers stay the same.
class SearchService {
  SearchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _lectures =>
      _db.collection(AppConstants.lecturesCollection);

  /// Returns lectures matching [query], ranked by how many query terms they hit.
  /// Uses `array-contains-any` on `keywords` (auto-indexed, no composite index
  /// needed). Whole-word matching only — Algolia adds partial/typo later.
  Future<List<LectureModel>> search(String query, {int limit = 25}) async {
    final tokens = _tokenize(query);
    if (tokens.isEmpty) return const [];

    // array-contains-any supports up to 30 values.
    final terms = tokens.take(30).toList();
    final snap = await _lectures
        .where('keywords', arrayContainsAny: terms)
        .limit(limit)
        .get();

    final results = snap.docs.map(LectureModel.fromFirestore).toList();
    results.sort((a, b) => _score(b, tokens).compareTo(_score(a, tokens)));
    return results;
  }

  List<String> _tokenize(String query) => query
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length > 1)
      .toList();

  /// Relevance score: +1 per matching keyword, +1 per token found in the title.
  int _score(LectureModel lecture, List<String> tokens) {
    final keywords = lecture.keywords.toSet();
    final title = lecture.title.toLowerCase();
    var score = 0;
    for (final t in tokens) {
      if (keywords.contains(t)) score++;
      if (title.contains(t)) score++;
    }
    return score;
  }
}
