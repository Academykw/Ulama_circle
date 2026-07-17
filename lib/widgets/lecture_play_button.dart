import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../core/theme/app_theme.dart';
import '../models/lecture_model.dart';
import '../providers/download_providers.dart';
import '../providers/player_provider.dart';

/// Round play control for a lecture row. Shows:
///   - a gold play circle by default
///   - a pause icon when THIS lecture is the one playing
///   - a progress ring while it's caching/downloading
///   - a small olive "downloaded" badge when it's available offline
///
/// [onPlay] starts this lecture (with its surrounding queue). Tapping while it's
/// the current lecture toggles play/pause instead.
class LecturePlayButton extends ConsumerWidget {
  const LecturePlayButton({
    super.key,
    required this.lecture,
    required this.onPlay,
    this.size = 46,
  });

  final LectureModel lecture;
  final VoidCallback onPlay;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent =
        ref.watch(currentLectureProvider)?.id == lecture.id;
    final info = ref.watch(downloadInfoProvider(lecture.id));
    final downloading = info.status == DownloadStatus.downloading;
    final downloaded = info.status == DownloadStatus.downloaded;
    final handler = ref.watch(audioHandlerProvider);

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (downloading)
            SizedBox(
              width: size + 6,
              height: size + 6,
              child: CircularProgressIndicator(
                value: info.progress > 0 ? info.progress : null,
                strokeWidth: 2.5,
                color: AppColors.gold,
                backgroundColor: AppColors.surfaceDark,
              ),
            ),
          if (isCurrent)
            StreamBuilder<PlayerState>(
              stream: handler.playerStateStream,
              builder: (context, snap) {
                final playing = snap.data?.playing ?? false;
                return _circle(
                  playing ? Icons.pause : Icons.play_arrow,
                  () => playing ? handler.pause() : handler.play(),
                );
              },
            )
          else
            _circle(Icons.play_arrow, onPlay),
          if (downloaded)
            Positioned(right: 2, bottom: 2, child: _downloadedBadge()),
        ],
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: AppColors.gold,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.charcoal, size: size * 0.5),
      ),
    );
  }

  Widget _downloadedBadge() {
    return Container(
      width: 17,
      height: 17,
      decoration: BoxDecoration(
        color: AppColors.olive,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.charcoal, width: 2),
      ),
      child: Icon(Icons.check, color: AppColors.cream, size: 9),
    );
  }
}
