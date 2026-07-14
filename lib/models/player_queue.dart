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
  static PlayerQueueState forQueue(
    List<LectureModel> lectures,
    int startIndex, {
    required RepeatMode repeatMode,
    required bool shuffle,
  }) {
    final order = _buildOrder(lectures.length, startIndex, shuffle);
    return PlayerQueueState(
      queue: lectures,
      order: order,
      orderPos: 0,
      repeatMode: repeatMode,
      shuffle: shuffle,
    );
  }

  /// Order that always starts with [startIndex]; the rest is sequential or
  /// shuffled.
  static List<int> _buildOrder(int length, int startIndex, bool shuffle) {
    final rest = [
      for (var i = 0; i < length; i++)
        if (i != startIndex) i
    ];
    if (shuffle) rest.shuffle(Random());
    return [if (length > 0) startIndex, ...rest];
  }

  /// Re-derives the play order when shuffle is toggled, keeping the current
  /// lecture playing (moved to the front of the new order).
  PlayerQueueState withShuffle(bool value) {
    final cur = currentIndex ?? 0;
    final order = _buildOrder(queue.length, cur, value);
    return copyWith(order: order, orderPos: 0, shuffle: value);
  }
}
