import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/lecture_model.dart';

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
            // Cover block
            AspectRatio(
              aspectRatio: 1.35,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.35),
                      AppColors.surfaceDark,
                    ],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.30)),
                ),
                child: Stack(
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
                    // Sheikh name centered as the "cover" text, matching the
                    // list-tile block. Padded so it never collides with the
                    // category label or the play button.
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 32, 12, 32),
                        child: Center(
                          child: Text(
                            lecture.sheikhName,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.cream,
                              fontSize: 13,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(color: accent, shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow,
                            color: AppColors.charcoal, size: 20),
                      ),
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
              style: const TextStyle(
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
              style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
