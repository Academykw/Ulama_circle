import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../admin_theme.dart';
import '../../providers/admin_providers.dart';
import '../widgets/admin_page.dart';

/// Compose + send a push to a topic. Backed by the `sendTopicNotification`
/// Cloud Function (deploy functions + upgrade to Blaze for this to work).
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
      await ref.read(adminServiceProvider).sendTopicNotification(
            topic: _topic,
            title: _title.text.trim(),
            body: _body.text.trim(),
            type: type,
          );
      setState(() {
        _success = 'Sent to everyone subscribed to this topic.';
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
      subtitle: 'Send an announcement to everyone subscribed to a topic.',
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Container(
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
        ),
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
