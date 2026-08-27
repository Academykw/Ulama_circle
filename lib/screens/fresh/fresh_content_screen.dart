import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/play_lecture.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/content_providers.dart';
import '../../providers/filter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/language_chips.dart';
import '../../widgets/lecture_list_tile.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/network_loading.dart';

/// Full "Fresh Content" feed — the newest lectures across all scholars, opened
/// from the Home "Fresh Content" See All. Infinite-scroll paginated via
/// [latestLecturesProvider].
class FreshContentScreen extends ConsumerStatefulWidget {
  const FreshContentScreen({super.key});

  @override
  ConsumerState<FreshContentScreen> createState() => _FreshContentScreenState();
}

class _FreshContentScreenState extends ConsumerState<FreshContentScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 400) {
      ref.read(latestLecturesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestLecturesProvider);
    final controller = ref.read(latestLecturesProvider.notifier);
    final langFilter = ref.watch(languageFilterProvider);

    final l = L10n.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(title: Text(l.freshContent)),
      body: latest.when(
        loading: () => NetworkLoading(
            onRetry: () => ref.invalidate(latestLecturesProvider)),
        error: (_, __) => NetworkLoading(
            isError: true,
            onRetry: () => ref.invalidate(latestLecturesProvider)),
        data: (all) {
          final list = all
              .where((lec) => languageMatches(langFilter, lec.language))
              .toList();
          return Column(
            children: [
              const SizedBox(height: 4),
              LanguageChips(
                selected: langFilter,
                onToggle: (lang) =>
                    ref.read(languageFilterProvider.notifier).toggle(lang),
                onSelectAll: () =>
                    ref.read(languageFilterProvider.notifier).selectAll(),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                  child: Text(l.freshContentSub,
                      style: TextStyle(
                          color: AppColors.mutedText, fontSize: 14)),
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.auto_awesome_outlined,
                        title: 'No lectures yet')
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: controller.refresh,
                        child: ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.only(top: 4, bottom: 12),
                          itemCount: list.length + 1,
                          itemBuilder: (context, i) {
                final index = i;
                if (index >= list.length) {
                  // Footer: a loader while more pages come in, else nothing.
                  return controller.hasMore
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold, strokeWidth: 2),
                          ),
                        )
                      : const SizedBox(height: 8);
                }
                final lecture = list[index];
                return LectureListTile(
                  lecture: lecture,
                  accent: index.isEven ? AppColors.gold : AppColors.olive,
                  onTap: () => openLecture(context, ref, lecture,
                      queue: list, index: index),
                );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
