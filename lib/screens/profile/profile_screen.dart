import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/emoji_picker_sheet.dart';
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
    final emoji = userDoc?.avatarEmoji ?? '';

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: AppColors.charcoal,
        title: const Text('Profile'),
        titleTextStyle: TextStyle(
            color: AppColors.cream, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AccountCard(name: name, isGuest: isGuest, emoji: emoji),
          const SizedBox(height: 24),
          const _SectionLabel('PREFERENCES'),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: switch (ref.watch(themeChoiceProvider)) {
                ThemeChoice.dark => Icons.dark_mode_outlined,
                ThemeChoice.emerald => Icons.spa_outlined,
                ThemeChoice.system => Icons.brightness_auto_outlined,
              },
              iconColor: AppColors.olive,
              title: 'Appearance',
              subtitle: _themeLabel(ref.watch(themeChoiceProvider)),
              onTap: () => _pickTheme(context, ref),
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

  static String _themeLabel(ThemeChoice c) => switch (c) {
        ThemeChoice.dark => 'Dark',
        ThemeChoice.emerald => 'Emerald',
        ThemeChoice.system => 'System default',
      };

  void _pickTheme(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(
        builder: (context, ref, __) {
          final current = ref.watch(themeChoiceProvider);
          Widget option(ThemeChoice choice, String label, IconData icon) {
            final selected = choice == current;
            return ListTile(
              leading: Icon(icon,
                  color: selected ? AppColors.gold : AppColors.mutedText),
              title: Text(label,
                  style: TextStyle(
                      color: AppColors.cream,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
              trailing: selected
                  ? const Icon(Icons.check, color: AppColors.gold)
                  : null,
              onTap: () {
                ref.read(themeChoiceProvider.notifier).set(choice);
                Navigator.pop(context);
              },
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedText.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Appearance',
                        style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                option(ThemeChoice.system, 'System default',
                    Icons.brightness_auto_outlined),
                option(ThemeChoice.dark, 'Dark', Icons.dark_mode_outlined),
                option(ThemeChoice.emerald, 'Emerald', Icons.spa_outlined),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard(
      {required this.name, required this.isGuest, required this.emoji});
  final String name;
  final bool isGuest;
  final String emoji;

  Future<void> _editAvatar(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final chosen = await showEmojiPickerSheet(context);
    if (chosen != null) {
      await ref.read(authControllerProvider).setAvatarEmoji(uid, chosen);
    }
  }

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
              GestureDetector(
                onTap: () => _editAvatar(context, ref),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: emoji.isEmpty
                          ? const Icon(Icons.person,
                              color: AppColors.gold, size: 30)
                          : Text(emoji, style: const TextStyle(fontSize: 30)),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceDark, width: 2),
                        ),
                        child: Icon(Icons.edit,
                            color: AppColors.charcoal, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      isGuest ? 'Sign in to sync your data' : 'Signed in',
                      style: TextStyle(
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
                    : BorderSide(color: AppColors.mutedText),
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
        style: TextStyle(
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
          style: TextStyle(
              color: AppColors.cream, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
      trailing:
          Icon(Icons.chevron_right, color: AppColors.mutedText, size: 20),
    );
  }
}
