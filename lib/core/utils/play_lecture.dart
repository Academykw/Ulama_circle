import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/lecture_model.dart';
import '../../providers/player_provider.dart';
import '../../screens/player/player_screen.dart';

/// The app's core interaction: start playing a lecture (instant playback +
/// silent background caching) and open the full player.
///
/// Pass [queue] (the surrounding list) + [index] so the whole list becomes the
/// play queue — enabling auto-play-next, repeat, and shuffle. Omit them for a
/// standalone lecture (e.g. resuming a single history entry).
void openLecture(
  BuildContext context,
  WidgetRef ref,
  LectureModel lecture, {
  List<LectureModel>? queue,
  int? index,
}) {
  final controller = ref.read(playbackControllerProvider);
  if (queue != null && index != null) {
    controller.playQueue(queue, index);
  } else {
    controller.playLecture(lecture);
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PlayerScreen()),
  );
}
