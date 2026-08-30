import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/play_lecture.dart';
import '../../core/utils/share_helper.dart';
import '../../models/lecture_model.dart';
import '../../models/sheikh_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/firebase_service_provider.dart';
import '../../widgets/lecture_play_button.dart';
import '../../widgets/mini_player.dart';

/// Sheikh detail: header + Lectures / Albums tabs, with search on Lectures and
/// grouped series on Albums. Pagination is managed locally in State.
class SheikhDetailScreen extends ConsumerStatefulWidget {
  const SheikhDetailScreen({super.key, required this.sheikh});

  final SheikhModel sheikh;

  @override
  ConsumerState<SheikhDetailScreen> createState() => _SheikhDetailScreenState();
}

class _SheikhDetailScreenState extends ConsumerState<SheikhDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _scroll = ScrollController();
  final _searchCtrl = TextEditingController();
  final _lectures = <LectureModel>[];

  String _query = '';
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      // When Albums is opened, make sure every lecture is loaded so grouping is
      // complete (albums span the whole catalog, not just the first page).
      if (_tab.index == 1) _loadAll();
    });
    _scroll.addListener(_onScroll);
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim()));
    _loadMore();
  }

  @override
  void dispose() {
    _tab.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  // Holds the currently-running page load so concurrent callers (the Albums
  // "load all" loop, the scroll listener, the Lectures auto-load) JOIN the same
  // fetch instead of each kicking off — or, worse, spinning in a busy-loop.
  Future<void>? _inFlight;

  Future<void> _loadMore() {
    if (!_hasMore) return Future.value();
    return _inFlight ??= _runLoad();
  }

  Future<void> _runLoad() async {
    setState(() => _loading = true);
    try {
      final page = await ref.read(firebaseServiceProvider).getLecturesBySheikh(
            widget.sheikh.id,
            startAfter: _cursor,
          );
      if (!mounted) return;
      setState(() {
        _lectures.addAll(page.items);
        _cursor = page.lastDoc;
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _inFlight = null;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAll() async {
    // Each iteration awaits a REAL fetch (start a new one or join the in-flight
    // one), so this never spins even if another loader is running.
    while (_hasMore && mounted) {
      await _loadMore();
    }
  }

  /// Standalone lectures only — anything in an album lives under the Albums
  /// tab instead, so the two tabs don't overlap.
  List<LectureModel> get _standalone =>
      _lectures.where((l) => l.album.isEmpty).toList();

  List<LectureModel> get _filtered {
    final base = _standalone;
    if (_query.isEmpty) return base;
    final q = _query.toLowerCase();
    return base.where((l) => l.title.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(widget.sheikh.name),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () => shareScholar(widget.sheikh.name),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: Column(
        children: [
          _SheikhHeader(sheikh: widget.sheikh),
          TabBar(
            controller: _tab,
            indicatorColor: AppColors.gold,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.gold,
            unselectedLabelColor: AppColors.mutedText,
            labelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            tabs: const [Tab(text: 'Lectures'), Tab(text: 'Albums')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_lecturesTab(), _albumsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // --- Lectures tab: search + numbered list ---
  Widget _lecturesTab() {
    if (_lectures.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    if (_lectures.isEmpty && _error != null) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        text: 'Couldn’t load lectures.',
        onRetry: _loadMore,
      );
    }
    if (_lectures.isEmpty) {
      return const _Message(
        icon: Icons.library_music_outlined,
        text: 'No lectures from this sheikh yet.',
      );
    }

    final list = _filtered;
    // If the loaded pages happen to be all album lectures, keep paging so any
    // standalone lectures deeper in the catalog still surface here.
    if (list.isEmpty && _query.isEmpty && _hasMore && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadMore());
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            style: TextStyle(color: AppColors.cream),
            decoration: InputDecoration(
              hintText: 'Search lectures',
              hintStyle: TextStyle(color: AppColors.faintText),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: PxIcon(Px.magnifyingGlass,
                    color: AppColors.mutedText, size: 18),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: PxIcon(Px.x,
                          color: AppColors.mutedText, size: 16),
                      onPressed: _searchCtrl.clear,
                    ),
              filled: true,
              fillColor: AppColors.cream.withValues(alpha: 0.04),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
        ),
        Expanded(
          child: list.isEmpty
              ? (_query.isNotEmpty
                  ? const _Message(
                      icon: Icons.search_off,
                      text: 'No lectures match your search.')
                  // No standalone lectures. If more pages may hold some, keep
                  // paging; otherwise everything is in Albums.
                  : (_hasMore
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.gold, strokeWidth: 2))
                      : const _Message(
                          icon: Icons.album_outlined,
                          text:
                              'All of this scholar’s lectures are in Albums — open the Albums tab.')))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: list.length + (_hasMore && _query.isEmpty ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= list.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold, strokeWidth: 2)),
                      );
                    }
                    return _LectureRow(
                      number: i + 1,
                      lecture: list[i],
                      onPlay: () => openLecture(context, ref, list[i],
                          queue: list, index: i),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- Albums tab: grouped series ---
  Widget _albumsTab() {
    if (_lectures.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gold));
    }
    final albums = <String, List<LectureModel>>{};
    for (final l in _lectures) {
      if (l.album.isEmpty) continue;
      albums.putIfAbsent(l.album, () => []).add(l);
    }
    // Within each album, numbered lectures come first in ascending order
    // (1,2,3… — a fixed course sequence). Un-numbered lectures, and any that
    // share the same number, fall back to NEWEST-first — so a weekly "feed"
    // album keeps the latest upload on top without renumbering the old ones.
    for (final list in albums.values) {
      list.sort((a, b) {
        final ao = a.order == 0 ? 1 << 30 : a.order;
        final bo = b.order == 0 ? 1 << 30 : b.order;
        return ao != bo
            ? ao.compareTo(bo)
            : b.dateAdded.compareTo(a.dateAdded); // newest first
      });
    }
    if (albums.isEmpty) {
      return const _Message(
        icon: Icons.album_outlined,
        text: 'No albums yet',
        // (Standalone lectures still appear under the Lectures tab.)
      );
    }

    final entries = albums.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: entries.length,
      itemBuilder: (context, i) =>
          _AlbumCard(name: entries[i].key, lectures: entries[i].value),
    );
  }
}

/// Header: avatar + name + "N lectures · Language" + bio.
class _SheikhHeader extends ConsumerWidget {
  const _SheikhHeader({required this.sheikh});
  final SheikhModel sheikh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(sheikhLectureCountProvider(sheikh.id)).asData?.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          _Avatar(name: sheikh.name, photoUrl: sheikh.photoUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheikh.name,
                  style: AppTheme.display(size: 20, weight: FontWeight.w700)
                      .copyWith(height: 1.2),
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    if (count != null) '$count lecture${count == 1 ? '' : 's'}',
                    Formatters.titleCase(sheikh.language),
                  ].join('  ·  '),
                  style: const TextStyle(
                      color: AppColors.goldMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                if (sheikh.bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    sheikh.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.mutedText, fontSize: 12, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.photoUrl = ''});
  final String name;
  final String photoUrl;

  String get _initials {
    const titles = {'dr', 'dr.', 'sheikh', 'shaykh', 'ustadh', 'mufti', 'imam'};
    final words = name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && !titles.contains(w.toLowerCase()))
        .toList();
    if (words.isEmpty) return name.isNotEmpty ? name[0].toUpperCase() : '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialsBox(),
          errorWidget: (_, __, ___) => _initialsBox(),
        ),
      );
    }
    return _initialsBox();
  }

  Widget _initialsBox() {
    return Container(
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3F6D5A), Color(0xFF123830)],
        ),
        border: Border.all(color: AppColors.goldMid.withValues(alpha: 0.4)),
      ),
      child: Text(
        _initials,
        style: AppTheme.display(size: 24, weight: FontWeight.w700)
            .copyWith(color: AppColors.gold),
      ),
    );
  }
}

