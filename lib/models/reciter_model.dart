import 'package:cloud_firestore/cloud_firestore.dart';

/// A Quran reciter (Qaari). Parallel to [SheikhModel] but for recitations rather
/// than lectures. `surahCount` and `listenCount` are denormalized (maintained by
/// the admin panel / a Cloud Function) so the reciters list reads cheaply.
class ReciterModel {
  final String id;
  final String name;
  final String coverUrl; // reciter artwork; '' → gradient placeholder
  final String language; // 'arabic' (with optional translation note in name)
  final String description;
  final int surahCount;
  final int listenCount;
  final int order;

  const ReciterModel({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.language,
    required this.description,
    this.surahCount = 0,
    this.listenCount = 0,
    this.order = 0,
  });

  factory ReciterModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ReciterModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      language: data['language'] as String? ?? 'arabic',
      description: data['description'] as String? ?? '',
      surahCount: data['surahCount'] as int? ?? 0,
      listenCount: data['listenCount'] as int? ?? 0,
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'coverUrl': coverUrl,
        'language': language,
        'description': description,
        'surahCount': surahCount,
        'listenCount': listenCount,
        'order': order,
      };
}
