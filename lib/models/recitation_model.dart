import 'package:cloud_firestore/cloud_firestore.dart';

import 'lecture_model.dart';

/// One surah recitation by a reciter. Stored like a lecture (has audio +
/// duration) so it plays through the exact same pipeline — [toLecture] adapts it
/// to the [LectureModel] the player/queue/mini-player all speak.
class RecitationModel {
  final String id;
  final String reciterId;
  final String reciterName;
  final String coverUrl;
  final String title; // e.g. "Recitation Of Qur'an (105) Suratul Fil"
  final int surahNumber;
  final String kind; // 'surah' | 'juz' | 'mushaf'
  final String audioUrl;
  final int durationSeconds;
  final int order;
  final int listenCount;

  const RecitationModel({
    required this.id,
    required this.reciterId,
    required this.reciterName,
    required this.coverUrl,
    required this.title,
    required this.audioUrl,
    required this.durationSeconds,
    this.surahNumber = 0,
    this.kind = 'surah',
    this.order = 0,
    this.listenCount = 0,
  });

  /// Human label for the recitation type.
  String get kindLabel => switch (kind) {
        'juz' => 'Juz',
        'mushaf' => 'Full mushaf',
        _ => 'Surah',
      };

  factory RecitationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RecitationModel(
      id: doc.id,
      reciterId: data['reciterId'] as String? ?? '',
      reciterName: data['reciterName'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      title: data['title'] as String? ?? '',
      surahNumber: data['surahNumber'] as int? ?? 0,
      kind: data['kind'] as String? ?? 'surah',
      audioUrl: data['audioUrl'] as String? ?? '',
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      order: data['order'] as int? ?? 0,
      listenCount: data['listenCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'reciterId': reciterId,
        'reciterName': reciterName,
        'coverUrl': coverUrl,
        'title': title,
        'surahNumber': surahNumber,
        'kind': kind,
        'audioUrl': audioUrl,
        'durationSeconds': durationSeconds,
        'order': order,
        'listenCount': listenCount,
      };

  /// Adapt to a [LectureModel] so the existing player/queue/history handle it
  /// with no special-casing. Recitation ids are namespaced ("rec_...") so they
  /// never collide with lecture ids in downloads/history.
  ///
  /// [artwork] overrides the cover — play sites pass the reciter's *current*
  /// photo so the Now Playing art stays correct even if this recitation doc's
  /// own coverUrl is stale.
  LectureModel toLecture({String? artwork}) => LectureModel(
        id: id,
        title: title,
        sheikhId: reciterId,
        sheikhName: reciterName,
        audioUrl: audioUrl,
        durationSeconds: durationSeconds,
        language: 'arabic',
        category: 'Quran',
        isFeatured: false,
        dateAdded: DateTime.now(),
        fileSizeMb: 0,
        playCount: listenCount,
        artworkUrl: artwork ?? coverUrl,
      );
}
