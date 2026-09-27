import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../providers/local_db_provider.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/empty_state.dart';

/// The bell inbox — admin announcements read from Firestore merged with the FCM
/// messages cached locally, newest first (see [inboxProvider]). Opening the
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    if (!mounted) return;
    final db = ref.read(localDbServiceProvider);
    await db.markAllNotificationsRead();
    await db.markAnnouncementsRead(
        ref.read(inboxProvider).map((n) => n.id).toList());
  }

  Future<void> _clear() async {
    final db = ref.read(localDbServiceProvider);
    // Announcements are shared docs, so "clear" only hides them on this device.
    await db.dismissAnnouncements(ref.read(inboxProvider).map((n) => n.id));
    await db.clearNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(inboxProvider);
    // Announcements arrive asynchronously; keep marking new ones read while the
    // screen is open so the badge doesn't reappear behind the user's back.
    ref.listen(inboxProvider, (_, __) => _markRead());

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(L10n.of(context).notifications),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: _clear,
              child: Text(L10n.of(context).clear,
                  style: TextStyle(color: AppColors.mutedText)),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.notifications_none,
              title: L10n.of(context).notificationsEmpty,
              subtitle: L10n.of(context).notificationsEmptySub,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(color: AppColors.surfaceDark, height: 1),
              itemBuilder: (_, i) => _NotificationRow(item: items[i]),
            ),
    );
  }
}

/// One inbox row. Long messages are clamped to three lines and expand on tap,
/// so a full announcement is readable without leaving the screen.
class _NotificationRow extends StatefulWidget {
  const _NotificationRow({required this.item});
  final AppNotification item;

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow> {
  bool _expanded = false;

  static const _icons = {
    'general': Px.bell,
    'lecture': Px.playCircleFill,
    'reciter': Px.bookOpen,
    'ramadan': Px.moonStars,
  };

  /// Roughly how much body text fits in the clamped three lines — below this a
  /// row has nothing to expand, so it stays a plain (non-tappable) row.
  static const _clampChars = 110;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final icon = _icons[item.type] ?? Px.bell;
    final canExpand = item.body.length > _clampChars;

    return InkWell(
      onTap: canExpand ? () => setState(() => _expanded = !_expanded) : null,
      child: Container(
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
                      maxLines: _expanded ? null : 3,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 13,
                          height: 1.3),
                    ),
                    if (canExpand) ...[
                      const SizedBox(height: 6),
                      Text(
                        _expanded
                            ? L10n.of(context).showLess
                            : L10n.of(context).readMore,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
