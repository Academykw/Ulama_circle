import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/lecture_model.dart';

/// Full-width lecture row for vertical lists (sheikh detail, category, search,
/// favorites, playlists). Shows a branded leading block, title, sheikh, and
/// meta. [trailing] lets callers slot a download/more button; [onTap] opens the
/// player (Day 12).
class LectureListTile extends StatelessWidget {
  const LectureListTile({
    super.key,
    required this.lecture,
    this.onTap,
    this.trailing,
    this.showSheikh = true,
    this.accent = AppColors.gold,
  });

  final LectureModel lecture;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showSheikh;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            // Cover stand-in: the sheikh's name set inside the gradient block,
            // small enough to wrap to a couple of lines. Keeps the same accent
            // colors we used as the empty placeholder.
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.40),
                    AppColors.surfaceDark,
                  ],
                ),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Text(
                lecture.sheikhName,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 9.5,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lecture.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (showSheikh) ...[
                        Flexible(
                          child: Text(
                            lecture.sheikhName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppColors.mutedText, fontSize: 12),
                          ),
                        ),
                        Text('  •  ',
                            style: TextStyle(
                                color: AppColors.mutedText, fontSize: 12)),
                      ],
                      Text(
                        '${Formatters.titleCase(lecture.language)}  •  ${Formatters.duration(lecture.durationSeconds)}',
                        style: TextStyle(
                            color: AppColors.mutedText, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
