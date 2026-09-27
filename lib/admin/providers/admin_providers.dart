import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_notification.dart';
import '../services/admin_service.dart';

/// Single AdminService instance for the panel.
final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

/// The sections in the admin sidebar.
enum AdminSection {
  dashboard,
  sheikhs,
  lectures,
  reciters,
  recitations,
  categories,
  notifications,
}

/// Which section is showing in the shell.
final adminSectionProvider =
    NotifierProvider<AdminSectionNotifier, AdminSection>(
  AdminSectionNotifier.new,
);

class AdminSectionNotifier extends Notifier<AdminSection> {
  @override
  AdminSection build() => AdminSection.dashboard;
  void select(AdminSection s) => state = s;
}

/// Messages already sent to the in-app inbox — the "Sent" list in the
/// Notifications module.
final sentAnnouncementsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  return ref.watch(adminServiceProvider).watchAnnouncements();
});
