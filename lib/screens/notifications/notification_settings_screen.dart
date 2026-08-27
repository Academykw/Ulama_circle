import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/local_db_provider.dart';
import '../../providers/notification_providers.dart';

/// Push preferences — a toggle per FCM topic, plus a system-permission status
/// card so users (especially on Xiaomi/Infinix/Tecno) can see whether the OS is
/// blocking notifications — including the media playback notification — and jump
/// straight to the settings to enable them.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from the system settings screen.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await Permission.notification.status;
    if (mounted) setState(() => _status = s);
  }

  Future<void> _fix() async {
    final s = await Permission.notification.status;
    // First ask; if the OS won't prompt again, send them to app settings.
    if (s.isDenied) {
      final res = await Permission.notification.request();
      if (mounted) setState(() => _status = res);
      if (res.isGranted) return;
    }
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(localDbServiceProvider);
    final service = ref.watch(notificationServiceProvider);
    final granted = _status?.isGranted ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (_status != null && !granted) _PermissionCard(onFix: _fix),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Text(
              'Choose what you’d like to be notified about. You can change these '
              'any time.',
              style: TextStyle(color: AppColors.mutedText, fontSize: 14),
            ),
          ),
          for (final t in AppConstants.notificationTopics)
            SwitchListTile(
              value: db.notifPref(t.topic),
              activeThumbColor: AppColors.charcoal,
              activeTrackColor: AppColors.gold,
              inactiveThumbColor: AppColors.mutedText,
              inactiveTrackColor: AppColors.surfaceDark,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: Text(t.label,
                  style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              subtitle: Text(t.description,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
              onChanged: (value) async {
                await service.setTopicEnabled(t.topic, value);
                if (mounted) setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

/// Shown when the OS is blocking notifications — explains the impact (incl. the
/// player controls on the lock screen) and offers a one-tap fix.
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onFix});
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2A12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PxIcon(Px.bell, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Notifications are turned off',
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Turn them on to get the player controls on your lock screen and '
            'notification shade while a lecture plays, plus new-lecture alerts.',
            style: TextStyle(
                color: AppColors.cream.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.45),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF0D2620),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onFix,
              child: const Text('Enable notifications',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
