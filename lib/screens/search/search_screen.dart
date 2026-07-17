import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/play_lecture.dart';
import '../../models/lecture_model.dart';
import '../../providers/search_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/favorite_button.dart';
import '../../widgets/lecture_list_tile.dart';
import '../../widgets/mini_player.dart';

/// Full-screen search: a search field in the app bar, debounced, with results
/// below. Backed by [searchResultsProvider] (Firestore keyword search for now).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    // Reset the query so a fresh search starts clean next time.
    Future.microtask(() => ref.read(searchQueryProvider.notifier).set(''));
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(searchQueryProvider.notifier).set(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: AppColors.cream, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search lectures, sheikhs, topics…',
            hintStyle: TextStyle(color: AppColors.mutedText),
            border: InputBorder.none,
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: Icon(Icons.close, color: AppColors.mutedText),
                    onPressed: () {
                      _controller.clear();
                      _onChanged('');
                      setState(() {});
                    },
                  ),
          ),
        ),
      ),
      body: _body(query, results),
    );
  }

  Widget _body(String query, AsyncValue<List<LectureModel>> results) {
    if (query.trim().length < 2) {
      return const EmptyState(
        icon: Icons.search,
        title: 'Search Ulama Circle',
        subtitle: 'Find lectures by title, sheikh, category, or language',
      );
    }

    return results.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (_, __) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Search failed',
        subtitle: 'Please try again',
      ),
      data: (lectures) {
        if (lectures.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: 'No results for “$query”',
            subtitle: 'Try a different word',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
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
