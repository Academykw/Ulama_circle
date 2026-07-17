import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/play_lecture.dart';
import '../../models/downloaded_lecture_model.dart';
import '../../models/lecture_model.dart';
import '../../providers/download_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/local_db_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/lecture_list_tile.dart';
import '../playlist/playlists_view.dart';

/// The Library tab: Downloads / History / Liked / Playlists. Downloads is live
/// (backed by the download store); the others land on Days 13 & 20 and show
/// empty states for now.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          backgroundColor: AppColors.charcoal,
          title: const Text('Library'),
          titleTextStyle: TextStyle(
              color: AppColors.cream, fontSize: 22, fontWeight: FontWeight.w700),
          bottom: TabBar(
            // Non-scrollable → the 4 tabs share the width evenly.
            indicatorColor: AppColors.gold,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.mutedText,
            labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            labelPadding: const EdgeInsets.symmetric(vertical: 4),
            tabs: const [
              Tab(text: 'Downloads'),
              Tab(text: 'History'),
              Tab(text: 'Liked'),
              Tab(text: 'Playlists'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DownloadsTab(),
            _HistoryTab(),
            _LikedTab(),
            PlaylistsView(),
          ],
        ),
      ),
    );
  }
}

/// Live list of downloaded lectures with total size + delete. Reactive to the
/// download store, so items appear/vanish as downloads complete or are removed.
class _DownloadsTab extends ConsumerWidget {
  const _DownloadsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild when the download map changes.
    ref.watch(downloadControllerProvider);
    final db = ref.watch(localDbServiceProvider);
    final downloads = db.allDownloads();

    if (downloads.isEmpty) {
      return const EmptyState(
        icon: Icons.download_outlined,
        title: 'No downloads yet',
        subtitle: 'Play or download a lecture to keep it offline',
      );
    }

    // Read actual on-disk sizes — some records (cached during playback) stored
    // a size of 0 due to a save-timing quirk; the files themselves are intact.
    final totalBytes =
        downloads.fold<int>(0, (sum, r) => sum + _fileSize(r.localFilePath));
    final totalMb = totalBytes / (1024 * 1024);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Text(
                '${downloads.length} lecture${downloads.length == 1 ? '' : 's'} · ${Formatters.fileSize(totalMb)}',
                style: TextStyle(color: AppColors.mutedText, fontSize: 13),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _confirmClearAll(context, ref),
                child: const Text('Clear all',
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: downloads.length,
            itemBuilder: (context, i) =>
                _DownloadRow(record: downloads[i], ref: ref),
          ),
        ),
      ],
    );
  }

  static int _fileSize(String path) {
    final f = File(path);
    return f.existsSync() ? f.lengthSync() : 0;
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text('Clear all downloads?',
            style: TextStyle(color: AppColors.cream)),
        content: Text(
          'This deletes every downloaded lecture from this device.',
          style: TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete all',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(downloadServiceProvider).deleteAll();
      // Reset the in-memory download state map.
      ref.invalidate(downloadControllerProvider);
    }
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.record, required this.ref});
  final DownloadedLecture record;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => openLecture(context, ref, _asLecture(record)),
      leading: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [AppColors.olive, AppColors.surfaceDark],
          ),
        ),
        child: Icon(Icons.play_arrow, color: AppColors.cream, size: 22),
      ),
      title: Text(
        record.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${record.sheikhName}  ·  ${Formatters.fileSize(_DownloadsTab._fileSize(record.localFilePath) / (1024 * 1024))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.mutedText, fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: AppColors.mutedText),
        tooltip: 'Delete download',
        onPressed: () =>
            ref.read(downloadControllerProvider.notifier).delete(record.id),
      ),
    );
  }

  /// Minimal LectureModel from a download record — enough to play the local
  /// file (playback resolves the local path by id; audioUrl is unused here).
  LectureModel _asLecture(DownloadedLecture r) => LectureModel(
        id: r.id,
        title: r.title,
        sheikhId: '',
        sheikhName: r.sheikhName,
        audioUrl: '',
        durationSeconds: 0,
        language: '',
        category: '',
        isFeatured: false,
        dateAdded: r.downloadedAt,
        fileSizeMb: r.fileSizeBytes / (1024 * 1024),
      );
}

/// Recently played, most recent first. Each row shows a resume progress bar and
/// resumes playback on tap.
class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No history yet',
        subtitle: 'Lectures you play will show up here',
      );
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () async {
                await ref.read(localDbServiceProvider).clearHistory();
                ref.read(historyRevisionProvider.notifier).bump();
              },
              child: const Text('Clear',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: history.length,
            itemBuilder: (context, i) {
              final entry = history[i];
              return ListTile(
                onTap: () => openLecture(context, ref, entry.toLecture()),
                leading: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [AppColors.olive, AppColors.surfaceDark],
                    ),
                  ),
                  child: Icon(Icons.play_arrow,
                      color: AppColors.cream, size: 22),
                ),
                title: Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.isResumable
                          ? '${entry.sheikhName}  ·  resume ${Formatters.clock(Duration(seconds: entry.positionSeconds))}'
                          : entry.sheikhName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12),
                    ),
                    if (entry.progress > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: entry.progress,
                          minHeight: 3,
                          backgroundColor: AppColors.surfaceDark,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Liked lectures, resolved from the user's favorites.
class _LikedTab extends ConsumerWidget {
  const _LikedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedLecturesProvider);
    return liked.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn’t load liked lectures',
      ),
      data: (lectures) {
        if (lectures.isEmpty) {
          return const EmptyState(
            icon: Icons.favorite_border,
            title: 'Nothing liked yet',
            subtitle: 'Tap the heart on a lecture to save it here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: lectures.length,
          itemBuilder: (context, i) {
            final lecture = lectures[i];
            return LectureListTile(
              lecture: lecture,
              onTap: () =>
                  openLecture(context, ref, lecture, queue: lectures, index: i),
              trailing: FavoriteButton(lectureId: lecture.id),
            );
          },
        );
      },
    );
  }
}
