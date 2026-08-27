import 'package:flutter/material.dart';

import '../core/icons/px.dart';
import '../core/theme/app_theme.dart';

/// The signature circular play button: gold gradient fill with a dark Phosphor
/// play (or pause) glyph, and a soft shadow. Used on the featured banner,
/// Continue Listening, carousels, trending rows, etc.
class GoldPlayButton extends StatelessWidget {
  const GoldPlayButton({
    super.key,
    this.size = 44,
    this.playing = false,
    this.onTap,
  });

  final double size;
  final bool playing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: PxIcon(
        playing ? Px.pauseFill : Px.playFill,
        color: const Color(0xFF0D2620),
        size: size * 0.42,
      ),
    );
    if (onTap == null) return button;
    return GestureDetector(onTap: onTap, child: button);
  }
}
