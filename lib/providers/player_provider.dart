import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../models/history_entry.dart';
import '../models/lecture_model.dart';
import '../models/player_queue.dart';
import '../services/audio_player_handler.dart';
import '../services/engagement_service.dart';
import 'connectivity_provider.dart';
import 'content_providers.dart';
import 'download_providers.dart';
import 'history_provider.dart';
import 'local_db_provider.dart';

/// Surfaces playback errors (network drops) to the UI so it can show a message.
final playerErrorProvider = StreamProvider<Object>(
    (ref) => ref.watch(audioHandlerProvider).errorStream);

/// Transient, self-healing playback notices (e.g. "weak connection, buffering")
/// — shown as a brief toast; unlike [playerErrorProvider] these don't put the
/// player into a retry state.
final playbackNoticeProvider = StreamProvider<String>(
    (ref) => ref.watch(playbackControllerProvider).notices);

/// Reactive "playback failed" flag (stream dropped, waiting to retry). The play
/// button watches this notifier to show a retry affordance; it flips back to
/// false on a successful (re)load.
final playerErrorStateProvider = Provider<ValueNotifier<bool>>(
    (ref) => ref.watch(playbackControllerProvider).hasErrorNotifier);

/// Records plays/listens for trending + the admin dashboard.
final engagementServiceProvider =
    Provider<EngagementService>((ref) => EngagementService());

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
    // never emits completed). The controller is an app-lifetime singleton, so
    // these subscriptions intentionally live for the whole session.
    handler.processingStateStream.listen(
      (state) {
        if (state == ProcessingState.completed) _onCompletion();
      },
      onError: (_, __) {/* surfaced via errorStream below */},
    );
    // A network drop while streaming: remember it so the play button offers a
    // retry, and auto-resume once the connection comes back.
    handler.errorStream.listen((_) => hasErrorNotifier.value = true);
    _ref.listen<AsyncValue<bool>>(connectivityProvider, (prev, next) {
      final online = next.value ?? false;
      if (online && hasErrorNotifier.value) {
        // Fire-and-forget from a Riverpod listener callback — guard so a
        // reconnect-triggered reload failure can't escape uncaught.
        retry().catchError((_) {});
      }
    });
    // Start/stop the fallback retry poll alongside the error flag itself, so
    // it covers both entry points into the error state (the stream listener
    // above and _playCurrent's own catch block).
    hasErrorNotifier.addListener(() {
      if (hasErrorNotifier.value) {
        _startAutoRetryPoll();
      } else {
        _autoRetryTimer?.cancel();
      }
    });
  }

  void _startAutoRetryPoll() {
    _autoRetryTimer?.cancel();
    _autoRetryTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!hasErrorNotifier.value || _autoRetrying) return;
      _autoRetrying = true;
      try {
        await retry();
      } catch (_) {/* still down — the next tick tries again */} finally {
        _autoRetrying = false;
      }
    });
  }

  final Ref _ref;
  StreamSubscription<double>? _cacheSub;
  StreamSubscription<Duration>? _posSub;
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  // Stall watchdog: a streaming buffer underrun can leave ExoPlayer "playing"
  // but frozen (position stops advancing) without auto-resuming. We watch the
  // position and, if it's stuck while playing, nudge it (pause→play) — the same
  // recovery a user does by hand.
  Timer? _stallTimer;
  Duration _lastWatchPos = Duration.zero;
  int _stalledTicks = 0;
  bool _stallNotified = false; // one toast per stall episode
  final StreamController<String> _notices = StreamController<String>.broadcast();
  Stream<String> get notices => _notices.stream;
  /// Reactive flag: true while playback is in a failed state (stream dropped),
  /// cleared on a successful (re)load.
  final ValueNotifier<bool> hasErrorNotifier = ValueNotifier<bool>(false);
  bool get hasError => hasErrorNotifier.value;
  // Fallback self-healing: the connectivity listener above only fires on an
  // offline→online EDGE, so a degraded connection that never actually drops
  // (weak signal, flaky DNS, a captive portal) — where the OS link never
  // reports "offline" — would otherwise leave the user stuck in the error
  // state forever unless they happen to manually tap play again. This polls
  // instead, so it always eventually recovers on its own.
  Timer? _autoRetryTimer;
  bool _autoRetrying = false;
  // Whether the current queue is Quran recitations (vs lectures) — decides which
  // engagement counter to bump when a track starts.
  bool _isRecitationQueue = false;

  AudioPlayerHandler get _handler => _ref.read(audioHandlerProvider);
  PlayerQueueNotifier get _queue => _ref.read(playerQueueProvider.notifier);

  /// Loads [lectures] as the queue and starts at [startIndex]. This is the
  /// "tap a list → the whole list becomes the queue" behavior. Set
  /// [isRecitation] when the queue is Quran recitations so listens (not plays)
  /// are counted.
  Future<void> playQueue(
    List<LectureModel> lectures,
    int startIndex, {
    bool isRecitation = false,
  }) async {
    _isRecitationQueue = isRecitation;
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

  // If the last load errored (network drop), the play button re-attempts the
  // stream instead of a no-op resume.
  Future<void> play() => hasError ? retry() : _handler.play();
  Future<void> pause() => _handler.pause();
  Future<void> seek(Duration position) => _handler.seek(position);

  /// Re-loads the current track from its last saved position — recovers from a
  /// network error, either from the play button or automatically on reconnect.
  Future<void> retry() async {
    if (_ref.read(playerQueueProvider).current == null) return;
    await _playCurrent();
  }

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
    final localDb = _ref.read(localDbServiceProvider);

    _cacheSub?.cancel();
    _posSub?.cancel();
    _stallTimer?.cancel();

    final localPath = await downloadService.playablePath(lecture.id);
    final AudioSource source;
    if (localPath != null) {
      // Downloaded → play the local file (works offline).
      source = AudioSource.uri(Uri.file(localPath));
    } else {
      // Stream only — NO on-device caching. Saving a lecture for offline is an
      // explicit (Premium) Download action, handled by DownloadButton; playback
      // no longer silently persists audio to disk.
      source = AudioSource.uri(Uri.parse(lecture.audioUrl));
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
      artworkUrl: lecture.artworkUrl,
      positionSeconds: resumeAt,
      durationSeconds: previous?.durationSeconds ?? lecture.durationSeconds,
      lastPlayedEpoch: DateTime.now().millisecondsSinceEpoch,
    ));
    _ref.read(historyRevisionProvider.notifier).bump();
    // Count plays so we can ask for a store review after a few listens.
    localDb.incrementPlayCount();

    try {
      // A bounded timeout so a hung DNS lookup / stalled TCP connect can never
      // leave the UI stuck on an endless spinner with no error and no retry —
      // it surfaces as a normal load failure instead, through the same
      // error/retry path as any other network error below.
      await _handler
          .setSource(source: source, item: _mediaItem(lecture))
          .timeout(const Duration(seconds: 20));
      if (resumeAt > 0) await _handler.seek(Duration(seconds: resumeAt));
      await _handler.play();
      hasErrorNotifier.value = false; // loaded OK — clear any prior error
    } catch (_) {
      // Synchronous load failure (e.g. no network when starting). Keep the
      // lecture loaded so the user can retry; auto-resumes on reconnect.
      hasErrorNotifier.value = true;
      return;
    }

    // Fire-and-forget engagement count (trending + dashboard). Non-critical.
    final engagement = _ref.read(engagementServiceProvider);
    if (_isRecitationQueue) {
      engagement.recordRecitationListen(lecture.id);
    } else {
      engagement.recordLecturePlay(lecture.id);
    }

    _lastProgressSave = DateTime.now();
    _posSub = _handler.positionStream.listen((position) {
      // A Stream.listen callback runs outside Flutter's own error zone, so an
      // exception here (e.g. a Hive write racing a box close during a network-
      // triggered lifecycle change) would otherwise go uncaught — non-fatal,
      // just skip this progress tick.
      try {
        final now = DateTime.now();
        if (now.difference(_lastProgressSave).inSeconds < 5) return;
        _lastProgressSave = now;
        localDb.updateHistoryProgress(
          lecture.id,
          positionSeconds: position.inSeconds,
          durationSeconds: _handler.duration?.inSeconds,
        );
        _ref.read(historyRevisionProvider.notifier).bump();
      } catch (_) {/* best-effort progress save */}
    }, onError: (_, __) {/* surfaced via errorStream */});

    // Only streamed audio can underrun; local files never stall.
    if (localPath == null) _startStallWatch();
  }

  /// Watches for a streaming stall: position frozen while still "playing".
  /// After ~10s stuck, nudge playback (pause→play) to force a rebuffer — the
  /// same thing the user would do by hand.
  void _startStallWatch() {
    _stallTimer?.cancel();
    _lastWatchPos = _handler.position;
    _stalledTicks = 0;
    _stallTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // Timer callbacks run outside Flutter's error zone too — a getter
      // throwing mid-teardown (e.g. the handler tears down its player right as
      // the network drops) must not escape uncaught here.
      try {
        if (!_handler.playing) {
          _stalledTicks = 0;
          return;
        }
        final pos = _handler.position;
        final dur = _handler.duration;
        // Near the end → let it complete normally, don't nudge.
        if (dur != null && (dur - pos) < const Duration(seconds: 2)) {
          _stalledTicks = 0;
          _lastWatchPos = pos;
          return;
        }
        if (pos <= _lastWatchPos) {
          _stalledTicks++;
          if (_stalledTicks >= 2) {
            // ~10s frozen while "playing" → stalled.
            _stalledTicks = 0;
            if (!_stallNotified) {
              _stallNotified = true;
              _notices.add('Weak connection — buffering…');
            }
            _nudge();
          }
        } else {
          _stalledTicks = 0;
          _stallNotified = false; // playback recovered
        }
        _lastWatchPos = pos;
      } catch (_) {/* best-effort stall detection */}
    });
  }

  /// Recover a stalled stream by toggling play — cheap and non-destructive; if
  /// the network is still down it simply re-enters buffering and the
  /// connectivity listener retries on reconnect.
  Future<void> _nudge() async {
    try {
      await _handler.pause();
      await _handler.play();
    } catch (_) {/* best-effort */}
  }

  MediaItem _mediaItem(LectureModel lecture) {
    // Reciters carry their cover in artworkUrl; lectures fall back to the
    // sheikh's photo so the lock-screen/notification art matches Now Playing.
    var art = lecture.artworkUrl;
    if (art.isEmpty && lecture.sheikhId.isNotEmpty) {
      art = _ref.read(sheikhByIdProvider(lecture.sheikhId))?.photoUrl ?? '';
    }
    return MediaItem(
      id: lecture.id,
      title: lecture.title,
      artist: lecture.sheikhName,
      duration: Duration(seconds: lecture.durationSeconds),
      artUri: art.isEmpty ? null : Uri.parse(art),
      extras: {'category': lecture.category, 'language': lecture.language},
    );
  }
}
