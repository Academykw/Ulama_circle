// Flutter also defines a RepeatMode (animations); hide it so ours wins.
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lecture_model.dart';
import '../../core/utils/share_helper.dart';
import '../../models/player_queue.dart';
import '../../providers/content_providers.dart';
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

    return Container(
      decoration: AppTheme.nowPlayingBackdrop,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const PxIcon(Px.caretLeft, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(L10n.of(context).nowPlaying),
          titleTextStyle: AppTheme.display(size: 16, weight: FontWeight.w700),
          centerTitle: true,
        ),
        body: lecture == null
            ? Center(
                child: Text(L10n.of(context).nothingPlaying,
                    style: TextStyle(color: AppColors.mutedText)),
              )
            : _PlayerBody(lecture: lecture),
      ),
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
            // Cover art when available (e.g. reciter photo), else a branded
            // block with the sheikh/reciter name.
            AspectRatio(
              aspectRatio: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: _Artwork(lecture: lecture),
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
                        style: AppTheme.display(size: 20, weight: FontWeight.w700)
                            .copyWith(height: 1.25),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${lecture.sheikhName}  ·  ${Formatters.titleCase(lecture.language)}',
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
                  icon: PxIcon(Px.playlist,
                      color: AppColors.mutedText, size: 24),
                  onPressed: () => showAddToPlaylistSheet(context, lecture.id),
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: Icon(Icons.share_outlined,
                      color: AppColors.mutedText, size: 22),
                  onPressed: () => shareLecture(lecture),
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

/// The Now Playing cover: the artwork image when set (reciter photo), or the
/// lecturer's photo resolved by sheikhId, otherwise a branded gradient block
/// with the sheikh/reciter name.
class _Artwork extends ConsumerWidget {
  const _Artwork({required this.lecture});
  final LectureModel lecture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branded = _BrandedCover(name: lecture.sheikhName);
    // Recitations carry the reciter cover in artworkUrl; lectures don't, so fall
    // back to the sheikh's photo (looked up by id) when one exists.
    var art = lecture.artworkUrl;
    if (art.isEmpty && lecture.sheikhId.isNotEmpty) {
      art = ref.watch(sheikhByIdProvider(lecture.sheikhId))?.photoUrl ?? '';
    }
    if (art.isEmpty) return branded;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        art,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Show the branded block while loading and if the image fails.
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : branded,
        errorBuilder: (_, __, ___) => branded,
      ),
    );
  }
}

class _BrandedCover extends StatelessWidget {
  const _BrandedCover({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A4C3F), Color(0xFF0D2620)],
        ),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: AppTheme.display(size: 24, weight: FontWeight.w700),
          ),
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
                    trackHeight: 4,
                    activeTrackColor: AppColors.goldMid,
                    inactiveTrackColor: AppColors.cream.withValues(alpha: 0.12),
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

    final repeatColor =
        queue.repeatMode == RepeatMode.off ? AppColors.mutedText : AppColors.gold;

    return ValueListenableBuilder<bool>(
      valueListenable: controller.hasErrorNotifier,
      builder: (context, hasError, __) => StreamBuilder<PlayerState>(
      stream: handler.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processing = playerState?.processingState;
        final playing = playerState?.playing ?? false;
        // Don't show the "busy" spinner when we're actually in an error state
        // waiting for a retry — show the retry button instead.
        final isBusy = !hasError &&
            (processing == ProcessingState.loading ||
                processing == ProcessingState.buffering);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              color: queue.shuffle ? AppColors.gold : AppColors.mutedText,
              icon: const PxIcon(Px.shuffle, size: 22),
              tooltip: 'Shuffle',
              onPressed: controller.toggleShuffle,
            ),
            IconButton(
              color: AppColors.cream,
              icon: const PxIcon(Px.skipBack, size: 28),
              onPressed: controller.previous,
            ),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isBusy
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: Color(0xFF0D2620), strokeWidth: 3),
                    )
                  : IconButton(
                      color: const Color(0xFF0D2620),
                      icon: PxIcon(
                          hasError
                              ? Px.arrowClockwise
                              : (playing ? Px.pauseFill : Px.playFill),
                          size: 26),
                      tooltip: hasError ? 'Retry' : null,
                      onPressed: () => hasError
                          ? controller.retry()
                          : (playing ? handler.pause() : controller.play()),
                    ),
            ),
            IconButton(
              color: queue.hasNext ? AppColors.cream : AppColors.mutedText,
              icon: const PxIcon(Px.skipForward, size: 28),
              onPressed: queue.hasNext ? controller.next : null,
            ),
            IconButton(
              color: repeatColor,
              icon: const PxIcon(Px.repeat, size: 22),
              tooltip: 'Repeat',
              onPressed: controller.cycleRepeat,
            ),
          ],
        );
      },
    ),
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

    final queueColor =
        queue.queue.length > 1 ? AppColors.cream : AppColors.mutedText;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _SeekButton(
          icon: Px.arrowCounterClockwise,
          label: '10',
          onTap: () => seekRelative(const Duration(seconds: -10)),
        ),
        IconButton(
          iconSize: 24,
          color: queueColor,
          icon: const PxIcon(Px.queue, size: 22),
          tooltip: 'Queue',
          onPressed:
              queue.queue.length > 1 ? () => showQueueSheet(context) : null,
        ),
        _SeekButton(
          icon: Px.arrowClockwise,
          label: '30',
          onTap: () => seekRelative(const Duration(seconds: 30)),
        ),
      ],
    );
  }
}

/// A relative-seek control: Phosphor arrow with its seconds label underneath.
class _SeekButton extends StatelessWidget {
  const _SeekButton(
      {required this.icon, required this.label, required this.onTap});
  final PxData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PxIcon(icon, color: AppColors.cream, size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: AppColors.mutedText, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
