import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import 'firebase_service_provider.dart';
import 'local_db_provider.dart';

/// The NotificationService, built on the shared LocalDbService. Initialized in
/// main(); this provider exposes the instance for topic toggles.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(localDbServiceProvider));
});

/// Admin-sent announcements from Firestore, newest first. The durable half of
/// the inbox: present even when the push was never delivered or tapped, and on
/// a freshly installed device.
final announcementsProvider = StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(firebaseServiceProvider).watchAnnouncements();
});

/// The bell inbox: Firestore announcements merged with the FCM messages cached
/// locally, newest first.
///
/// Rules of the merge:
///   - de-duplicate by id, preferring the Firestore copy (it has the topic and
///     the server timestamp); the FCM copy of an announcement carries the same
///     doc id, so the two collapse into one row.
///   - drop announcements for topics the user has switched off, and ones
///     cleared on this device.
///   - read state for announcements comes from the local id set, since the docs
///     are shared by every user.
///
/// Watches [announcementsProvider] for the server side and the Hive listenable
/// for the local side, so it rebuilds on either.
final inboxProvider = Provider<List<AppNotification>>((ref) {
  final db = ref.watch(localDbServiceProvider);
  // Rebuild when the local cache or the read/dismissed sets change.
  ref.watch(_localInboxRevisionProvider);

  final readIds = db.readAnnouncementIds();
  final dismissed = db.dismissedAnnouncementIds();
  final togglable = {for (final t in AppConstants.notificationTopics) t.topic};

  final merged = <String, AppNotification>{};
  for (final n in db.notifications()) {
    merged[n.id] = n;
  }
  final announcements =
      ref.watch(announcementsProvider).value ?? const <AppNotification>[];
  for (final a in announcements) {
    if (dismissed.contains(a.id)) {
      merged.remove(a.id);
      continue;
    }
    // Only the user-facing topics are filterable; anything else always shows.
    if (togglable.contains(a.topic) && !db.notifPref(a.topic)) {
      merged.remove(a.id);
      continue;
    }
    merged[a.id] = a.copyWith(read: readIds.contains(a.id));
  }

  final items = merged.values.toList()
    ..sort((a, b) => b.receivedAtEpoch.compareTo(a.receivedAtEpoch));
  return items;
});

/// Unread count for the header bell badge.
final unreadInboxCountProvider = Provider<int>((ref) {
  return ref.watch(inboxProvider).where((n) => !n.read).length;
});

/// Bridges the Hive ValueListenable (local cache + read marks) into Riverpod so
/// [inboxProvider] recomputes when either changes. The value is just a tick
/// counter — the data itself is read from LocalDbService.
final _localInboxRevisionProvider = StreamProvider<int>((ref) {
  final db = ref.watch(localDbServiceProvider);
  final listenable = db.notificationsListenable();
  final controller = StreamController<int>();
  var tick = 0;
  void onChange() => controller.add(++tick);
  listenable.addListener(onChange);
  ref.onDispose(() {
    listenable.removeListener(onChange);
    controller.close();
  });
  return controller.stream;
});
