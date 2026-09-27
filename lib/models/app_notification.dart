import 'package:cloud_firestore/cloud_firestore.dart';

/// An in-app notification shown in the bell inbox.
///
/// Two sources feed the same model:
///   - FCM messages received/tapped while the app runs, cached locally (as a
///     plain map in the app_meta box — no Hive adapter needed).
///   - `announcements` docs written by the admin panel's send — the durable
///     copy, so a message still reaches the inbox when the push is missed.
/// Both are keyed by the announcement id where there is one, so the two copies
/// of the same message de-duplicate when the inbox merges them.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final int receivedAtEpoch;
  final bool read;
  final String type; // 'general' | 'lecture' | 'reciter' | 'ramadan'

  /// FCM topic the message was sent to (announcements only; '' for local ones).
  /// Lets the inbox respect the user's per-topic preferences.
  final String topic;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAtEpoch,
    this.read = false,
    this.type = 'general',
    this.topic = '',
  });

  DateTime get receivedAt =>
      DateTime.fromMillisecondsSinceEpoch(receivedAtEpoch);

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        receivedAtEpoch: receivedAtEpoch,
        read: read ?? this.read,
        type: type,
        topic: topic,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAtEpoch': receivedAtEpoch,
        'read': read,
        'type': type,
        'topic': topic,
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        receivedAtEpoch: m['receivedAtEpoch'] as int? ?? 0,
        read: m['read'] as bool? ?? false,
        type: m['type'] as String? ?? 'general',
        topic: m['topic'] as String? ?? '',
      );

  /// An `announcements` doc sent from the admin panel. [read] is tracked
  /// locally (the doc is shared by every user), so it always starts false here.
  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? const {};
    final createdAt = m['createdAt'];
    return AppNotification(
      id: doc.id,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      // serverTimestamp() is null for a beat on the writer's own snapshot.
      receivedAtEpoch: createdAt is Timestamp
          ? createdAt.millisecondsSinceEpoch
          : DateTime.now().millisecondsSinceEpoch,
      type: m['type'] as String? ?? 'general',
      topic: m['topic'] as String? ?? '',
    );
  }
}
