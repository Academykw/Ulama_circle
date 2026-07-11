import 'package:cloud_firestore/cloud_firestore.dart';

class LectureModel {
  final String id;
  final String title;
  final String sheikhId;
  final String sheikhName; // denormalized — avoids an extra read per lecture
  final String audioUrl;
  final int durationSeconds;
  final String language; // yoruba | hausa | english
  final String category;
  final bool isFeatured;
  final DateTime dateAdded;
  final double fileSizeMb;
  final List<String> keywords; // powers Firestore-side filtering; Algolia is the primary search path
  final int commentCount;
  final int playCount;

  const LectureModel({
    required this.id,
    required this.title,
    required this.sheikhId,
    required this.sheikhName,
    required this.audioUrl,
    required this.durationSeconds,
    required this.language,
    required this.category,
    required this.isFeatured,
    required this.dateAdded,
    required this.fileSizeMb,
    this.keywords = const [],
    this.commentCount = 0,
    this.playCount = 0,
  });

  factory LectureModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return LectureModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      sheikhId: data['sheikhId'] as String? ?? '',
      sheikhName: data['sheikhName'] as String? ?? '',
      audioUrl: data['audioUrl'] as String? ?? '',
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      language: data['language'] as String? ?? 'english',
      category: data['category'] as String? ?? '',
      isFeatured: data['isFeatured'] as bool? ?? false,
      dateAdded: (data['dateAdded'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileSizeMb: (data['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
      keywords: List<String>.from(data['keywords'] as List? ?? const []),
      commentCount: data['commentCount'] as int? ?? 0,
      playCount: data['playCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'sheikhId': sheikhId,
        'sheikhName': sheikhName,
        'audioUrl': audioUrl,
        'durationSeconds': durationSeconds,
        'language': language,
        'category': category,
        'isFeatured': isFeatured,
        'dateAdded': Timestamp.fromDate(dateAdded),
        'fileSizeMb': fileSizeMb,
        'keywords': keywords,
        'commentCount': commentCount,
        'playCount': playCount,
      };
}
