import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/history_entry.dart';
import '../models/lecture_model.dart';
import '../models/player_queue.dart';
import '../services/audio_player_handler.dart';
import 'download_providers.dart';
import 'history_provider.dart';
import 'local_db_provider.dart';

/// The single AudioPlayerHandler, created via AudioService.init() in main() and
/// injected here. Reading it without that override is a deliberate fail-fast.
final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError(
    'audioHandlerProvider must be overridden in main() with the handler from '
    'AudioService.init().',
  );
});

/// The play queue (list, position, repeat, shuffle).
final playerQueueProvider =
    NotifierProvider<PlayerQueueNotifier, PlayerQueueState>(
  PlayerQueueNotifier.new,
);

class PlayerQueueNotifier extends Notifier<PlayerQueueState> {
  @override
  PlayerQueueState build() => const PlayerQueueState();

  void setQueue(List<LectureModel> lectures, int startIndex) {
    state = PlayerQueueState.forQueue(
      lectures,
      startIndex,
      repeatMode: state.repeatMode,
      shuffle: state.shuffle,
    );
  }

  /// Advances; wraps when repeat-all. Returns false at the end (repeat off).
  bool moveNext() {
    final s = state;
    if (s.orderPos < s.order.length - 1) {
      state = s.copyWith(orderPos: s.orderPos + 1);
      return true;
    }
    if (s.repeatMode == RepeatMode.all && s.order.isNotEmpty) {
      state = s.copyWith(orderPos: 0);
      return true;
    }
    return false;
  }

  bool movePrevious() {
    final s = state;
    if (s.orderPos > 0) {
      state = s.copyWith(orderPos: s.orderPos - 1);
      return true;
    }
    if (s.repeatMode == RepeatMode.all && s.order.isNotEmpty) {
      state = s.copyWith(orderPos: s.order.length - 1);
      return true;
    }
    return false;
  }

  void jumpTo(int queueIndex) {
    final pos = state.order.indexOf(queueIndex);
    if (pos != -1) state = state.copyWith(orderPos: pos);
  }

  void setRepeat(RepeatMode mode) => state = state.copyWith(repeatMode: mode);
  void toggleShuffle() => state = state.withShuffle(!state.shuffle);
}

/// The lecture currently loaded — derived from the queue so every consumer
/// (player, mini-player) stays in sync automatically.
final currentLectureProvider =
    Provider<LectureModel?>((ref) => ref.watch(playerQueueProvider).current);

/// Coordinates playback: source loading (local vs stream+cache), the queue,
/// auto-play-next, repeat, shuffle, history, and resume.
final playbackControllerProvider =
    Provider<PlaybackController>((ref) => PlaybackController(ref));

