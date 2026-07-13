import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';
import '../models/downloaded_lecture_model.dart';
import '../models/lecture_model.dart';
import 'local_db_service.dart';

/// Owns the filesystem side of downloads: fetches audio with Dio, writes it into
/// app-private storage, and records it via [LocalDbService]. The Hive record is
/// the app's source of truth for "is this downloaded?"; this service keeps the
/// actual file and that record in sync.
///
/// App-private storage (ApplicationDocumentsDirectory) needs no runtime
/// permission on Android/iOS.
class DownloadService {
  DownloadService(this._localDb, {Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final LocalDbService _localDb;

  Future<Directory> _audioDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/${AppConstants.localAudioFolder}');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _fileFor(Directory dir, String lectureId) =>
      File('${dir.path}/$lectureId.mp3');

  /// Downloads a lecture's audio and saves its record. Downloads to a `.tmp`
  /// first, then renames on success — so an interrupted download never leaves a
  /// partial file that looks complete. Returns the saved record.
  Future<DownloadedLecture> download(
    LectureModel lecture, {
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final dir = await _audioDir();
    final file = _fileFor(dir, lecture.id);
    final tmp = File('${file.path}.tmp');

    await _dio.download(
      lecture.audioUrl,
      tmp.path,
      onReceiveProgress: onProgress,
      cancelToken: cancelToken,
    );

    if (file.existsSync()) file.deleteSync();
    tmp.renameSync(file.path);

    final record = DownloadedLecture(
      id: lecture.id,
      title: lecture.title,
      sheikhName: lecture.sheikhName,
      localFilePath: file.path,
      downloadedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      fileSizeBytes: file.lengthSync(),
    );
    await _localDb.saveDownload(record);
    return record;
  }

  bool isDownloaded(String lectureId) => _localDb.isDownloaded(lectureId);

  /// The on-disk path a lecture's audio should live at. Used by the player's
  /// LockCachingAudioSource so streaming-while-playing caches to the SAME file
  /// the Dio downloader would use — one cache, shared by both paths.
  Future<File> targetFile(String lectureId) async {
    final dir = await _audioDir();
    return _fileFor(dir, lectureId);
  }

  /// Records a lecture as downloaded from an already-present file (e.g. once the
  /// player's LockCachingAudioSource has finished caching it). Idempotent.
  Future<DownloadedLecture> registerExistingFile(
      LectureModel lecture, File file) async {
    final record = DownloadedLecture(
      id: lecture.id,
      title: lecture.title,
      sheikhName: lecture.sheikhName,
      localFilePath: file.path,
      downloadedAtEpoch: DateTime.now().millisecondsSinceEpoch,
      fileSizeBytes: file.existsSync() ? file.lengthSync() : 0,
    );
    await _localDb.saveDownload(record);
    return record;
  }

  /// Local file path if downloaded AND the file still exists on disk. Returns
  /// null (and cleans up a stale record) if the file went missing.
  Future<String?> playablePath(String lectureId) async {
    final path = _localDb.localPathFor(lectureId);
    if (path == null) return null;
    if (File(path).existsSync()) return path;
    // Record points at a file that's gone — self-heal by dropping the record.
    await _localDb.removeDownloadRecord(lectureId);
    return null;
  }

  /// Deletes the audio file, its records, and any sidecar files. Dio leaves a
  /// `.tmp`; LockCachingAudioSource leaves a `.mime` — clean up both.
  void _deleteFileAndSidecars(String path) {
    for (final p in [path, '$path.tmp', '$path.mime']) {
      final f = File(p);
      if (f.existsSync()) f.deleteSync();
    }
  }

  /// Deletes the file (if present) and its record.
  Future<void> delete(String lectureId) async {
    final path = _localDb.localPathFor(lectureId);
    if (path != null) _deleteFileAndSidecars(path);
    await _localDb.removeDownloadRecord(lectureId);
  }

  /// Deletes every downloaded file and clears all records. For the download
  /// manager's "clear all".
  Future<void> deleteAll() async {
    for (final rec in _localDb.allDownloads()) {
      _deleteFileAndSidecars(rec.localFilePath);
    }
    await _localDb.clearAllDownloadRecords();
  }
}
