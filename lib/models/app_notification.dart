/// An in-app notification shown in the bell inbox. Stored locally (as a plain
/// map in the app_meta box — no Hive adapter needed) as messages arrive via FCM.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final int receivedAtEpoch;
  final bool read;
  final String type; // 'general' | 'lecture' | 'reciter' | 'ramadan'

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAtEpoch,
    this.read = false,
    this.type = 'general',
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
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'receivedAtEpoch': receivedAtEpoch,
        'read': read,
        'type': type,
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String? ?? '',
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        receivedAtEpoch: m['receivedAtEpoch'] as int? ?? 0,
        read: m['read'] as bool? ?? false,
        type: m['type'] as String? ?? 'general',
      );
}
