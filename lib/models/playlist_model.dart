import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistModel {
  final String id;
  final String name;
  final List<String> lectureIds;
  final DateTime? createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.lectureIds,
    this.createdAt,
  });

  int get count => lectureIds.length;

  factory PlaylistModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PlaylistModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      lectureIds: List<String>.from(data['lectureIds'] as List? ?? const []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// A stable key of the lecture ids, for caching resolved lectures.
  String get idsKey => lectureIds.join(',');
}
