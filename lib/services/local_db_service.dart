import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../core/constants/app_constants.dart';
import '../hive_registrar.g.dart';
import '../models/downloaded_lecture_model.dart';
import '../models/history_entry.dart';

/// The single owner of all Hive access. Nothing else in the app should call
/// `Hive.box(...)` directly — go through this service so box names, adapter
/// registration, and (de)serialization live in one place.
///
/// Two boxes:
///   - `downloaded_lectures` (typed) — the on-disk audio catalog
///   - `app_meta` (untyped key/value) — onboarding flag, theme, playback resume
class LocalDbService {
  late final Box<DownloadedLecture> _downloads;
  late final Box _meta;

  /// Call once during app startup, after `Hive.initFlutter()`.
  Future<void> init() async {
    Hive.registerAdapters(); // from hive_registrar.g.dart
    _downloads =
        await Hive.openBox<DownloadedLecture>(AppConstants.downloadedLecturesBox);
    _meta = await Hive.openBox(AppConstants.appMetaBox);
  }

  // ---------------------------------------------------------------------------
  // Downloaded lectures
  // ---------------------------------------------------------------------------

  bool isDownloaded(String lectureId) => _downloads.containsKey(lectureId);

  DownloadedLecture? getDownload(String lectureId) => _downloads.get(lectureId);

  /// Local file path for a downloaded lecture, or null if not downloaded.
  String? localPathFor(String lectureId) => _downloads.get(lectureId)?.localFilePath;

  Future<void> saveDownload(DownloadedLecture record) =>
      _downloads.put(record.id, record);

  /// Removes only the Hive record. Deleting the actual file on disk is the
  /// DownloadService's job — it owns the filesystem.
  Future<void> removeDownloadRecord(String lectureId) =>
      _downloads.delete(lectureId);

  /// All downloads, newest first — for the Download Manager screen.
  List<DownloadedLecture> allDownloads() {
    final list = _downloads.values.toList()
      ..sort((a, b) => b.downloadedAtEpoch.compareTo(a.downloadedAtEpoch));
    return list;
  }

  int get downloadCount => _downloads.length;

  /// Total bytes used by downloaded audio — drives the "X MB used" display.
  int totalDownloadedBytes() =>
      _downloads.values.fold(0, (sum, d) => sum + d.fileSizeBytes);

  /// Reactive handle for the downloads box, so screens rebuild on change.
  ValueListenable<Box<DownloadedLecture>> downloadsListenable() =>
      _downloads.listenable();

  Future<void> clearAllDownloadRecords() => _downloads.clear();

  // ---------------------------------------------------------------------------
  // App meta (untyped key/value)
  // ---------------------------------------------------------------------------

  bool get onboardingSeen =>
      _meta.get(AppConstants.metaKeyOnboardingSeen, defaultValue: false) as bool;

  Future<void> setOnboardingSeen(bool value) =>
      _meta.put(AppConstants.metaKeyOnboardingSeen, value);

  /// Theme mode persisted as a string: 'system' | 'light' | 'dark'.
  String get themeMode =>
      _meta.get(AppConstants.metaKeyThemeMode, defaultValue: 'system') as String;

  Future<void> setThemeMode(String mode) =>
      _meta.put(AppConstants.metaKeyThemeMode, mode);

  bool get isGuest =>
      _meta.get(AppConstants.metaKeyIsGuest, defaultValue: false) as bool;

  Future<void> setIsGuest(bool value) =>
      _meta.put(AppConstants.metaKeyIsGuest, value);

  // ---- Resume playback (local cache for instant offline resume) ----
  // Stored under a single map key so we don't need a new Hive box/adapter.
  // The authoritative history still lives in Firestore per the schema; this is
  // just a fast local mirror for "continue listening".

  static const String _positionsKey = 'playback_positions';

  int positionFor(String lectureId) {
    final map = _meta.get(_positionsKey) as Map?;
    final value = map?[lectureId];
    return value is int ? value : 0;
  }

  Future<void> setPosition(String lectureId, int seconds) async {
    final raw = _meta.get(_positionsKey) as Map?;
    final map = <String, int>{
      if (raw != null)
        for (final entry in raw.entries)
          entry.key.toString(): (entry.value is int) ? entry.value as int : 0,
    };
    map[lectureId] = seconds;
    await _meta.put(_positionsKey, map);
  }

  Future<void> clearPosition(String lectureId) async {
    final raw = _meta.get(_positionsKey) as Map?;
    if (raw == null) return;
    final map = Map<String, dynamic>.from(raw)..remove(lectureId);
    await _meta.put(_positionsKey, map);
  }

  // ---- Listening history + resume ("continue listening") ----
  // Stored as a most-recent-first list of maps under one key. Capped so it
  // never grows unbounded. Each entry carries its own resume position.

  static const String _historyKey = 'play_history';
  static const int _historyLimit = 50;

  List<HistoryEntry> history() {
    final raw = _meta.get(_historyKey) as List?;
    if (raw == null) return const [];
    return raw
        .map((e) => HistoryEntry.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  HistoryEntry? historyFor(String lectureId) {
    for (final e in history()) {
      if (e.id == lectureId) return e;
    }
    return null;
  }

  Future<void> _writeHistory(List<HistoryEntry> list) =>
      _meta.put(_historyKey, list.map((e) => e.toMap()).toList());

  /// Adds or moves an entry to the front (most recent). Used when playback of a
  /// lecture starts.
  Future<void> upsertHistory(HistoryEntry entry) async {
    final list = history().where((e) => e.id != entry.id).toList();
    list.insert(0, entry);
    if (list.length > _historyLimit) list.removeRange(_historyLimit, list.length);
    await _writeHistory(list);
  }

  /// Updates the resume position (and real duration once known) for a lecture
  /// already in history, moving it to the front. No-op if not present.
  Future<void> updateHistoryProgress(
    String lectureId, {
    required int positionSeconds,
    int? durationSeconds,
  }) async {
    final list = history();
    final idx = list.indexWhere((e) => e.id == lectureId);
    if (idx == -1) return;
    final updated = list[idx].copyWith(
      positionSeconds: positionSeconds,
      durationSeconds: durationSeconds,
      lastPlayedEpoch: DateTime.now().millisecondsSinceEpoch,
    );
    list.removeAt(idx);
    list.insert(0, updated);
    await _writeHistory(list);
  }

  Future<void> removeHistory(String lectureId) async {
    final list = history().where((e) => e.id != lectureId).toList();
    await _writeHistory(list);
  }

  Future<void> clearHistory() => _meta.delete(_historyKey);
}
