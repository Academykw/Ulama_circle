import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a `users/{uid}` document. Named `AppUser` to avoid colliding with
/// Firebase Auth's own `User` type.
class AppUser {
  final String uid;
  final String displayName;
  final bool isGuest;
  final List<String> favorites;
  final String avatarEmoji; // user-chosen emoji avatar; '' = default icon

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.isGuest,
    this.favorites = const [],
    this.avatarEmoji = '',
  });

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? '',
      isGuest: data['isGuest'] as bool? ?? false,
      favorites: List<String>.from(data['favorites'] as List? ?? const []),
      avatarEmoji: data['avatarEmoji'] as String? ?? '',
    );
  }

  /// Written on first sign-in. `history` lives here too per the schema but is
  /// updated by the player later, so it starts empty.
  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'isGuest': isGuest,
        'favorites': favorites,
        'avatarEmoji': avatarEmoji,
        'history': const [],
      };
}
