import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/category_model.dart';
import '../../providers/content_providers.dart';
import '../category_detail/category_detail_screen.dart';

/// Full grid of all categories. Reached from the "See all" on the Home category
/// row. Tapping a tile opens that category's paginated lecture list.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  // A small palette rotated across tiles so the grid isn't monotone.
  static const _accents = [
    AppColors.gold,
    AppColors.olive,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(title: const Text('Categories')),
      body: categories.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.gold)),
        error: (_, __) => const Center(
          child: Text('Couldn’t load categories',
              style: TextStyle(color: AppColors.mutedText)),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Text('No categories yet',
                  style: TextStyle(color: AppColors.mutedText)),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => CategoryTile(
              category: list[i],
              accent: _accents[i % _accents.length],
            ),
          );
        },
      ),
    );
  }
}

/// A single category card — used in the grid. Branded gradient with the name.
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.category, this.accent = AppColors.gold});

  final CategoryModel category;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: category)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.35), AppColors.surfaceDark],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.menu_book_outlined, color: accent, size: 24),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
