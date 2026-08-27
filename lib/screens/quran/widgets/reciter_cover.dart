import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Reciter artwork: the network cover when set, else a branded gradient block
/// with a Quran icon. Shared by the reciters list, detail header, and Home row.
class ReciterCover extends StatelessWidget {
  const ReciterCover({
    super.key,
    required this.coverUrl,
    required this.size,
    this.radius = 14,
  });

  final String coverUrl;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.olive, AppColors.surfaceDark],
        ),
        image: coverUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(coverUrl), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: coverUrl.isEmpty
          ? Icon(Icons.menu_book_rounded,
              color: AppColors.cream.withValues(alpha: 0.85), size: size * 0.34)
          : null,
    );
  }
}
