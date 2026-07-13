import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../models/lecture_model.dart';
import '../../core/utils/play_lecture.dart';
import '../../providers/firebase_service_provider.dart';
import '../../widgets/download_button.dart';
import '../../widgets/lecture_list_tile.dart';

/// Paginated list of all lectures in one category (across sheikhs). Same local
/// pagination approach as the sheikh detail screen. Each tile's block shows the
/// sheikh name, so listeners can see who's teaching within the category.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  final _scroll = ScrollController();
  final _lectures = <LectureModel>[];

  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  bool _hasMore = true;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page =
          await ref.read(firebaseServiceProvider).getLecturesByCategory(
                widget.category.id,
                startAfter: _cursor,
              );
      setState(() {
        _lectures.addAll(page.items);
        _cursor = page.lastDoc;
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(title: Text(widget.category.name)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_lectures.isEmpty && _loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.gold));
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
        text: 'No lectures in this category yet.',
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _lectures.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _lectures.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2)),
          );
        }
        final lecture = _lectures[i];
        return LectureListTile(
          lecture: lecture,
          trailing: DownloadButton(lecture: lecture),
          // Tap = play instantly + cache silently; the whole list is the queue.
          onTap: () =>
              openLecture(context, ref, lecture, queue: _lectures, index: i),
        );
      },
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
          Text(text, style: const TextStyle(color: AppColors.mutedText)),
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
