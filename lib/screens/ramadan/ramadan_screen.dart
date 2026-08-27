import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/px.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/play_lecture.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reciter_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/reciter_providers.dart';
import '../../widgets/lecture_card.dart';
import '../../widgets/mini_player.dart';
import '../category/categories_screen.dart';
import '../home/home_screen.dart' show SectionHeader;
import '../quran/quran_reciters_screen.dart';
import '../quran/reciter_detail_screen.dart';
import '../quran/widgets/reciter_cover.dart';

/// The Ramadan collection — a themed hub for the blessed month: Quran &
/// Taraweeh reciters plus Tafsir & Seerah lectures, curated from existing
/// content. Opened from the Home "Ramadan" browse card.
class RamadanScreen extends ConsumerWidget {
  const RamadanScreen({super.key});

  static const double _reciterRow = 210;
  static const double _lectureRow = 214;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciters = ref.watch(recitersProvider);
    final lectures = ref.watch(ramadanLecturesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const PxIcon(Px.caretLeft, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(L10n.of(context).ramadan),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const _RamadanHero(),
          const SizedBox(height: 8),

          // Quran & Taraweeh — reciters.
          SectionHeader(
            title: L10n.of(context).quranTaraweeh,
            subtitle: L10n.of(context).quranTaraweehSub,
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const QuranRecitersScreen()),
            ),
          ),
          reciters.when(
            loading: () => const SizedBox(
              height: _reciterRow,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: _reciterRow,
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
                            ReciterDetailScreen(reciter: list[i]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Tafsir & reminders — lectures.
          SectionHeader(
            title: L10n.of(context).tafsirReminders,
            subtitle: L10n.of(context).tafsirRemindersSub,
            onSeeAll: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CategoriesScreen()),
            ),
          ),
          lectures.when(
            loading: () => const SizedBox(
              height: _lectureRow,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.gold, strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Ramadan lectures will appear here',
                      style: TextStyle(color: AppColors.mutedText)),
                );
              }
              return SizedBox(
                height: _lectureRow,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, i) => LectureCard(
                    lecture: list[i],
                    accent: i.isEven ? AppColors.gold : AppColors.olive,
                    onTap: () => openLecture(context, ref, list[i],
                        queue: list, index: i),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The themed banner at the top of the Ramadan screen.
class _RamadanHero extends StatelessWidget {
  const _RamadanHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A4C3F), Color(0xFF0D2620)],
          ),
          border: Border.all(color: AppColors.goldMid.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PxIcon(Px.moonStars, color: AppColors.gold, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    L10n.of(context).ramadanReflections,
                    style: AppTheme.display(size: 21, weight: FontWeight.w700)
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L10n.of(context).ramadanReflectionsSub,
                    style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
