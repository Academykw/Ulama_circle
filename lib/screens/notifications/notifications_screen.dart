import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../providers/local_db_provider.dart';
import '../../widgets/empty_state.dart';

/// The bell inbox — notifications received via FCM, newest first. Opening the
/// screen marks everything read (clears the header badge).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark read once the first frame is up (so the unread state is visible for
    // a beat, then the badge clears).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localDbServiceProvider).markAllNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDbServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(L10n.of(context).notifications),
        actions: [
          ValueListenableBuilder(
            valueListenable: db.notificationsListenable(),
            builder: (context, _, __) {
              if (db.notifications().isEmpty) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => db.clearNotifications(),
                child: Text(L10n.of(context).clear,
                    style: TextStyle(color: AppColors.mutedText)),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: db.notificationsListenable(),
        builder: (context, _, __) {
          final items = db.notifications();
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.notifications_none,
              title: L10n.of(context).notificationsEmpty,
              subtitle: L10n.of(context).notificationsEmptySub,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(color: AppColors.surfaceDark, height: 1),
            itemBuilder: (_, i) => _NotificationRow(item: items[i]),
          );
        },
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item});
  final AppNotification item;

  static const _icons = {
    'general': Px.bell,
    'lecture': Px.playCircleFill,
    'reciter': Px.bookOpen,
    'ramadan': Px.moonStars,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icons[item.type] ?? Px.bell;
    return Container(
      color: item.read
          ? Colors.transparent
          : AppColors.gold.withValues(alpha: 0.06),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldMid.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: PxIcon(icon, color: AppColors.gold, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.timeAgo(item.receivedAt),
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12),
                    ),
                    if (!item.read) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: AppColors.gold, shape: BoxShape.circle),
                      ),
                    ],
                  ],
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: TextStyle(
                        color: AppColors.mutedText, fontSize: 13, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
