import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.order,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      order: data['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'order': order,
      };
}
