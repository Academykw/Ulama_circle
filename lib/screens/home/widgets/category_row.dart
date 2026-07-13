import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/content_providers.dart';
import '../../category/categories_screen.dart';
import '../../category_detail/category_detail_screen.dart';
import '../home_screen.dart' show SectionHeader;

/// Horizontal row of category chips on Home — the entry point into category
/// browsing. Tapping a chip opens that category's lectures; "See all" opens the
/// full categories grid.
class CategoryRow extends ConsumerWidget {
  const CategoryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return categories.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Browse by category',
              onSeeAll: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final category = list[i];
                  return Center(
                    child: ActionChip(
                      label: Text(category.name),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      labelStyle: const TextStyle(
                          color: AppColors.cream, fontWeight: FontWeight.w600),
                      backgroundColor: AppColors.surfaceDark,
                      side: BorderSide(
                          color: AppColors.gold.withValues(alpha: 0.4)),
                      shape: const StadiumBorder(),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryDetailScreen(category: category),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
