import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../admin_theme.dart';
import '../providers/admin_providers.dart';
import 'categories/categories_admin_screen.dart';
import 'dashboard/dashboard_screen.dart';
import 'lectures/lectures_admin_screen.dart';
import 'notifications/notifications_admin_screen.dart';
import 'recitations/recitations_admin_screen.dart';
import 'reciters/reciters_admin_screen.dart';
import 'sheikhs/sheikhs_admin_screen.dart';

/// The signed-in admin layout: a fixed sidebar + the active section's screen.
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(adminSectionProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: fixed sidebar beside the content. Tablet/phone: a hamburger
        // AppBar + slide-out drawer, content full width.
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            backgroundColor: AdminTheme.bg,
            body: Row(
              children: [
                const _Sidebar(),
                Expanded(child: _sectionBody(section)),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: AdminTheme.bg,
          appBar: AppBar(
            backgroundColor: AdminTheme.sidebar,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(_sectionTitle(section),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          drawer: const Drawer(
            width: 288,
            backgroundColor: AdminTheme.sidebar,
            child: _Sidebar(inDrawer: true),
          ),
          body: _sectionBody(section),
        );
      },
    );
  }

  String _sectionTitle(AdminSection section) => switch (section) {
        AdminSection.dashboard => 'Dashboard',
        AdminSection.sheikhs => 'Scholars',
        AdminSection.lectures => 'Lectures',
        AdminSection.reciters => 'Reciters',
        AdminSection.recitations => 'Recitations',
        AdminSection.categories => 'Categories',
        AdminSection.notifications => 'Notifications',
      };

  Widget _sectionBody(AdminSection section) {
    switch (section) {
      case AdminSection.sheikhs:
        return const SheikhsAdminScreen();
      case AdminSection.dashboard:
        return const DashboardScreen();
      case AdminSection.lectures:
        return const LecturesAdminScreen();
      case AdminSection.reciters:
        return const RecitersAdminScreen();
      case AdminSection.recitations:
        return const RecitationsAdminScreen();
      case AdminSection.categories:
        return const CategoriesAdminScreen();
      case AdminSection.notifications:
        return const NotificationsAdminScreen();
    }
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({this.inDrawer = false});

  /// When shown inside the mobile Drawer, tapping a section also closes it.
  final bool inDrawer;

  static const _items = <({AdminSection section, String label, IconData icon})>[
    (section: AdminSection.dashboard, label: 'Dashboard', icon: Icons.dashboard_outlined),
    (section: AdminSection.sheikhs, label: 'Scholars', icon: Icons.groups_outlined),
    (section: AdminSection.lectures, label: 'Lectures', icon: Icons.headset_outlined),
    (section: AdminSection.reciters, label: 'Reciters', icon: Icons.menu_book_outlined),
    (section: AdminSection.recitations, label: 'Recitations', icon: Icons.graphic_eq),
    (section: AdminSection.categories, label: 'Categories', icon: Icons.category_outlined),
    (section: AdminSection.notifications, label: 'Notifications', icon: Icons.campaign_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(adminSectionProvider);
    final email = ref.watch(authStateProvider).asData?.value?.email ?? 'Admin';

    return Container(
      width: inDrawer ? double.infinity : 264,
      color: AdminTheme.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AdminTheme.gold,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.shield_moon,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ulama Circle',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                      Text('Admin',
                          style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text('MENU',
                style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ),
          for (final item in _items)
            _NavItem(
              label: item.label,
              icon: item.icon,
              selected: item.section == active,
              onTap: () {
                ref.read(adminSectionProvider.notifier).select(item.section);
                if (inDrawer) Navigator.of(context).maybePop();
              },
            ),
          const Spacer(),
          _AccountBlock(email: email),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AdminTheme.sidebarHover : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon,
                    size: 20,
                    color: selected ? AdminTheme.gold : Colors.white60),
                const SizedBox(width: 14),
                Text(label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountBlock extends ConsumerWidget {
  const _AccountBlock({required this.email});
  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'A';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                color: AdminTheme.gold, shape: BoxShape.circle),
            child: Text(initial,
                style: const TextStyle(
                    color: AdminTheme.sidebar,
                    fontWeight: FontWeight.w800,
                    fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Signed in',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sign out',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
