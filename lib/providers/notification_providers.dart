import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import 'local_db_provider.dart';

/// The NotificationService, built on the shared LocalDbService. Initialized in
/// main(); this provider exposes the instance for topic toggles. The inbox
/// itself is read reactively via `LocalDbService.notificationsListenable()`
/// (a Hive ValueListenable), so it updates even from FCM callbacks.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(localDbServiceProvider));
});