/// Numbered lecture row with the play button trailing.
class _LectureRow extends StatelessWidget {
  const _LectureRow({
    required this.number,
    required this.lecture,
    required this.onPlay,
  });

  final int number;
  final LectureModel lecture;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final meta = [
      Formatters.titleCase(lecture.language),
      Formatters.duration(lecture.durationSeconds),
      if (lecture.playCount > 0) '${lecture.playCount} plays',
    ].join('  ·  ');

    return InkWell(
      onTap: onPlay,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$number',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            LecturePlayButton(lecture: lecture, onPlay: onPlay),
          ],
        ),
      ),
    );
  }
}

/// Expandable album (series) card. Tapping the header expands its lectures;
/// "Play all" queues the whole series.
class _AlbumCard extends ConsumerWidget {
  const _AlbumCard({required this.name, required this.lectures});
  final String name;
  final List<LectureModel> lectures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent, splashColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.gold,
          collapsedIconColor: AppColors.mutedText,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.gold, AppColors.olive],
              ),
            ),
            child: Icon(Icons.album, color: AppColors.charcoal, size: 26),
          ),
          title: Text(name,
              style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          subtitle: Text(
              '${lectures.length} lecture${lectures.length == 1 ? '' : 's'}',
              style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () =>
                      openLecture(context, ref, lectures.first, queue: lectures, index: 0),
                  icon: const PxIcon(Px.playCircleFill,
                      color: AppColors.gold, size: 20),
                  label: const Text('Play all',
                      style: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            for (var i = 0; i < lectures.length; i++)
              _LectureRow(
                number: i + 1,
                lecture: lectures[i],
                onPlay: () => openLecture(context, ref, lectures[i],
                    queue: lectures, index: i),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});
  final IconData icon;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.mutedText, size: 40),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: AppColors.mutedText)),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton(
                onPressed: onRetry,
                child: const Text('Retry',
                    style: TextStyle(color: AppColors.gold))),
          ],
        ],
      ),
    );
  }
}
