import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Wraps a just_audio [AudioPlayer] and exposes it to the OS via audio_service,
/// so playback continues in the background and shows a media notification /
/// lock-screen controls. This is the single player instance for the whole app.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  // Buffer tuning balances two things:
  //   • fast START — [bufferForPlaybackDuration] is how much must buffer before
  //     playback begins; kept low (1s) so streaming starts quickly.
  //   • smooth PLAYBACK — [minBuffer]/[maxBuffer] keep a healthy runway ahead so
  //     the audio doesn't underrun/crackle on slower connections.
  final AudioPlayer _player = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        // Keep a bigger runway ahead so brief network hiccups don't underrun
        // the buffer and stall playback. Start latency is governed by
        // bufferForPlaybackDuration (1s), so raising min/max doesn't slow the
        // initial start — it just makes ongoing playback more hiccup-proof.
        minBufferDuration: Duration(seconds: 30),
        maxBufferDuration: Duration(seconds: 120),
        bufferForPlaybackDuration: Duration(milliseconds: 1000),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 3),
      ),
      darwinLoadControl: DarwinLoadControl(
        automaticallyWaitsToMinimizeStalling: false,
        preferredForwardBufferDuration: Duration(seconds: 30),
      ),
    ),
  );

  /// Set by PlaybackController so notification / lock-screen skip buttons drive
  /// the queue. Completion-driven auto-advance is handled by the controller too
  /// (it listens to [playerStateStream]).
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  /// Emits whenever playback fails (e.g. the stream drops on a bad network).
  /// The controller listens to auto-retry; the UI listens to show a message.
  final StreamController<Object> _errors = StreamController<Object>.broadcast();
  Stream<Object> get errorStream => _errors.stream;

  AudioPlayerHandler() {
    // Push just_audio state changes out to the OS notification. A network drop
    // surfaces as a stream ERROR here — catch it so it doesn't go unhandled,
    // flag the notification as errored, and let listeners react/retry.
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object e, StackTrace _) {
        _errors.add(e);
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
        ));
      },
    );

    // Keep the media notification's duration accurate once known.
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  // --- Streams the player screen listens to ---
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;
  Duration? get duration => _player.duration;
  Duration get position => _player.position;
  bool get playing => _player.playing;

  /// Repeat-one is delegated to just_audio's loop mode (seamless); repeat-off /
  /// -all are handled by the controller on completion.
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  /// Loads a new audio source and its notification metadata. Does not auto-play.
  Future<void> setSource({
    required AudioSource source,
    required MediaItem item,
  }) async {
    mediaItem.add(item);
    await _player.setAudioSource(source);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async => onSkipToNext?.call();

  @override
  Future<void> skipToPrevious() async => onSkipToPrevious?.call();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }
}
