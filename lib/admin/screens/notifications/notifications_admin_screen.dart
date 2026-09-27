import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/app_notification.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';

/// Compose + send an announcement, and review what has already gone out.
///
/// Backed by the `sendTopicNotification` Cloud Function (deploy functions +
/// upgrade to Blaze for this to work), which pushes to the topic AND saves the
/// message to `announcements` — the app's in-app bell inbox reads that, so a
/// message lands even for users who missed or disabled the push.
class NotificationsAdminScreen extends ConsumerStatefulWidget {
  const NotificationsAdminScreen({super.key});

  @override
  ConsumerState<NotificationsAdminScreen> createState() =>
      _NotificationsAdminScreenState();
}

class _NotificationsAdminScreenState
    extends ConsumerState<NotificationsAdminScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _topic = AppConstants.notificationTopics.first.topic;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty) {
      return setState(() => _error = 'Title is required.');
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final type = _topic == AppConstants.topicRamadan
          ? 'ramadan'
          : _topic == AppConstants.topicNewLectures
              ? 'lecture'
              : 'general';
      final pushError =
          await ref.read(adminServiceProvider).sendTopicNotification(
                topic: _topic,
                title: _title.text.trim(),
                body: _body.text.trim(),
                type: type,
              );
      setState(() {
        _success = pushError == null
            ? 'Sent. It is in every subscriber\'s notifications and in the '
                'app\'s in-app inbox.'
            : 'Saved to the in-app inbox, but the push failed: $pushError';
        _title.clear();
        _body.clear();
      });
    } catch (e) {
      setState(() => _error = 'Send failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifications',
      subtitle: 'Send an announcement — it goes out as a push and stays in '
          'the app\'s in-app inbox.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _composer(),
            const SizedBox(height: 32),
            const _SentList(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
          width: 560,
          padding: const EdgeInsets.all(24),
          decoration: AdminTheme.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Audience (topic)'),
              DropdownButtonFormField<String>(
                initialValue: _topic,
                items: [
                  for (final t in AppConstants.notificationTopics)
                    DropdownMenuItem(value: t.topic, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _topic = v ?? _topic),
              ),
              const SizedBox(height: 16),
              _label('Title'),
              TextField(controller: _title),
              const SizedBox(height: 16),
              _label('Message'),
              TextField(controller: _body, maxLines: 4),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _Banner(
                    color: Colors.redAccent,
                    icon: Icons.error_outline,
                    text: _error!),
              ],
              if (_success != null) ...[
                const SizedBox(height: 14),
                _Banner(
                    color: AdminTheme.olive,
                    icon: Icons.check_circle_outline,
                    text: _success!),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _send,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AdminTheme.sidebar))
                      : const Icon(Icons.send, size: 18),
                  label: const Text('Send notification'),
                ),
              ),
            ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AdminTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.icon, required this.text});
  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}

/// What users currently see in the app's bell inbox. Deleting removes a message
/// from every inbox (the push already delivered can't be recalled).
class _SentList extends ConsumerWidget {
  const _SentList();

  static String _topicLabel(String topic) {
    for (final t in AppConstants.notificationTopics) {
      if (t.topic == topic) return t.label;
    }
    return topic.isEmpty ? '—' : topic;
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppNotification item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from inboxes?'),
        content: Text(
          '“${item.title}” will disappear from every user\'s in-app inbox. '
          'The push notification already delivered stays on their device.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(adminServiceProvider).deleteAnnouncement(item.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sent = ref.watch(sentAnnouncementsProvider);

    return Container(
      width: 720,
      padding: const EdgeInsets.all(24),
      decoration: AdminTheme.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'In the app\'s inbox',
            style: TextStyle(
                color: AdminTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Everything sent, newest first — this is exactly what users find '
            'under the bell.',
            style: TextStyle(color: AdminTheme.subtle, fontSize: 13),
          ),
          const SizedBox(height: 16),
          switch (sent) {
            AsyncError(:final error) => Text('Could not load: $error',
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            AsyncData(:final value) when value.isEmpty => const Text(
                'Nothing sent yet.',
                style: TextStyle(color: AdminTheme.faint, fontSize: 13)),
            AsyncData(:final value) => Column(
                children: [
                  for (final item in value)
                    _SentRow(
                      item: item,
                      topicLabel: _topicLabel(item.topic),
                      onDelete: () => _confirmDelete(context, ref, item),
                    ),
                ],
              ),
            _ => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          },
        ],
      ),
    );
  }
}

class _SentRow extends StatelessWidget {
  const _SentRow({
    required this.item,
    required this.topicLabel,
    required this.onDelete,
  });

  final AppNotification item;
  final String topicLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AdminTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                      color: AdminTheme.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                if (item.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.body,
                      style: const TextStyle(
                          color: AdminTheme.subtle, fontSize: 13, height: 1.35)),
                ],
                const SizedBox(height: 4),
                Text(
                  '$topicLabel · ${Formatters.timeAgo(item.receivedAt)}',
                  style: const TextStyle(color: AdminTheme.faint, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Remove from inboxes',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AdminTheme.faint),
          ),
        ],
      ),
    );
  }
}
