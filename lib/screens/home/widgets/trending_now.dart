import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/lecture_model.dart';
import '../../../providers/content_providers.dart';
import '../../../widgets/gold_play_button.dart';
import '../../../widgets/lecture_cover.dart';
import '../../trending/trending_screen.dart';
import '../home_screen.dart' show SectionHeader;

/// "Trending Now" — a bounded horizontal row of the most-played lectures. Backed
/// by `playCount` (see [trendingLecturesProvider]); one fixed-height row so it
/// scales with the catalog.
class TrendingNow extends ConsumerWidget {
  const TrendingNow({super.key});

  static const double _rowHeight = 96;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingLecturesProvider);

    return trending.when(
      loading: () => const SizedBox(
        height: _rowHeight + 60,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (lectures) {
        if (lectures.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: L10n.of(context).trendingNow,
              subtitle: L10n.of(context).trendingNowSub,
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TrendingScreen()),
              ),
            ),
            SizedBox(
              height: _rowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: lectures.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _TrendingCard(
                  lecture: lectures[i],
                  rank: i + 1,
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

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({
    required this.lecture,
    required this.rank,
    required this.accent,
    required this.onTap,
  });

  final LectureModel lecture;
  final int rank;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.mutedText.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            // Lecturer photo (falls back to a branded block) with a rank badge.
            SizedBox(
              width: 64,
              height: 64,
              child: LectureCover(
                lecture: lecture,
                accent: accent,
                radius: 12,
                showBrandedName: false,
                overlay: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$rank',
                      style: AppTheme.display(size: 13, weight: FontWeight.w700)
                          .copyWith(color: AppColors.goldMid),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lecture.sheikhName}  ·  ${Formatters.compactCount(lecture.playCount)} plays',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const GoldPlayButton(size: 40),
          ],
        ),
      ),
    );
  }
}
