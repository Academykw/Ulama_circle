import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final bool hidden;

  const CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    this.hidden = false,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CommentModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hidden: data['hidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'hidden': hidden,
      };
}