class PlaybackController {
  PlaybackController(this._ref) {
    final handler = _ref.read(audioHandlerProvider);
    // Notification / lock-screen skip buttons drive the queue.
    handler.onSkipToNext = next;
    handler.onSkipToPrevious = previous;
    // Auto-advance on track completion (repeat-one is handled by LoopMode and
    // never emits completed).
    _completionSub = handler.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _onCompletion();
    });
  }

  final Ref _ref;
  StreamSubscription<double>? _cacheSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<ProcessingState>? _completionSub;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);

  AudioPlayerHandler get _handler => _ref.read(audioHandlerProvider);
  PlayerQueueNotifier get _queue => _ref.read(playerQueueProvider.notifier);

  /// Loads [lectures] as the queue and starts at [startIndex]. This is the
  /// "tap a list → the whole list becomes the queue" behavior.
  Future<void> playQueue(List<LectureModel> lectures, int startIndex) async {
    _queue.setQueue(lectures, startIndex);
    await _playCurrent();
  }

  /// Single-lecture convenience (used where there's no surrounding list).
  Future<void> playLecture(LectureModel lecture) => playQueue([lecture], 0);

  Future<void> next() async {
    if (_queue.moveNext()) await _playCurrent();
  }

  Future<void> previous() async {
    // Restart the current lecture if we're already a few seconds in — the
    // familiar "previous" behavior — otherwise go to the prior track.
    if (_handler.position.inSeconds > 3) {
      await _handler.seek(Duration.zero);
      return;
    }
    if (_queue.movePrevious()) await _playCurrent();
  }

  Future<void> jumpTo(int queueIndex) async {
    _queue.jumpTo(queueIndex);
    await _playCurrent();
  }

  /// Cycles off → all → one → off. Repeat-one uses just_audio's seamless loop.
  void cycleRepeat() {
    final current = _ref.read(playerQueueProvider).repeatMode;
    const order = [RepeatMode.off, RepeatMode.all, RepeatMode.one];
    final nextMode = order[(order.indexOf(current) + 1) % order.length];
    _queue.setRepeat(nextMode);
    _handler.setLoopMode(
        nextMode == RepeatMode.one ? LoopMode.one : LoopMode.off);
  }

  void toggleShuffle() => _queue.toggleShuffle();

  Future<void> play() => _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seek(Duration position) => _handler.seek(position);

  Future<void> _onCompletion() async {
    if (_ref.read(playerQueueProvider).hasNext) {
      await next();
    } else {
      await _handler.pause();
      await _handler.seek(Duration.zero);
    }
  }

  /// Loads and plays the queue's current lecture: local file if downloaded,
  /// else stream-and-cache. Records history and resumes from any saved point.
  Future<void> _playCurrent() async {
    final lecture = _ref.read(playerQueueProvider).current;
    if (lecture == null) return;

    final downloadService = _ref.read(downloadServiceProvider);
    final downloads = _ref.read(downloadControllerProvider.notifier);
    final localDb = _ref.read(localDbServiceProvider);

    _cacheSub?.cancel();
    _posSub?.cancel();

    final localPath = await downloadService.playablePath(lecture.id);
    final AudioSource source;
    if (localPath != null) {
      source = AudioSource.uri(Uri.file(localPath));
    } else {
      final cacheFile = await downloadService.targetFile(lecture.id);
      // ignore: experimental_member_use
      final caching = LockCachingAudioSource(
        Uri.parse(lecture.audioUrl),
        cacheFile: cacheFile,
      );
      _cacheSub = caching.downloadProgressStream.listen((progress) {
        if (progress >= 1.0) {
          downloads.markCached(lecture, cacheFile);
          _cacheSub?.cancel();
        } else {
          downloads.reportCacheProgress(lecture.id, progress);
        }
      });
      source = caching;
    }

    final previous = localDb.historyFor(lecture.id);
    final resumeAt =
        (previous != null && previous.isResumable) ? previous.positionSeconds : 0;

    await localDb.upsertHistory(HistoryEntry(
      id: lecture.id,
      title: lecture.title,
      sheikhId: lecture.sheikhId,
      sheikhName: lecture.sheikhName,
      audioUrl: lecture.audioUrl,
      language: lecture.language,
      category: lecture.category,
      positionSeconds: resumeAt,
      durationSeconds: previous?.durationSeconds ?? lecture.durationSeconds,
      lastPlayedEpoch: DateTime.now().millisecondsSinceEpoch,
    ));
    _ref.read(historyRevisionProvider.notifier).bump();

    await _handler.setSource(source: source, item: _mediaItem(lecture));
    if (resumeAt > 0) await _handler.seek(Duration(seconds: resumeAt));
    await _handler.play();

    _lastProgressSave = DateTime.now();
    _posSub = _handler.positionStream.listen((position) {
      final now = DateTime.now();
      if (now.difference(_lastProgressSave).inSeconds < 5) return;
      _lastProgressSave = now;
      localDb.updateHistoryProgress(
        lecture.id,
        positionSeconds: position.inSeconds,
        durationSeconds: _handler.duration?.inSeconds,
      );
      _ref.read(historyRevisionProvider.notifier).bump();
    });
  }

  MediaItem _mediaItem(LectureModel lecture) => MediaItem(
        id: lecture.id,
        title: lecture.title,
        artist: lecture.sheikhName,
        duration: Duration(seconds: lecture.durationSeconds),
        extras: {'category': lecture.category, 'language': lecture.language},
      );
}
