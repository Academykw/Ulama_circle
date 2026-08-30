import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/lecture_model.dart';
import 'gold_play_button.dart';
import 'lecture_cover.dart';

/// Compact fixed-width lecture card for horizontal rows (home sheikh sections).
/// Lectures have no artwork, so the "cover" is a branded gradient block with the
/// category name. Tapping opens the player (wired Day 12) via [onTap].
class LectureCard extends StatelessWidget {
  const LectureCard({
    super.key,
    required this.lecture,
    this.onTap,
    this.accent = AppColors.gold,
  });

  final LectureModel lecture;
  final VoidCallback? onTap;
  final Color accent;

  static const double width = 168;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover: the lecturer's photo (falls back to a branded name block),
            // with the category label and a play button laid over it.
            AspectRatio(
              aspectRatio: 1.35,
              child: LectureCover(
                lecture: lecture,
                accent: accent,
                radius: 14,
                brandedTextSize: 13,
                overlay: Stack(
                  children: [
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Text(
                        Formatters.titleCase(lecture.category),
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Positioned(
                      right: 10,
                      bottom: 10,
                      child: GoldPlayButton(size: 34),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lecture.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.cream,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.titleCase(lecture.language)}  •  ${Formatters.duration(lecture.durationSeconds)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
