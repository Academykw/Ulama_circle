import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/lecture_model.dart';
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

    switch (info.status) {
      case DownloadStatus.notDownloaded:
        return _iconButton(
          icon: Icons.download_outlined,
          color: AppColors.mutedText,
          tooltip: 'Download',
          onTap: () => controller.download(lecture),
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
                child: Icon(Icons.close, size: 14, color: AppColors.mutedText),
              ),
            ],
          ),
        );

      case DownloadStatus.downloaded:
        return _iconButton(
          icon: Icons.download_done,
          color: AppColors.olive,
          tooltip: 'Downloaded — tap to remove',
          onTap: () => _confirmDelete(context, controller),
        );

      case DownloadStatus.failed:
        return _iconButton(
          icon: Icons.error_outline,
          color: Colors.redAccent,
          tooltip: 'Download failed — tap to retry',
          onTap: () => controller.download(lecture),
        );
    }
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
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
