import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/filter_providers.dart';
import '../../../widgets/lecture_card.dart';
import '../../fresh/fresh_content_screen.dart';
import '../home_screen.dart' show SectionHeader;

/// "Fresh Content" — a single bounded horizontal row of the newest lectures.
/// Unlike the old per-sheikh sections, this is one fixed-height row, so the
/// catalog can grow without stretching Home. Respects the language filter.
class FreshContent extends ConsumerWidget {
  const FreshContent({super.key});

  static const double _rowHeight = 214;
  static const int _max = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestLecturesProvider);
    final langFilter = ref.watch(languageFilterProvider);

    return latest.when(
      loading: () => const SizedBox(
        height: _rowHeight,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        final lectures = all
            .where((l) => languageMatches(langFilter, l.language))
            .take(_max)
            .toList();
        if (lectures.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: L10n.of(context).freshContent,
              subtitle: L10n.of(context).freshContentSub,
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FreshContentScreen()),
              ),
            ),
            SizedBox(
              height: _rowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: lectures.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => LectureCard(
                  lecture: lectures[i],
                  accent: i.isEven ? AppColors.gold : AppColors.olive,
                  onTap: () => openLecture(context, ref, lectures[i],
                      queue: lectures, index: i),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
