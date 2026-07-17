// Flutter also defines a RepeatMode (animations); hide it so ours wins.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/lecture_model.dart';
import '../../models/player_queue.dart';
import '../../providers/player_provider.dart';
import '../../widgets/add_to_playlist_sheet.dart';
import '../../widgets/download_button.dart';
import '../../widgets/favorite_button.dart';
import 'widgets/queue_sheet.dart';

/// Full-screen player: artwork stand-in, metadata, scrubber, transport controls.
/// Background playback + the media notification are handled by audio_service.
class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecture = ref.watch(currentLectureProvider);

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Now Playing'),
        centerTitle: true,
      ),
      body: lecture == null
          ? Center(
              child: Text('Nothing playing',
                  style: TextStyle(color: AppColors.mutedText)),
            )
          : _PlayerBody(lecture: lecture),
    );
  }
}

class _PlayerBody extends ConsumerWidget {
  const _PlayerBody({required this.lecture});
  final LectureModel lecture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(),
            // Artwork stand-in — branded block with the sheikh name.
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.olive, AppColors.surfaceDark],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      lecture.sheikhName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Title + meta + download indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lecture.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lecture.sheikhName}  •  ${Formatters.titleCase(lecture.language)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                FavoriteButton(lectureId: lecture.id, size: 26),
                IconButton(
                  tooltip: 'Add to playlist',
                  icon: Icon(Icons.playlist_add,
                      color: AppColors.mutedText, size: 26),
                  onPressed: () => showAddToPlaylistSheet(context, lecture.id),
                ),
                DownloadButton(lecture: lecture),
              ],
            ),
            const SizedBox(height: 20),
            _Scrubber(handler: handler),
            const SizedBox(height: 8),
            const _Controls(),
            const SizedBox(height: 8),
            const _SecondaryControls(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

/// Seek bar with position/duration labels. Tracks a local drag value so the
/// thumb doesn't fight the incoming position stream while the user scrubs.
class _Scrubber extends StatefulWidget {
  const _Scrubber({required this.handler});
  final dynamic handler; // AudioPlayerHandler (kept loose to avoid extra import here)

  @override
  State<_Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends State<_Scrubber> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: widget.handler.durationStream,
      builder: (context, durationSnap) {
        final duration = durationSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: widget.handler.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final maxMs = duration.inMilliseconds.toDouble();
            final posMs = position.inMilliseconds
                .toDouble()
                .clamp(0.0, maxMs == 0 ? 1.0 : maxMs);
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppColors.gold,
                    inactiveTrackColor: AppColors.surfaceDark,
                    thumbColor: AppColors.gold,
                    overlayColor: AppColors.gold.withValues(alpha: 0.2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    min: 0,
                    max: maxMs == 0 ? 1.0 : maxMs,
                    value: _dragValue ?? posMs,
                    onChanged: (v) => setState(() => _dragValue = v),
                    onChangeEnd: (v) {
                      widget.handler.seek(Duration(milliseconds: v.round()));
                      setState(() => _dragValue = null);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Formatters.clock(position),
                          style: TextStyle(
                              color: AppColors.mutedText, fontSize: 12)),
                      Text(Formatters.clock(duration),
                          style: TextStyle(
                              color: AppColors.mutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Main transport row: shuffle · previous · play/pause · next · repeat.
class _Controls extends ConsumerWidget {
  const _Controls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final queue = ref.watch(playerQueueProvider);
    final controller = ref.read(playbackControllerProvider);

    final repeatIcon =
        queue.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat;
    final repeatColor =
        queue.repeatMode == RepeatMode.off ? AppColors.mutedText : AppColors.gold;

    return StreamBuilder<PlayerState>(
      stream: handler.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processing = playerState?.processingState;
        final playing = playerState?.playing ?? false;
        final isBusy = processing == ProcessingState.loading ||
            processing == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 24,
              color: queue.shuffle ? AppColors.gold : AppColors.mutedText,
              icon: const Icon(Icons.shuffle),
              tooltip: 'Shuffle',
              onPressed: controller.toggleShuffle,
            ),
            IconButton(
              iconSize: 34,
              color: AppColors.cream,
              icon: const Icon(Icons.skip_previous),
              onPressed: controller.previous,
            ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: isBusy
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: AppColors.charcoal, strokeWidth: 3),
                    )
                  : IconButton(
                      iconSize: 40,
                      color: AppColors.charcoal,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: () =>
                          playing ? handler.pause() : handler.play(),
                    ),
            ),
            IconButton(
              iconSize: 34,
              color: queue.hasNext ? AppColors.cream : AppColors.mutedText,
              icon: const Icon(Icons.skip_next),
              onPressed: queue.hasNext ? controller.next : null,
            ),
            IconButton(
              iconSize: 24,
              color: repeatColor,
              icon: Icon(repeatIcon),
              tooltip: 'Repeat',
              onPressed: controller.cycleRepeat,
            ),
          ],
        );
      },
    );
  }
}

/// Secondary row: −10s · queue · +30s.
class _SecondaryControls extends ConsumerWidget {
  const _SecondaryControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final queue = ref.watch(playerQueueProvider);

    void seekRelative(Duration delta) {
      var target = handler.position + delta;
      if (target < Duration.zero) target = Duration.zero;
      handler.seek(target);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 28,
          color: AppColors.cream,
          icon: const Icon(Icons.replay_10),
          onPressed: () => seekRelative(const Duration(seconds: -10)),
        ),
        IconButton(
          iconSize: 26,
          color: queue.queue.length > 1
              ? AppColors.cream
              : AppColors.mutedText,
          icon: const Icon(Icons.queue_music),
          tooltip: 'Queue',
          onPressed: queue.queue.length > 1
              ? () => showQueueSheet(context)
              : null,
        ),
        IconButton(
          iconSize: 28,
          color: AppColors.cream,
          icon: const Icon(Icons.forward_30),
          onPressed: () => seekRelative(const Duration(seconds: 30)),
        ),
      ],
    );
  }
}
