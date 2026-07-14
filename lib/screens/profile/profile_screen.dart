import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../notifications/notification_settings_screen.dart';

/// Profile / settings tab. Header adapts to guest vs registered; below it,
/// preference and support rows. Several rows are placeholders wired to real
/// screens on later days (theme = Day 29, notifications = Day 21).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).asData?.value;
    final isGuest = userDoc?.isGuest ?? true;
    final name = (userDoc?.displayName.isNotEmpty ?? false)
        ? userDoc!.displayName
        : 'Guest User';

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        title: const Text('Profile'),
        titleTextStyle: const TextStyle(
            color: AppColors.cream, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AccountCard(name: name, isGuest: isGuest),
          const SizedBox(height: 24),
          const _SectionLabel('PREFERENCES'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.nightlight_round,
              iconColor: AppColors.olive,
              title: 'Appearance',
              subtitle: 'Dark mode',
              onTap: () => _soon(context, 'Theme options arrive later'),
            ),
            _SettingsTile(
              icon: Icons.notifications_outlined,
              iconColor: AppColors.gold,
              title: 'Notifications',
              subtitle: 'Manage what you’re notified about',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          const _SectionLabel('SUPPORT'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Icons.help_outline,
              iconColor: AppColors.olive,
              title: 'Help & Support',
              subtitle: 'FAQs and contact us',
              onTap: () => _soon(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Icons.chat_bubble_outline,
              iconColor: AppColors.gold,
              title: 'Send Feedback',
              subtitle: 'Help us improve',
              onTap: () => _soon(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppColors.mutedText,
              title: 'About',
              subtitle: 'Version 0.1.0',
              onTap: () => _soon(context, 'Ulama Circle · v0.1.0'),
            ),
          ]),
        ],
      ),
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.name, required this.isGuest});
  final String name;
  final bool isGuest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person, color: AppColors.gold, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppColors.cream,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Sign in to sync your data' : 'Signed in',
                      style: const TextStyle(
                          color: AppColors.mutedText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: isGuest ? AppColors.gold : AppColors.surfaceDark,
                foregroundColor: isGuest ? AppColors.charcoal : AppColors.cream,
                side: isGuest
                    ? null
                    : const BorderSide(color: AppColors.mutedText),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(isGuest ? Icons.login : Icons.logout, size: 20),
              label: Text(isGuest ? 'Sign In' : 'Sign out',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              // Guest "Sign In" and "Sign out" both return to the auth screen.
              onPressed: () => ref.read(authControllerProvider).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              color: AppColors.cream, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.mutedText, size: 20),
    );
  }
}
