import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';
import '../providers/content_providers.dart';
import '../providers/player_provider.dart';
import '../screens/player/player_screen.dart';

/// Persistent playback bar shown while something is loaded. Tapping it opens the
/// full player. Renders nothing when no lecture is active.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecture = ref.watch(currentLectureProvider);
    if (lecture == null) return const SizedBox.shrink();

    final handler = ref.watch(audioHandlerProvider);
    // Reciter cover comes through artworkUrl; lectures fall back to sheikh photo.
    var art = lecture.artworkUrl;
    if (art.isEmpty && lecture.sheikhId.isNotEmpty) {
      art = ref.watch(sheikhByIdProvider(lecture.sheikhId))?.photoUrl ?? '';
    }

    return Material(
      color: AppColors.navBg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.goldMid.withValues(alpha: 0.18)),
          ),
        ),
        child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin progress line across the top of the bar.
            StreamBuilder<Duration?>(
              stream: handler.durationStream,
              builder: (context, durSnap) {
                final duration = durSnap.data ?? Duration.zero;
                return StreamBuilder<Duration>(
                  stream: handler.positionStream,
                  builder: (context, posSnap) {
                    final position = posSnap.data ?? Duration.zero;
                    final value = duration.inMilliseconds == 0
                        ? 0.0
                        : (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0);
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 2,
                      backgroundColor: AppColors.charcoal,
                      color: AppColors.gold,
                    );
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: art.isEmpty
                          ? _MiniArtFallback()
                          : Image.network(
                              art,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _MiniArtFallback(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          lecture.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.cream,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          lecture.sheikhName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppColors.mutedText, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PlayPause(handler: handler),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _MiniArtFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.olive, AppColors.charcoal],
        ),
      ),
      child: Icon(Icons.graphic_eq, color: AppColors.cream, size: 20),
    );
  }
}

class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.handler});
  final dynamic handler; // AudioPlayerHandler

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: handler.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processing = playerState?.processingState;
        final playing = playerState?.playing ?? false;
        final busy = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        if (busy) {
          return const SizedBox(
            width: 36,
            height: 36,
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(
                  color: AppColors.gold, strokeWidth: 2.4),
            ),
          );
        }
        return GestureDetector(
          onTap: () => playing ? handler.pause() : handler.play(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: PxIcon(playing ? Px.pauseFill : Px.playFill,
                color: const Color(0xFF0D2620), size: 15),
          ),
        );
      },
    );
  }
}
