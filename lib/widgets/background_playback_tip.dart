import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';
import '../providers/local_db_provider.dart';

/// Manufacturers whose Android skins aggressively kill background services and
/// hide media notifications unless the app is whitelisted (Autostart + battery).
/// Common across the Nigerian market: Xiaomi/Redmi/Poco, Infinix/Tecno/Itel
/// (Transsion), Oppo/Vivo/Realme, Huawei/Honor.
const _aggressiveOems = {
  'xiaomi', 'redmi', 'poco', 'infinix', 'tecno', 'itel', 'transsion',
  'oppo', 'vivo', 'realme', 'huawei', 'honor', 'meizu',
};

/// Shows a one-time tip (only on an affected device) explaining how to keep
/// background playback + the media notification alive. No-ops otherwise.
Future<void> maybeShowBackgroundPlaybackTip(
    BuildContext context, WidgetRef ref) async {
  if (!Platform.isAndroid) return;
  final db = ref.read(localDbServiceProvider);
  if (db.backgroundTipShown) return;

  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final maker = '${info.manufacturer} ${info.brand}'.toLowerCase();
    final affected = _aggressiveOems.any((oem) => maker.contains(oem));
    if (!affected) return;
  } catch (_) {
    return; // if we can't tell, don't nag
  }

  await db.setBackgroundTipShown(true);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _BackgroundTipSheet(),
  );
}

class _BackgroundTipSheet extends StatelessWidget {
  const _BackgroundTipSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.mutedText.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.goldMid.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const PxIcon(Px.bell, color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Keep playback alive',
                    style:
                        AppTheme.display(size: 20, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Your phone can pause audio and hide the lock-screen controls to '
              'save battery. To keep lectures playing in the background, allow '
              'these for Ulama Circle in Settings:',
              style: TextStyle(
                  color: AppColors.mutedText, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 18),
            const _Step(
              icon: Px.playCircleFill,
              title: 'Autostart',
              detail: 'Apps → Ulama Circle → turn Autostart on',
            ),
            const _Step(
              icon: Px.moonStars,
              title: 'Battery',
              detail: 'Battery saver → No restrictions',
            ),
            const _Step(
              icon: Px.bell,
              title: 'Notifications',
              detail: 'Allow notifications (incl. the lock screen)',
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF0D2620),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.detail});
  final PxData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PxIcon(icon, color: AppColors.goldMid, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(detail,
                    style: TextStyle(
                        color: AppColors.faintText, fontSize: 12.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
