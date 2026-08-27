import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/icons/px.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/local_db_provider.dart';
import '../../notifications/notifications_screen.dart';

/// Top of Home: greeting with the user's avatar on the left and a notification
/// bell on the right. The bell is a placeholder until push notifications land
/// (Day 21) — for now it just tells the user there's nothing new.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider).asData?.value;
    final authUser = ref.watch(authStateProvider).asData?.value;
    final isGuest = userDoc?.isGuest ?? authUser?.isAnonymous ?? true;
    // Guests read "Guest User"; a signed-in user shows their real name (saved
    // doc name, else the live auth/Google name, else the email prefix).
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          _Avatar(name: isGuest ? null : name, emoji: userDoc?.avatarEmoji ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L10n.of(context).greetingSalam,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(size: 23, weight: FontWeight.w700)
                      .copyWith(height: 1.1),
                ),
              ],
            ),
          ),
          const _NotificationBell(),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.name, this.emoji = ''});
  final String? name;
  final String emoji;

  String get _initials {
    if (name == null) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters;
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (emoji.isNotEmpty) {
      content = Text(emoji, style: const TextStyle(fontSize: 24));
    } else if (_initials.isEmpty) {
      content = Icon(Icons.person, color: AppColors.charcoal, size: 24);
    } else {
      content = Text(
        _initials,
        style: TextStyle(
          color: AppColors.charcoal,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    }

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Emoji avatars sit on a neutral surface; initials keep the gold gradient.
        color: emoji.isNotEmpty ? AppColors.surfaceDark : null,
        gradient: emoji.isNotEmpty
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold, AppColors.olive],
              ),
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(localDbServiceProvider);
    void open() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
        );

    return ValueListenableBuilder(
      valueListenable: db.notificationsListenable(),
      builder: (context, _, __) {
        final unread = db.unreadNotificationCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: open,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: const PxIcon(Px.bell, size: 21, color: AppColors.gold),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: const BoxDecoration(
                      color: AppColors.gold, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: TextStyle(
                        color: AppColors.charcoal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
