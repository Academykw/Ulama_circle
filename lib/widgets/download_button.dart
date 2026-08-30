import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';
import '../models/lecture_model.dart';
import '../providers/auth_provider.dart';
import '../providers/download_providers.dart';

/// Small stateful affordance showing a lecture's download state and letting the
/// user act on it:
///   - not downloaded → download icon (tap to download)
///   - downloading     → progress ring (tap to cancel)
///   - downloaded      → check (tap to delete, with confirm)
///   - failed          → retry icon
class DownloadButton extends ConsumerWidget {
  const DownloadButton({super.key, required this.lecture, this.accent = AppColors.gold});

  final LectureModel lecture;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(downloadInfoProvider(lecture.id));
    final controller = ref.read(downloadControllerProvider.notifier);

    // Downloads become Premium-only once [downloadsRequirePremium] is flipped
    // on; until then everyone can download.
    final locked = AppConstants.downloadsRequirePremium &&
        !ref.watch(isPremiumProvider);

    switch (info.status) {
      case DownloadStatus.notDownloaded:
        return _iconButton(
          icon: Px.downloadSimple,
          color: AppColors.mutedText,
          tooltip: locked ? 'Download (Premium)' : 'Download',
          onTap: () => locked
              ? _showPremiumSheet(context)
              : controller.download(lecture),
        );

      case DownloadStatus.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Determinate ring; falls back to indeterminate before first byte.
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  value: info.progress > 0 ? info.progress : null,
                  color: accent,
                  backgroundColor: AppColors.surfaceDark,
                ),
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => controller.cancel(lecture.id),
                child: PxIcon(Px.x, size: 14, color: AppColors.mutedText),
              ),
            ],
          ),
        );

      case DownloadStatus.downloaded:
        return _iconButton(
          icon: Px.checkCircleFill,
          color: AppColors.goldMid,
          tooltip: 'Downloaded — tap to remove',
          onTap: () => _confirmDelete(context, controller),
        );

      case DownloadStatus.failed:
        return IconButton(
          icon: const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
          tooltip: 'Download failed — tap to retry',
          visualDensity: VisualDensity.compact,
          onPressed: () => controller.download(lecture),
        );
    }
  }

  Widget _iconButton({
    required PxData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: PxIcon(icon, color: color, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }

  void _showPremiumSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
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
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const PxIcon(Px.downloadSimple,
                        color: Color(0xFF0D2620), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text('Downloads are Premium',
                        style: AppTheme.display(
                            size: 20, weight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Save lectures and recitations to listen offline — on the bus, '
                'in areas with no data, anywhere. Upgrade to Premium to unlock '
                'downloads.',
                style: TextStyle(
                    color: AppColors.mutedText, fontSize: 14, height: 1.5),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(const SnackBar(
                          content: Text('Premium is coming soon, inshaAllah.')));
                  },
                  child: const Text('Notify me',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, DownloadController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Remove download?',
            style: TextStyle(color: AppColors.cream)),
        content: Text(
          'Delete the downloaded audio for "${lecture.title}"? You can download it again later.',
          style: TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(lecture.id);
  }
}
