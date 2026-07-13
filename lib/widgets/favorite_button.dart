import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../providers/favorites_provider.dart';

/// Heart toggle for a lecture. Filled gold when favorited. Works for guests too
/// (they have a user doc). [size] lets the player use a bigger icon than lists.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.lectureId, this.size = 22});

  final String lectureId;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(isFavoriteProvider(lectureId));
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: isFav ? 'Remove from Liked' : 'Add to Liked',
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? AppColors.gold : AppColors.mutedText,
        size: size,
      ),
      onPressed: () => ref.read(favoritesControllerProvider).toggle(lectureId),
    );
  }
}
