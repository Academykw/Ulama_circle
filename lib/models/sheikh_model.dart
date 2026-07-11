import 'package:cloud_firestore/cloud_firestore.dart';

class SheikhModel {
  final String id;
  final String name;
  final String photoUrl;
  final String language; // yoruba | hausa | english
  final String bio;
  final int order;

  const SheikhModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.language,
    required this.bio,
    required this.order,
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
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'photoUrl': photoUrl,
        'language': language,
        'bio': bio,
        'order': order,
      };

  /// FCM topic name for "notify me about new lectures from this sheikh".
  String get subscriberTopic => 'sheikh_$id';
}
