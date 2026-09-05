import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/sheikh_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/filter_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/language_chips.dart';
import '../sheikh_detail/sheikh_detail_screen.dart';

/// The full Scholars directory — opened from the Home "Lecturers" browse card.
/// A searchable, language-filterable grid of scholars. Tapping one opens their
/// lectures ([SheikhDetailScreen]). Matches the reference design in our own
/// charcoal/gold palette, and filters by language instead of state.
class ScholarsScreen extends ConsumerStatefulWidget {
  const ScholarsScreen({super.key});

  @override
  ConsumerState<ScholarsScreen> createState() => _ScholarsScreenState();
}

enum _Sort { featured, popular, name }

class _ScholarsScreenState extends ConsumerState<ScholarsScreen> {
  String _query = '';
  // Default to the admin-defined order (the "Sort order" field in the panel);
  // Popular / A–Z stay available via the toggle.
  _Sort _sort = _Sort.featured;

  List<SheikhModel> _apply(List<SheikhModel> all, Set<String> langFilter) {
    final q = _query.trim().toLowerCase();
    final filtered = all.where((s) {
      final matchesQuery = q.isEmpty || s.name.toLowerCase().contains(q);
      return matchesQuery && languageMatches(langFilter, s.language);
    }).toList();
    filtered.sort((a, b) {
      switch (_sort) {
        case _Sort.featured: // admin "Sort order", then name as a tiebreak
          final byOrder = a.order.compareTo(b.order);
          return byOrder != 0
              ? byOrder
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _Sort.popular:
          return b.totalViews.compareTo(a.totalViews);
        case _Sort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final sheikhs = ref.watch(sheikhsProvider);
    final langFilter = ref.watch(languageFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Scholars'),
        centerTitle: true,
      ),
      body: sheikhs.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (_, __) => const EmptyState(
            icon: Icons.error_outline, title: 'Couldn’t load scholars'),
        data: (all) {
          final list = _apply(all, langFilter);
          return Column(
            children: [
              _SearchField(
                onChanged: (v) => setState(() => _query = v),
              ),
              LanguageChips(
                selected: langFilter,
                onToggle: (lang) =>
                    ref.read(languageFilterProvider.notifier).toggle(lang),
                onSelectAll: () =>
                    ref.read(languageFilterProvider.notifier).selectAll(),
              ),
              _CountSortRow(
                count: list.length,
                sort: _sort,
                onToggleSort: () => setState(() => _sort =
                    _Sort.values[(_sort.index + 1) % _Sort.values.length]),
              ),
              Expanded(
                child: list.isEmpty
                    ? const EmptyState(
                        icon: Icons.person_search,
                        title: 'No scholars found',
                        subtitle: 'Try a different search or language')
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 20,
                          mainAxisExtent: 210,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, i) => _ScholarCard(
                          sheikh: list[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SheikhDetailScreen(sheikh: list[i]),
                            ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: AppColors.cream),
        decoration: InputDecoration(
          hintText: 'Search scholars',
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
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
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

class _CountSortRow extends StatelessWidget {
  const _CountSortRow({
    required this.count,
    required this.sort,
    required this.onToggleSort,
  });
  final int count;
  final _Sort sort;
  final VoidCallback onToggleSort;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            '$count scholar${count == 1 ? '' : 's'}',
            style: TextStyle(
                color: AppColors.cream,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onToggleSort,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    switch (sort) {
                      _Sort.featured => 'Featured',
                      _Sort.popular => 'Most Popular',
                      _Sort.name => 'A–Z',
                    },
                    style: TextStyle(
                        color: AppColors.cream,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScholarCard extends StatelessWidget {
  const _ScholarCard({required this.sheikh, required this.onTap});
  final SheikhModel sheikh;
  final VoidCallback onTap;

  String get _initials {
    final parts = sheikh.name
        .replaceAll(RegExp(r'(Dr\.?|Prof\.?|Sheikh|Shaykh|Ustadh|Mallam)',
            caseSensitive: false), '')
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
      onTap: onTap,
      child: Column(
        children: [
          // Avatar — photo when available, else a branded initials circle.
          Container(
            width: 88,
            height: 88,
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
                      // A failed load (no network/bad URL) just leaves the
                      // gradient behind it showing — no visual change, but
                      // silences the Flutter image-error report at the source
                      // instead of relying on it being caught downstream.
                      onError: (_, __) {},
                    ),
              border:
                  Border.all(color: AppColors.goldMid.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: sheikh.photoUrl.isEmpty
                ? Text(
                    _initials,
                    style: AppTheme.display(size: 26, weight: FontWeight.w700)
                        .copyWith(color: AppColors.gold),
                  )
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            sheikh.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.cream,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cream.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              Formatters.titleCase(sheikh.language),
              style: TextStyle(color: AppColors.cream, fontSize: 11),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.compactCount(sheikh.totalViews)} views',
            style: const TextStyle(
                color: AppColors.goldMid,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
