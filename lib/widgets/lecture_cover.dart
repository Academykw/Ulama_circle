import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/lecture_model.dart';
import '../providers/content_providers.dart';

/// The artwork for a lecture card/tile. Resolves an image in this order:
///   1. the lecture's own [LectureModel.artworkUrl] (e.g. a reciter cover),
///   2. the lecturer's photo (`sheikhByIdProvider(...).photoUrl`),
///   3. a branded gradient block with the scholar's name (the old placeholder).
///
/// Fills its parent, so wrap it in an `AspectRatio`/`SizedBox` for sizing.
/// [overlay] is stacked on top (play button, category, rank badge, …).
class LectureCover extends ConsumerWidget {
  const LectureCover({
    super.key,
    required this.lecture,
    this.accent = AppColors.gold,
    this.radius = 12,
    this.brandedTextSize = 12,
    this.showBrandedName = true,
    this.overlay,
  });

  final LectureModel lecture;
  final Color accent;
  final double radius;
  final double brandedTextSize;

  /// When there's no image, whether the fallback shows the scholar's name.
  final bool showBrandedName;

  /// Optional widget stacked over the cover (e.g. a Positioned play button).
  final Widget? overlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = lecture.artworkUrl.isNotEmpty
        ? lecture.artworkUrl
        : (ref.watch(sheikhByIdProvider(lecture.sheikhId))?.photoUrl ?? '');
    final hasImage = url.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _branded(),
              errorWidget: (_, __, ___) => _branded(),
            )
          else
            _branded(),
          // Scrim so anything overlaid on a photo stays legible.
          if (hasImage)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }

  Widget _branded() {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.40), AppColors.surfaceDark],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: showBrandedName
          ? Text(
              lecture.sheikhName,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.cream,
                fontSize: brandedTextSize,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
    );
  }
}
