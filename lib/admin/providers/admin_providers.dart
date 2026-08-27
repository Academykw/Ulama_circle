import 'package:flutter_riverpod/flutter_riverpod.dart';

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
