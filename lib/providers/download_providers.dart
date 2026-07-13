import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lecture_model.dart';
import '../services/download_service.dart';
import 'local_db_provider.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, failed }

/// Per-lecture download state for the UI. [progress] is 0..1, only meaningful
/// while [status] is downloading.
class DownloadInfo {
  final DownloadStatus status;
  final double progress;
  const DownloadInfo(this.status, [this.progress = 0]);

  static const notDownloaded = DownloadInfo(DownloadStatus.notDownloaded);
  static const downloaded = DownloadInfo(DownloadStatus.downloaded, 1);
}

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref.watch(localDbServiceProvider));
});

/// Tracks download state for lectures. Seeded from the persisted Hive records
/// on startup (so already-downloaded lectures show as downloaded immediately),
/// then updated live as the user downloads or deletes.
final downloadControllerProvider =
    NotifierProvider<DownloadController, Map<String, DownloadInfo>>(
  DownloadController.new,
);

class DownloadController extends Notifier<Map<String, DownloadInfo>> {
  final _cancelTokens = <String, CancelToken>{};

  @override
  Map<String, DownloadInfo> build() {
    final db = ref.read(localDbServiceProvider);
    return {
      for (final rec in db.allDownloads()) rec.id: DownloadInfo.downloaded,
    };
  }

  void _set(String id, DownloadInfo info) {
    state = {...state, id: info};
  }

  DownloadInfo infoFor(String lectureId) =>
      state[lectureId] ?? DownloadInfo.notDownloaded;

  /// Downloads a lecture, streaming progress into [state]. No-op if it's already
  /// downloaded or currently downloading.
  Future<void> download(LectureModel lecture) async {
    final id = lecture.id;
    final current = infoFor(id).status;
    if (current == DownloadStatus.downloading ||
        current == DownloadStatus.downloaded) {
      return;
    }

    final token = CancelToken();
    _cancelTokens[id] = token;
    _set(id, const DownloadInfo(DownloadStatus.downloading, 0));

    try {
      await ref.read(downloadServiceProvider).download(
        lecture,
        cancelToken: token,
        onProgress: (received, total) {
          if (total > 0) {
            _set(id, DownloadInfo(DownloadStatus.downloading, received / total));
          }
        },
      );
      _set(id, DownloadInfo.downloaded);
    } on DioException catch (e) {
      // A user cancel resets to not-downloaded; anything else is a failure.
      _set(id, CancelToken.isCancel(e)
          ? DownloadInfo.notDownloaded
          : const DownloadInfo(DownloadStatus.failed));
    } catch (_) {
      _set(id, const DownloadInfo(DownloadStatus.failed));
    } finally {
      _cancelTokens.remove(id);
    }
  }

  /// Reflects background caching progress from the player's LockCachingAudioSource
  /// into the shared download state — so tapping *play* also lights up the tile's
  /// download indicator. Ignored once the lecture is already downloaded.
  void reportCacheProgress(String lectureId, double progress) {
    if (infoFor(lectureId).status == DownloadStatus.downloaded) return;
    if (progress >= 1.0) return; // completion handled by markCached
    _set(lectureId, DownloadInfo(DownloadStatus.downloading, progress));
  }

  /// Called when the player finished caching a lecture during playback. Persists
  /// the record and flips state to downloaded.
  Future<void> markCached(LectureModel lecture, File file) async {
    if (infoFor(lecture.id).status == DownloadStatus.downloaded) return;
    await ref.read(downloadServiceProvider).registerExistingFile(lecture, file);
    _set(lecture.id, DownloadInfo.downloaded);
  }

  /// Cancels an in-flight download.
  void cancel(String lectureId) {
    _cancelTokens[lectureId]?.cancel('cancelled by user');
    _cancelTokens.remove(lectureId);
    _set(lectureId, DownloadInfo.notDownloaded);
  }

  /// Deletes a downloaded lecture (file + record) and resets its state.
  Future<void> delete(String lectureId) async {
    await ref.read(downloadServiceProvider).delete(lectureId);
    final next = {...state}..remove(lectureId);
    state = next;
  }
}

/// Reactive per-lecture download info for widgets. Watch this to rebuild a tile
/// as its download progresses.
final downloadInfoProvider =
    Provider.family<DownloadInfo, String>((ref, lectureId) {
  final map = ref.watch(downloadControllerProvider);
  return map[lectureId] ?? DownloadInfo.notDownloaded;
});
