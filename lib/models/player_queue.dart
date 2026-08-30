import 'dart:math';

import 'lecture_model.dart';

enum RepeatMode { off, one, all }

/// Immutable snapshot of the play queue. [order] holds indices into [queue] in
/// the current play order (sequential, or shuffled when [shuffle] is on), and
/// [orderPos] is where we are within that order — so shuffle and repeat are just
/// different ways of walking [order].
class PlayerQueueState {
  final List<LectureModel> queue;
  final List<int> order;
  final int orderPos;
  final RepeatMode repeatMode;
  final bool shuffle;

  const PlayerQueueState({
    this.queue = const [],
    this.order = const [],
    this.orderPos = 0,
    this.repeatMode = RepeatMode.off,
    this.shuffle = false,
  });

  int? get currentIndex =>
      (order.isEmpty || orderPos < 0 || orderPos >= order.length)
          ? null
          : order[orderPos];

  LectureModel? get current {
    final i = currentIndex;
    return (i == null || i < 0 || i >= queue.length) ? null : queue[i];
  }

  bool get hasNext =>
      queue.length > 1 &&
      (orderPos < order.length - 1 || repeatMode == RepeatMode.all);

  bool get hasPrevious => orderPos > 0;

  /// The upcoming lectures (after current) in play order — for the queue sheet.
  List<LectureModel> get upNext => [
        for (var p = orderPos + 1; p < order.length; p++) queue[order[p]],
      ];

  PlayerQueueState copyWith({
    List<LectureModel>? queue,
    List<int>? order,
    int? orderPos,
    RepeatMode? repeatMode,
    bool? shuffle,
  }) {
    return PlayerQueueState(
      queue: queue ?? this.queue,
      order: order ?? this.order,
      orderPos: orderPos ?? this.orderPos,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffle: shuffle ?? this.shuffle,
    );
  }

  /// Builds a fresh state for a new queue starting at [startIndex], honoring the
  /// current shuffle setting.
  ///
  /// Sequential play keeps the natural order [0,1,2,…] and simply starts at
  /// [startIndex], so completing one track advances to the NEXT real index
  /// (5 → 6 → 7…). Only shuffle reorders — the tapped track first, the rest
  /// shuffled after it.
  static PlayerQueueState forQueue(
    List<LectureModel> lectures,
    int startIndex, {
    required RepeatMode repeatMode,
    required bool shuffle,
  }) {
    final n = lectures.length;
    final safeStart = n == 0 ? 0 : startIndex.clamp(0, n - 1);
    final List<int> order;
    final int orderPos;
    if (shuffle) {
      order = _shuffledOrder(n, safeStart);
      orderPos = 0; // tapped track sits first
    } else {
      order = [for (var i = 0; i < n; i++) i];
      orderPos = safeStart; // walk forward from here
    }
    return PlayerQueueState(
      queue: lectures,
      order: order,
      orderPos: orderPos,
      repeatMode: repeatMode,
      shuffle: shuffle,
    );
  }

  /// Shuffle order: [startIndex] first, the remaining indices shuffled after it.
  static List<int> _shuffledOrder(int length, int startIndex) {
    final rest = [
      for (var i = 0; i < length; i++)
        if (i != startIndex) i
    ]..shuffle(Random());
    return [if (length > 0) startIndex, ...rest];
  }

  /// Re-derives the play order when shuffle is toggled, keeping the current
  /// lecture playing. Turning shuffle OFF restores natural order and continues
  /// forward from the current track; turning it ON puts current first.
  PlayerQueueState withShuffle(bool value) {
    final cur = currentIndex ?? 0;
    if (value) {
      return copyWith(
          order: _shuffledOrder(queue.length, cur), orderPos: 0, shuffle: true);
    }
    return copyWith(
      order: [for (var i = 0; i < queue.length; i++) i],
      orderPos: cur,
      shuffle: false,
    );
  }
}
