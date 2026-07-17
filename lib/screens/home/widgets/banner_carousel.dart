import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../models/lecture_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/filter_providers.dart';

/// Rotating banner of featured lectures at the top of Home. Lectures have no
/// cover art, so each slide is a branded gradient card. Tapping a slide will
/// open the player (wired on Day 12).
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key, this.onTapLecture});

  /// Called when a banner is tapped. Left as a hook until the player exists.
  final void Function(LectureModel lecture)? onTapLecture;

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  int _current = 0;

  static const double _height = 200;

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(featuredLecturesProvider);
    final languageFilter = ref.watch(languageFilterProvider);

    return featured.when(
      loading: () => const _BannerSkeleton(height: _height),
      error: (e, _) => const _BannerMessage(
        height: _height,
        icon: Icons.cloud_off_outlined,
        text: 'Couldn’t load featured lectures',
      ),
      data: (all) {
        // Apply the active language filter client-side (featured is a small,
        // bounded set, so no extra query is needed).
        final lectures = languageFilter == null
            ? all
            : all.where((l) => l.language == languageFilter).toList();
        if (lectures.isEmpty) {
          return _BannerMessage(
            height: _height,
            icon: Icons.auto_awesome_outlined,
            text: languageFilter == null
                ? 'Featured lectures will appear here'
                : 'No featured lectures in ${Formatters.titleCase(languageFilter)}',
          );
        }
        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: lectures.length,
              itemBuilder: (context, index, _) => _BannerCard(
                lecture: lectures[index],
                accent: _accentFor(index),
                onTap: () => openLecture(context, ref, lectures[index],
                    queue: lectures, index: index),
              ),
              options: CarouselOptions(
                height: _height,
                viewportFraction: 0.88,
                enlargeCenterPage: true,
                autoPlay: lectures.length > 1,
                autoPlayInterval: const Duration(seconds: 5),
                onPageChanged: (i, _) => setState(() => _current = i),
              ),
            ),
            if (lectures.length > 1) ...[
              const SizedBox(height: 12),
              _Dots(count: lectures.length, active: _current),
            ],
          ],
        );
      },
    );
  }

  // Alternate the accent tint so consecutive slides feel distinct.
  Color _accentFor(int index) =>
      index.isEven ? AppColors.gold : AppColors.olive;
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.lecture,
    required this.accent,
    required this.onTap,
  });

  final LectureModel lecture;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.35),
              AppColors.surfaceDark,
              AppColors.charcoal,
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(text: 'Featured', color: accent),
                const SizedBox(width: 8),
                _Chip(
                  text: Formatters.titleCase(lecture.category),
                  color: AppColors.cream,
                  outlined: true,
                ),
                const SizedBox(width: 8),
                _Chip(
                  text: Formatters.titleCase(lecture.language),
                  color: AppColors.cream,
                  outlined: true,
                ),
              ],
            ),
            const Spacer(),
            Text(
              lecture.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.cream,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lecture.sheikhName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.schedule, size: 14, color: AppColors.mutedText),
                const SizedBox(width: 4),
                Text(
                  Formatters.duration(lecture.durationSeconds),
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  child: Icon(Icons.play_arrow,
                      color: AppColors.charcoal, size: 24),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, this.outlined = false});
  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: outlined ? color : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});
  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final selected = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: selected ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold
                : AppColors.mutedText.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
      ),
    );
  }
}

class _BannerMessage extends StatelessWidget {
  const _BannerMessage({
    required this.height,
    required this.icon,
    required this.text,
  });
  final double height;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.mutedText, size: 32),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: AppColors.mutedText)),
        ],
      ),
    );
  }
}
