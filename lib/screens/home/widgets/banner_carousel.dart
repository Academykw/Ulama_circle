import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/play_lecture.dart';
import '../../../models/lecture_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/filter_providers.dart';
import '../../../widgets/gold_play_button.dart';

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
    final langFilter = ref.watch(languageFilterProvider);

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
        final lectures =
            all.where((l) => languageMatches(langFilter, l.language)).toList();
        if (lectures.isEmpty) {
          return _BannerMessage(
            height: _height,
            icon: Icons.auto_awesome_outlined,
            text: langFilter.isEmpty
                ? 'Featured lectures will appear here'
                : langFilter.length == 1
                    ? 'No featured lectures in ${Formatters.titleCase(langFilter.first)}'
                    : 'No featured lectures in your selected languages',
          );
        }
        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: lectures.length,
              itemBuilder: (context, index, _) => _BannerCard(
                lecture: lectures[index],
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

}

class _BannerCard extends ConsumerWidget {
  const _BannerCard({required this.lecture, required this.onTap});

  final LectureModel lecture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prefer the lecture's own artwork, then the lecturer's photo, then a plain
    // emerald cover.
    final url = lecture.artworkUrl.isNotEmpty
        ? lecture.artworkUrl
        : (ref.watch(sheikhByIdProvider(lecture.sheikhId))?.photoUrl ?? '');
    final hasArt = url.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.goldMid.withValues(alpha: 0.20)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background: artwork / lecturer photo if present, else emerald.
              if (hasArt)
                Image.network(url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _EmeraldCover())
              else
                const _EmeraldCover(),
              // Dark bottom-up scrim so the text always reads.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: [0.10, 0.55, 1.0],
                    colors: [
                      Color(0xF0071410),
                      Color(0x80071410),
                      Color(0x26071410),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _FeaturedPill(),
                        const SizedBox(width: 8),
                        _Chip(text: Formatters.titleCase(lecture.category)),
                        const SizedBox(width: 8),
                        _Chip(text: Formatters.titleCase(lecture.language)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      lecture.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(size: 21, weight: FontWeight.w700)
                          .copyWith(height: 1.2, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${lecture.sheikhName}  ·  ${Formatters.duration(lecture.durationSeconds)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFFCFD9D4), fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const GoldPlayButton(size: 38),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plain emerald cover used when a featured lecture has no artwork image.
class _EmeraldCover extends StatelessWidget {
  const _EmeraldCover();
  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A4C3F), Color(0xFF0D2620)],
          ),
        ),
      );
}

/// Solid-gold "FEATURED" pill with dark text.
class _FeaturedPill extends StatelessWidget {
  const _FeaturedPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(100),
        ),
        child: const Text('FEATURED',
            style: TextStyle(
                color: Color(0xFF0D2620),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );
}

/// Translucent white outlined pill (category / language) over the cover.
class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFF5F1E6),
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
