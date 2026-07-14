import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhModel {
  final String id;
  final String name;
  final String photoUrl;
  final String language; // yoruba | hausa | english
  final String bio;
  final int order;
  final int totalViews; // denormalized sum of this scholar's lecture plays
  final int lectureCount; // denormalized count of this scholar's lectures

  const SheikhModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.language,
    required this.bio,
    required this.order,
    this.totalViews = 0,
    this.lectureCount = 0,
  });

  factory SheikhModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SheikhModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      language: data['language'] as String? ?? 'english',
      bio: data['bio'] as String? ?? '',
      order: data['order'] as int? ?? 0,
      totalViews: data['totalViews'] as int? ?? 0,
      lectureCount: data['lectureCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'photoUrl': photoUrl,
        'language': language,
        'bio': bio,
        'order': order,
        'totalViews': totalViews,
        'lectureCount': lectureCount,
      };

  /// FCM topic name for "notify me about new lectures from this sheikh".
  String get subscriberTopic => 'sheikh_$id';
}
