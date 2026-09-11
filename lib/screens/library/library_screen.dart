import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../l10n/app_localizations.dart';
import '../../core/utils/play_lecture.dart';
import '../../models/downloaded_lecture_model.dart';
import '../../models/lecture_model.dart';
import '../../models/reciter_model.dart';
import '../../models/sheikh_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/download_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/local_db_provider.dart';
import '../../providers/player_provider.dart';
import '../../providers/reciter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/gold_play_button.dart';
import '../../widgets/lecture_list_tile.dart';
import '../player/player_screen.dart';
import '../quran/reciter_detail_screen.dart';
import '../quran/widgets/reciter_cover.dart';
import '../sheikh_detail/sheikh_detail_screen.dart';
import '../playlist/playlists_view.dart';

/// The Library tab — a scrollable pill-tab hub:
/// Scholars · Reciters · Playlists · Downloaded · Favorites.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final labels = [
      l.tabScholars,
      l.tabReciters,
      l.tabPlaylists,
      l.tabDownloaded,
      l.tabFavorites,
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(l.library,
                  style: AppTheme.display(size: 24, weight: FontWeight.w700)),
            ),
            _PillTabs(
              labels: labels,
              selected: _tab,
              onSelect: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [
                  _ScholarsTab(),
                  _RecitersTab(),
                  PlaylistsView(),
                  _DownloadedTab(),
                  _FavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally-scrollable gold-gradient pill tabs (Home filter styling).
class _PillTabs extends StatelessWidget {
  const _PillTabs(
      {required this.labels, required this.selected, required this.onSelect});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final active = i == selected;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: active ? AppColors.goldGradient : null,
                color: active ? null : AppColors.cream.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(100),
                border: active ? null : Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: active ? const Color(0xFF0D2620) : AppColors.cream,
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Scholars ───────────────────────────

class _ScholarsTab extends ConsumerStatefulWidget {
  const _ScholarsTab();
  @override
  ConsumerState<_ScholarsTab> createState() => _ScholarsTabState();
}

class _ScholarsTabState extends ConsumerState<_ScholarsTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sheikhs = ref.watch(sheikhsProvider);
    return sheikhs.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
          icon: Icons.error_outline, title: 'Couldn’t load scholars'),
      data: (all) {
        final q = _query.trim().toLowerCase();
        final list = q.isEmpty
            ? all
            : all.where((s) => s.name.toLowerCase().contains(q)).toList();
        return Column(
          children: [
            _SearchBox(
              hint: L10n.of(context).searchScholars,
              onChanged: (v) => setState(() => _query = v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(L10n.of(context).scholarsCount(list.length),
                    style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search, title: 'No scholars found')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 190,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ScholarTile(sheikh: list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ScholarTile extends StatelessWidget {
  const _ScholarTile({required this.sheikh});
  final SheikhModel sheikh;

  String get _initials {
    final parts = sheikh.name
        .replaceAll(
            RegExp(r'(Dr\.?|Prof\.?|Sheikh|Shaykh|Ustadh|Mallam)',
                caseSensitive: false),
            '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SheikhDetailScreen(sheikh: sheikh)),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F6D5A), Color(0xFF123830)],
              ),
              image: sheikh.photoUrl.isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(sheikh.photoUrl),
                      fit: BoxFit.cover,
                      onError: (_, __) {}),
              border: Border.all(color: AppColors.goldMid.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: sheikh.photoUrl.isEmpty
                ? Text(_initials,
                    style: AppTheme.display(size: 24, weight: FontWeight.w700)
                        .copyWith(color: AppColors.gold))
                : null,
          ),
          const SizedBox(height: 10),
          Text(sheikh.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(Formatters.titleCase(sheikh.language),
                style: TextStyle(color: AppColors.cream, fontSize: 11)),
          ),
          const SizedBox(height: 5),
          Text('${Formatters.compactCount(sheikh.totalViews)} views',
              style: const TextStyle(
                  color: AppColors.goldMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────── Reciters ───────────────────────────

class _RecitersTab extends ConsumerStatefulWidget {
  const _RecitersTab();
  @override
  ConsumerState<_RecitersTab> createState() => _RecitersTabState();
}

class _RecitersTabState extends ConsumerState<_RecitersTab> {
  Future<void> _play(ReciterModel reciter) async {
    final recitations =
        await ref.read(recitationsByReciterProvider(reciter.id).future);
    if (!mounted) return;
    if (recitations.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No recitations yet')));
      return;
    }
    final lectures =
        recitations.map((r) => r.toLecture(artwork: reciter.coverUrl)).toList();
    ref.read(playbackControllerProvider).playQueue(lectures, 0,
        isRecitation: true);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final reciters = ref.watch(recitersProvider);
    return reciters.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
          icon: Icons.error_outline, title: 'Couldn’t load reciters'),
      data: (all) {
        if (all.isEmpty) {
          return EmptyState(
              icon: Icons.person_search,
              title: L10n.of(context).noRecitersYet);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: all.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'Listen to beautiful recitations from talented indigenous '
                  'Nigerian Qur’an reciters',
                  style: TextStyle(
                      color: AppColors.mutedText, fontSize: 13, height: 1.5),
                ),
              );
            }
            final r = all[i - 1];
            return _ReciterTile(
              reciter: r,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReciterDetailScreen(reciter: r))),
              onPlay: () => _play(r),
            );
          },
        );
      },
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile(
      {required this.reciter, required this.onTap, required this.onPlay});
  final ReciterModel reciter;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            ReciterCover(coverUrl: reciter.coverUrl, size: 56, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reciter.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.cream,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(Formatters.titleCase(reciter.language),
                            style: TextStyle(
                                color: AppColors.cream, fontSize: 11)),
                      ),
                      const SizedBox(width: 10),
                      Text('${reciter.surahCount} Surahs',
                          style: TextStyle(
                              color: AppColors.faintText, fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GoldPlayButton(size: 38, onTap: onPlay),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Downloaded ───────────────────────────

/// Live list of downloaded lectures with total size + delete.
class _DownloadedTab extends ConsumerWidget {
  const _DownloadedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadControllerProvider);
    final db = ref.watch(localDbServiceProvider);
    final downloads = db.allDownloads();

    if (downloads.isEmpty) {
      return EmptyState(
        icon: Icons.download_outlined,
        title: L10n.of(context).noDownloads,
        subtitle: L10n.of(context).noDownloadsSub,
      );
    }

    final totalBytes =
        downloads.fold<int>(0, (sum, r) => sum + _fileSize(r.localFilePath));
    final totalMb = totalBytes / (1024 * 1024);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Text(
                '${downloads.length} item${downloads.length == 1 ? '' : 's'} · ${Formatters.fileSize(totalMb)} offline',
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
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: downloads.length,
            itemBuilder: (context, i) => _DownloadRow(
                record: downloads[i], allDownloads: downloads, index: i, ref: ref),
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
            child:
                Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
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
      ref.invalidate(downloadControllerProvider);
    }
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    required this.record,
    required this.allDownloads,
    required this.index,
    required this.ref,
  });
  final DownloadedLecture record;
  final List<DownloadedLecture> allDownloads;
  final int index;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // Pass the whole downloads list as the queue so completing one auto-
      // advances to the next downloaded lecture instead of just stopping.
      onTap: () => openLecture(context, ref, _asLecture(record),
          queue: allDownloads.map(_asLecture).toList(), index: index),
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.goldMid.withValues(alpha: 0.14),
        ),
        child: const PxIcon(Px.checkCircleFill,
            color: AppColors.goldMid, size: 20),
      ),
      title: Text(
        record.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            color: AppColors.cream, fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${record.sheikhName}  ·  ${Formatters.fileSize(_DownloadedTab._fileSize(record.localFilePath) / (1024 * 1024))}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: AppColors.faintText, fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: AppColors.mutedText),
        tooltip: 'Delete download',
        onPressed: () =>
            ref.read(downloadControllerProvider.notifier).delete(record.id),
      ),
    );
  }

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

// ─────────────────────────── Favorites ───────────────────────────

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedLecturesProvider);
    return liked.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Couldn’t load favorites',
      ),
      data: (lectures) {
        if (lectures.isEmpty) {
          return EmptyState(
            icon: Icons.favorite_border,
            title: L10n.of(context).nothingSaved,
            subtitle: L10n.of(context).nothingSavedSub,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
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

/// Rounded search box used by the Scholars tab.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: AppColors.cream),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.faintText),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: PxIcon(Px.magnifyingGlass,
                color: AppColors.mutedText, size: 18),
          ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 0, minHeight: 0),
          filled: true,
          fillColor: AppColors.cream.withValues(alpha: 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.cardBorder),
          ),
        ),
      ),
    );
  }
}
