import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../models/sheikh_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/filter_providers.dart';
import '../../../widgets/lecture_card.dart';
import '../../sheikh_detail/sheikh_detail_screen.dart';
import '../home_screen.dart' show SectionHeader;

/// One home section: a sheikh's name + a horizontal row of their latest
/// lectures, with "See all" into the full paginated sheikh screen. Renders
/// nothing when the sheikh has no lectures (keeps Home tidy).
class SheikhSection extends ConsumerWidget {
  const SheikhSection({super.key, required this.sheikh, this.accent = AppColors.gold});

  final SheikhModel sheikh;
  final Color accent;

  static const double _rowHeight = 214;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = ref.watch(sheikhPreviewLecturesProvider(sheikh.id));
    final languageFilter = ref.watch(languageFilterProvider);

    return preview.when(
      // Keep the layout stable while loading; hide entirely on error/empty.
      loading: () => _Frame(
        sheikh: sheikh,
        child: const SizedBox(
          height: _rowHeight,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
          ),
        ),
        onSeeAll: () => _openDetail(context),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (all) {
        // Filter by the active language; hide the whole section if this sheikh
        // has nothing in the selected language.
        final lectures = languageFilter == null
            ? all
            : all.where((l) => l.language == languageFilter).toList();
        if (lectures.isEmpty) return const SizedBox.shrink();
        return _Frame(
          sheikh: sheikh,
          onSeeAll: () => _openDetail(context),
          child: SizedBox(
            height: _rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: lectures.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) => LectureCard(
                lecture: lectures[i],
                accent: accent,
                onTap: () =>
                    openLecture(context, ref, lectures[i], queue: lectures, index: i),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SheikhDetailScreen(sheikh: sheikh)),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.sheikh, required this.child, this.onSeeAll});
  final SheikhModel sheikh;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: sheikh.name, onSeeAll: onSeeAll),
        child,
        const SizedBox(height: 20),
      ],
    );
  }
}
