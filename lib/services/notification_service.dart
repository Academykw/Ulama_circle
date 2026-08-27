import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import 'local_db_service.dart';

/// Must be a top-level function. For notification-payload messages the OS shows
/// the system tray notification automatically while the app is backgrounded or
/// terminated, so there's nothing to do here yet — kept as the required hook.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally minimal — see the doc comment above.
}

/// Wraps Firebase Cloud Messaging: permission, topic subscriptions, and routing
/// incoming messages into the local notifications inbox ([LocalDbService]).
class NotificationService {
  NotificationService(this._db);

  final LocalDbService _db;
  final _fcm = FirebaseMessaging.instance;

  /// Call once at startup (after Firebase + Hive are ready).
  Future<void> init() async {
    await _fcm.requestPermission();

    // Foreground messages: the OS won't show a tray notification, so we record
    // it in the inbox ourselves.
    FirebaseMessaging.onMessage.listen(_record);

    // App opened from a background notification tap.
    FirebaseMessaging.onMessageOpenedApp.listen(_record);

    // App launched from a terminated-state notification tap.
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _record(initial);

    // Sync topic subscriptions to the saved preferences.
    for (final t in AppConstants.notificationTopics) {
      await _applyTopic(t.topic, _db.notifPref(t.topic));
    }
  }

  Future<void> _record(RemoteMessage message) async {
    final n = message.notification;
    final data = message.data;
    final title = n?.title ?? data['title'] ?? 'Ulama Circle';
    final body = n?.body ?? data['body'] ?? '';
    if (title.isEmpty && body.isEmpty) return;
    await _db.addNotification(AppNotification(
      id: message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      receivedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      type: data['type'] ?? 'general',
    ));
  }

  /// Toggle a topic subscription and persist the preference.
  Future<void> setTopicEnabled(String topic, bool enabled) async {
    await _db.setNotifPref(topic, enabled);
    await _applyTopic(topic, enabled);
  }

  Future<void> _applyTopic(String topic, bool enabled) async {
    try {
      if (enabled) {
        await _fcm.subscribeToTopic(topic);
      } else {
        await _fcm.unsubscribeFromTopic(topic);
      }
    } catch (e) {
      // Topic (un)subscription needs network; failures are non-fatal — the saved
      // preference is the source of truth and re-syncs on next launch.
      debugPrint('FCM topic "$topic" toggle failed: $e');
    }
  }
}
