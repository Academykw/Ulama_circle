import 'lecture_model.dart';

/// One "recently played" entry — powers the History tab and resume/continue
/// listening. Stored locally (Hive app_meta) as a plain map so no Hive adapter
/// is needed. Carries enough lecture info to render offline and to resume.
class HistoryEntry {
  final String id;
  final String title;
  final String sheikhId;
  final String sheikhName;
  final String audioUrl;
  final String language;
  final String category;
  final int positionSeconds;
  final int durationSeconds;
  final int lastPlayedEpoch;

  const HistoryEntry({
    required this.id,
    required this.title,
    required this.sheikhId,
    required this.sheikhName,
    required this.audioUrl,
    required this.language,
    required this.category,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.lastPlayedEpoch,
  });

  double get progress => durationSeconds > 0
      ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  /// True when there's a meaningful resume point (started, not basically done).
  bool get isResumable =>
      positionSeconds > 5 &&
      (durationSeconds == 0 || durationSeconds - positionSeconds > 10);

  DateTime get lastPlayed =>
      DateTime.fromMillisecondsSinceEpoch(lastPlayedEpoch);

  HistoryEntry copyWith({int? positionSeconds, int? durationSeconds, int? lastPlayedEpoch}) {
    return HistoryEntry(
      id: id,
      title: title,
      sheikhId: sheikhId,
      sheikhName: sheikhName,
      audioUrl: audioUrl,
      language: language,
      category: category,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      lastPlayedEpoch: lastPlayedEpoch ?? this.lastPlayedEpoch,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'sheikhId': sheikhId,
        'sheikhName': sheikhName,
        'audioUrl': audioUrl,
        'language': language,
        'category': category,
        'position': positionSeconds,
        'duration': durationSeconds,
        'lastPlayed': lastPlayedEpoch,
      };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) => HistoryEntry(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        sheikhId: map['sheikhId'] as String? ?? '',
        sheikhName: map['sheikhName'] as String? ?? '',
        audioUrl: map['audioUrl'] as String? ?? '',
        language: map['language'] as String? ?? '',
        category: map['category'] as String? ?? '',
        positionSeconds: (map['position'] as num?)?.toInt() ?? 0,
        durationSeconds: (map['duration'] as num?)?.toInt() ?? 0,
        lastPlayedEpoch: (map['lastPlayed'] as num?)?.toInt() ?? 0,
      );

  /// Rebuilds a LectureModel good enough to resume playback (id resolves the
  /// local cache; audioUrl covers the not-yet-cached case).
  LectureModel toLecture() => LectureModel(
        id: id,
        title: title,
        sheikhId: sheikhId,
        sheikhName: sheikhName,
        audioUrl: audioUrl,
        durationSeconds: durationSeconds,
        language: language,
        category: category,
        isFeatured: false,
        dateAdded: DateTime.now(),
        fileSizeMb: 0,
      );
}
