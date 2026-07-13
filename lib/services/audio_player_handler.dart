import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Wraps a just_audio [AudioPlayer] and exposes it to the OS via audio_service,
/// so playback continues in the background and shows a media notification /
/// lock-screen controls. This is the single player instance for the whole app.
class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  /// Set by PlaybackController so notification / lock-screen skip buttons drive
  /// the queue. Completion-driven auto-advance is handled by the controller too
  /// (it listens to [playerStateStream]).
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;

  AudioPlayerHandler() {
    // Push just_audio state changes out to the OS notification.
    _player.playbackEventStream.listen(_broadcastState);

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
