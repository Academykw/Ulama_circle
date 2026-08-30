import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/share_helper.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/filter_providers.dart';
import '../../providers/locale_provider.dart';
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
    final authUser = ref.watch(authStateProvider).asData?.value;
    final isGuest = userDoc?.isGuest ?? authUser?.isAnonymous ?? true;
    // Guests always read "Guest User". A signed-in (e.g. Google) user shows
    // their real name: the saved doc name, else the live auth/Google name, else
    // the email prefix.
    final docName = userDoc?.displayName.trim() ?? '';
    final googleName = authUser?.displayName?.trim() ?? '';
    final emailPrefix = (authUser?.email ?? '').split('@').first;
    final name = isGuest
        ? 'Guest User'
        : docName.isNotEmpty
            ? docName
            : googleName.isNotEmpty
                ? googleName
                : emailPrefix.isNotEmpty
                    ? emailPrefix
                    : 'User';
    final emoji = userDoc?.avatarEmoji ?? '';

    final l = L10n.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.profile),
        titleTextStyle: AppTheme.display(size: 24, weight: FontWeight.w700),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AccountCard(name: name, isGuest: isGuest, emoji: emoji),
          const SizedBox(height: 24),
          _SectionLabel(l.sectionPreferences),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: switch (ref.watch(themeChoiceProvider)) {
                ThemeChoice.obsidian => Px.moonStars,
                ThemeChoice.emerald => Px.sun,
              },
              title: l.appearance,
              subtitle: _themeLabel(l, ref.watch(themeChoiceProvider)),
              onTap: () => _pickTheme(context, ref),
            ),
            _SettingsTile(
              icon: Px.translate,
              title: l.language,
              subtitle: _languageLabel(ref.watch(localeProvider)),
              onTap: () => _pickLanguage(context, ref),
            ),
            _SettingsTile(
              icon: Px.bookOpen,
              title: 'Content languages',
              subtitle:
                  _contentLanguagesLabel(ref.watch(preferredLanguagesProvider)),
              onTap: () => _pickContentLanguages(context, ref),
            ),
            _SettingsTile(
              icon: Px.bell,
              title: l.notifications,
              subtitle: l.notificationsSub,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _SectionLabel(l.sectionSupport),
          _SettingsGroup(children: [
            _SettingsTile(
              icon: Px.usersThree,
              title: 'Share Ulama Circle',
              subtitle: 'Invite friends & family to the app',
              onTap: () => shareApp(),
            ),
            _SettingsTile(
              icon: Px.heart,
              title: 'Rate Ulama Circle',
              subtitle: 'Leave a review on Google Play',
              onTap: () {
                InAppReview.instance.openStoreListing();
              },
            ),
            _SettingsTile(
              icon: Px.question,
              title: l.helpSupport,
              subtitle: l.helpSupportSub,
              onTap: () => _soon(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Px.chatCircleText,
              title: l.sendFeedback,
              subtitle: l.sendFeedbackSub,
              onTap: () => _soon(context, 'Coming soon'),
            ),
            _SettingsTile(
              icon: Px.info,
              title: l.about,
              subtitle: 'Version 0.1.0',
              onTap: () => _soon(context, 'Ulama Circle · v0.1.0'),
            ),
          ]),
          // Registered users can permanently delete their account + data.
          if (!isGuest) ...[
            const SizedBox(height: 28),
            const _DeleteAccountButton(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  static String _languageLabel(Locale? locale) => switch (locale?.languageCode) {
        'ha' => 'Hausa',
        'en' => 'English',
        _ => 'System default',
      };

  static String _contentLanguagesLabel(Set<String> langs) => langs.isEmpty
      ? 'All languages'
      : (AppConstants.supportedLanguages
              .where(langs.contains)
              .map(Formatters.titleCase)
              .toList()
            ..sort())
          .join(', ');

  /// Bottom sheet to change the preferred content languages later. Toggling
  /// updates the app-wide default filter immediately; at least one stays on.
  void _pickContentLanguages(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(builder: (context, ref, __) {
        final selected = ref.watch(preferredLanguagesProvider); // empty = all
        final notifier = ref.read(preferredLanguagesProvider.notifier);
        final all = selected.isEmpty;

        Widget row({String? lang}) {
          final isAll = lang == null;
          final isSel = isAll ? all : selected.contains(lang);
          return ListTile(
            title: Text(
              isAll ? 'All languages' : Formatters.titleCase(lang!),
              style: TextStyle(
                  color: AppColors.cream, fontWeight: FontWeight.w600),
            ),
            trailing: isSel
                ? const Icon(Icons.check, color: AppColors.gold)
                : null,
            onTap: () {
              if (isAll) {
                notifier.save(<String>{});
                return;
              }
              // Expand "All" to the concrete set before toggling one off.
              final next = (all
                  ? {...AppConstants.supportedLanguages}
                  : {...selected});
              if (!next.add(lang!)) next.remove(lang);
              notifier.save(next.isEmpty
                  ? {...AppConstants.supportedLanguages}
                  : next);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Content languages',
                      style:
                          AppTheme.display(size: 18, weight: FontWeight.w700)),
                ),
              ),
              row(lang: null),
              for (final l in AppConstants.supportedLanguages) row(lang: l),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }

  void _pickLanguage(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer(builder: (context, ref, __) {
        final current = ref.watch(localeProvider)?.languageCode;
        Widget option(String? code, String label) {
          final selected = current == code;
          return ListTile(
            title: Text(label,
                style: TextStyle(
                    color: AppColors.cream,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500)),
            trailing: selected
                ? const PxIcon(Px.checkCircleFill, color: AppColors.gold)
                : null,
            onTap: () {
              ref
                  .read(localeProvider.notifier)
                  .set(code == null ? null : Locale(code));
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
                  child: Text(L10n.of(context).language,
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
              ),
              option('en', 'English'),
              option('ha', 'Hausa'),
              option(null, 'System default'),
              const SizedBox(height: 12),
            ],
          ),
        );
      }),
    );
  }

  void _soon(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _themeLabel(L10n l, ThemeChoice c) => switch (c) {
        ThemeChoice.obsidian => l.themeObsidian,
        ThemeChoice.emerald => l.themeEmerald,
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
          Widget option(ThemeChoice choice, String label, PxData icon) {
            final selected = choice == current;
            return ListTile(
              leading: PxIcon(icon,
                  color: selected ? AppColors.gold : AppColors.mutedText),
              title: Text(label,
                  style: TextStyle(
                      color: AppColors.cream,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500)),
              trailing: selected
                  ? const PxIcon(Px.checkCircleFill, color: AppColors.gold)
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
                    child: Text(L10n.of(context).appearance,
                        style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                option(ThemeChoice.emerald, L10n.of(context).themeEmerald,
                    Px.sun),
                option(ThemeChoice.obsidian, L10n.of(context).themeObsidian,
                    Px.moonStars),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Danger-zone action: permanently delete the account + all saved data.
class _DeleteAccountButton extends ConsumerWidget {
  const _DeleteAccountButton();

  static const _danger = Color(0xFFE5534B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirm(context, ref),
      icon: const Icon(Icons.delete_outline, size: 19),
      label: const Text('Delete account'),
      style: OutlinedButton.styleFrom(
        foregroundColor: _danger,
        side: const BorderSide(color: Color(0x55E5534B)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account. All your saved data — '
          'favorites, playlists, and listening history — will be wiped and '
          'this cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, ref);
  }

  Future<void> _run(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
    try {
      await ref.read(authControllerProvider).deleteAccount();
      // Success → the auth state flips to signed-out and routing takes over.
      // Remove the progress spinner so it doesn't linger over the next screen.
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss progress
      final needsReauth = e.toString().contains('requires-recent-login');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: const Text('Couldn’t delete account'),
          content: Text(needsReauth
              ? 'For your security, please sign out and sign in again, then '
                  'try deleting your account.'
              : 'Something went wrong. Please check your connection and try '
                  'again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
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
                          ? const PxIcon(Px.userCircleFill,
                              color: AppColors.gold, size: 32)
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
                        alignment: Alignment.center,
                        child: const PxIcon(Px.pencilSimple,
                            color: Color(0xFF0D2620), size: 11),
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
              icon: PxIcon(isGuest ? Px.userCircleFill : Px.signOut, size: 18),
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
        color: AppColors.cream.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final PxData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.goldMid.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: PxIcon(icon, color: AppColors.gold, size: 21),
      ),
      title: Text(title,
          style: TextStyle(
              color: AppColors.cream, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(color: AppColors.faintText, fontSize: 12)),
      trailing:
          PxIcon(Px.caretRight, color: AppColors.faintText, size: 16),
    );
  }
}
