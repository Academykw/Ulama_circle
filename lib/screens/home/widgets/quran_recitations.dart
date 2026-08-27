import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/reciter_model.dart';
import '../../../providers/reciter_providers.dart';
import '../../quran/quran_reciters_screen.dart';
import '../../quran/reciter_detail_screen.dart';
import '../../quran/widgets/reciter_cover.dart';
import '../home_screen.dart' show SectionHeader;

/// "Quran Recitations" — a bounded horizontal row of reciters. See All opens the
/// full [QuranRecitersScreen]. Hides itself when there are no reciters yet.
class QuranRecitations extends ConsumerWidget {
  const QuranRecitations({super.key});

  static const double _rowHeight = 210;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersProvider);

    return reciters.when(
      loading: () => const SizedBox(
        height: _rowHeight + 60,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: L10n.of(context).quranRecitations,
              subtitle: L10n.of(context).quranRecitationsSub,
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranRecitersScreen()),
              ),
            ),
            SizedBox(
              height: _rowHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) => _ReciterTile(
                  reciter: list[i],
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ReciterDetailScreen(reciter: list[i])),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReciterTile extends StatelessWidget {
  const _ReciterTile({required this.reciter, required this.onTap});
  final ReciterModel reciter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReciterCover(coverUrl: reciter.coverUrl, size: 150, radius: 16),
            const SizedBox(height: 8),
            Text(
              reciter.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.cream,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${reciter.surahCount} Surahs',
              style: TextStyle(color: AppColors.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
