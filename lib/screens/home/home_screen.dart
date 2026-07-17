import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/content_providers.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/browse_grid.dart';
import 'widgets/continue_listening.dart';
import 'widgets/fresh_content.dart';
import 'widgets/home_header.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/language_filter_bar.dart';
import 'widgets/quran_recitations.dart';
import 'widgets/trending_now.dart';

/// Home: a fixed-height navigation hub (greeting, search, browse grid) plus a
/// couple of bounded content rows. Deliberately does NOT grow one row per
/// sheikh — the Browse grid is the entry point into the full catalog, so Home
/// stays the same length no matter how many lectures exist.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async {
            ref.invalidate(featuredLecturesProvider);
            await ref.read(latestLecturesProvider.notifier).refresh();
          },
          child: const CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: HomeHeader()),
              SliverToBoxAdapter(child: HomeSearchBar()),
              SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(child: LanguageFilterBar()),
              SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverToBoxAdapter(child: BannerCarousel()),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: ContinueListening()),
              SliverToBoxAdapter(child: BrowseGrid()),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: FreshContent()),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: QuranRecitations()),
              SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(child: TrendingNow()),
              SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable "Section title  ›  See all" header used across Home sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.cream,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                        color: AppColors.mutedText, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('See All',
                      style: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
