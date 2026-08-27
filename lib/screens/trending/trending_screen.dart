import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/play_lecture.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lecture_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/filter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gold_play_button.dart';
import '../../widgets/language_chips.dart';
import '../../widgets/lecture_list_tile.dart';
import '../../widgets/mini_player.dart';
import '../../widgets/network_loading.dart';

/// Full "Trending" screen — opened from the Home "Trending" browse card and the
/// "Trending Now" See All. Search + collapsible Filters & Sorting over the
/// most-played lectures.
class TrendingScreen extends ConsumerStatefulWidget {
  const TrendingScreen({super.key});

  @override
  ConsumerState<TrendingScreen> createState() => _TrendingScreenState();
}

enum _Sort { popular, newest, longest }

class _TrendingScreenState extends ConsumerState<TrendingScreen> {
  String _query = '';
  _Sort _sort = _Sort.popular;
  bool _filtersOpen = false;

  int _activeCount(Set<String> langFilter) =>
      (langFilter.isEmpty ? 0 : 1) + (_sort == _Sort.popular ? 0 : 1);

  List<LectureModel> _apply(List<LectureModel> all, Set<String> langFilter) {
    final q = _query.trim().toLowerCase();
    final list = all.where((l) {
      final matchesQuery = q.isEmpty ||
          l.title.toLowerCase().contains(q) ||
          l.sheikhName.toLowerCase().contains(q);
      return matchesQuery && languageMatches(langFilter, l.language);
    }).toList();
    switch (_sort) {
      case _Sort.popular:
        list.sort((a, b) => b.playCount.compareTo(a.playCount));
      case _Sort.newest:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      case _Sort.longest:
        list.sort((a, b) => b.durationSeconds.compareTo(a.durationSeconds));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final trending = ref.watch(allTrendingLecturesProvider);
    final langFilter = ref.watch(languageFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(L10n.of(context).trending),
      ),
      body: trending.when(
        loading: () => NetworkLoading(
            onRetry: () => ref.invalidate(allTrendingLecturesProvider)),
        error: (_, __) => NetworkLoading(
            isError: true,
            onRetry: () => ref.invalidate(allTrendingLecturesProvider)),
        data: (all) {
          final list = _apply(all, langFilter);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              LanguageChips(
                selected: langFilter,
                onToggle: (lang) =>
                    ref.read(languageFilterProvider.notifier).toggle(lang),
                onSelectAll: () =>
                    ref.read(languageFilterProvider.notifier).selectAll(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Most popular and engaging content loved by our community',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(
                      text:
                          '${all.length} lecture${all.length == 1 ? '' : 's'}'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: AppColors.cream),
                  decoration: InputDecoration(
                    hintText: 'Search in trending',
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
              ),
              _FiltersHeader(
                open: _filtersOpen,
                activeCount: _activeCount(langFilter),
                onToggle: () => setState(() => _filtersOpen = !_filtersOpen),
              ),
              if (_filtersOpen)
                _FiltersPanel(
                  selected: langFilter,
                  sort: _sort,
                  onToggleLanguage: (lang) =>
                      ref.read(languageFilterProvider.notifier).toggle(lang),
                  onSelectAllLanguages: () =>
                      ref.read(languageFilterProvider.notifier).selectAll(),
                  onSort: (v) => setState(() => _sort = v),
                ),
              Divider(color: AppColors.surfaceDark, height: 1),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off, title: 'Nothing matches')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, i) => LectureListTile(
                          lecture: list[i],
                          accent:
                              i.isEven ? AppColors.gold : AppColors.olive,
                          onTap: () => openLecture(context, ref, list[i],
                              queue: list, index: i),
                          trailing: _PlayDot(
                            onTap: () => openLecture(context, ref, list[i],
                                queue: list, index: i),
                          ),
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

class _Pill extends StatelessWidget {
  const _Pill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: AppColors.cream,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _FiltersHeader extends StatelessWidget {
  const _FiltersHeader({
    required this.open,
    required this.activeCount,
    required this.onToggle,
  });
  final bool open;
  final int activeCount;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Text('Filters & Sorting',
                style: TextStyle(
                    color: AppColors.cream,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: activeCount > 0
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$activeCount active',
                  style: TextStyle(
                      color:
                          activeCount > 0 ? AppColors.gold : AppColors.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            Icon(open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.selected,
    required this.sort,
    required this.onToggleLanguage,
    required this.onSelectAllLanguages,
    required this.onSort,
  });
  final Set<String> selected; // empty = All
  final _Sort sort;
  final ValueChanged<String> onToggleLanguage;
  final VoidCallback onSelectAllLanguages;
  final ValueChanged<_Sort> onSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GroupLabel('Language'),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: selected.isEmpty,
                onTap: onSelectAllLanguages,
              ),
              for (final v in AppConstants.supportedLanguages)
                _FilterChip(
                  label: Formatters.titleCase(v),
                  selected: selected.contains(v),
                  onTap: () => onToggleLanguage(v),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const _GroupLabel('Sort by'),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'Most popular',
                selected: sort == _Sort.popular,
                onTap: () => onSort(_Sort.popular),
              ),
              _FilterChip(
                label: 'Newest',
                selected: sort == _Sort.newest,
                onTap: () => onSort(_Sort.newest),
              ),
              _FilterChip(
                label: 'Longest',
                selected: sort == _Sort.longest,
                onTap: () => onSort(_Sort.longest),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              color: AppColors.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selected ? AppColors.charcoal : AppColors.cream,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      selectedColor: AppColors.gold,
      backgroundColor: AppColors.surfaceDark,
      side: BorderSide(
        color: selected
            ? AppColors.gold
            : AppColors.mutedText.withValues(alpha: 0.3),
      ),
      shape: const StadiumBorder(),
      onSelected: (_) => onTap(),
    );
  }
}

class _PlayDot extends StatelessWidget {
  const _PlayDot({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GoldPlayButton(size: 42, onTap: onTap);
}
