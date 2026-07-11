import 'package:cloud_firestore/cloud_firestore.dart';

class PlaylistModel {
  final String id;
  final String name;
  final List<String> lectureIds;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.lectureIds,
  });

  factory PlaylistModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PlaylistModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      lectureIds: List<String>.from(data['lectureIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lectureIds': lectureIds,
      };

  PlaylistModel copyWithAddedLecture(String lectureId) {
    if (lectureIds.contains(lectureId)) return this;
    return PlaylistModel(id: id, name: name, lectureIds: [...lectureIds, lectureId]);
  }

  PlaylistModel copyWithRemovedLecture(String lectureId) {
    return PlaylistModel(
      id: id,
      name: name,
      lectureIds: lectureIds.where((id) => id != lectureId).toList(),
    );
  }
}
