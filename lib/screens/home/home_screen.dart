import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/content_providers.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/category_row.dart';
import 'widgets/continue_listening.dart';
import 'widgets/language_filter_bar.dart';
import 'widgets/sheikh_section.dart';

/// Home shell: app bar + scrollable body. Day 8 delivers the shell and the
/// featured banner; Day 9 adds sheikh-grouped sections below it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(currentUserDocProvider);
    final displayName = userDoc.asData?.value?.displayName;

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async {
            ref.invalidate(featuredLecturesProvider);
            await ref.read(latestLecturesProvider.notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(name: displayName)),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: LanguageFilterBar()),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: BannerCarousel()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              const SliverToBoxAdapter(child: ContinueListening()),
              const SliverToBoxAdapter(child: CategoryRow()),
              const _SheikhSectionsSliver(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({this.name});
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final greeting = (name == null || name!.isEmpty || name == 'Guest')
        ? 'Assalamu alaikum'
        : 'Assalamu alaikum,\n$name';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              greeting,
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search, color: AppColors.cream),
            // Search screen arrives Day 18.
            onPressed: () {},
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: AppColors.mutedText),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
    );
  }
}

/// Renders one [SheikhSection] per sheikh, alternating accent colors. Sections
/// self-hide when a sheikh has no lectures, so empty rows never show.
class _SheikhSectionsSliver extends ConsumerWidget {
  const _SheikhSectionsSliver();

  static const _accents = [AppColors.gold, AppColors.olive];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheikhs = ref.watch(sheikhsProvider);

    return sheikhs.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Couldn’t load sheikhs',
                style: TextStyle(color: AppColors.mutedText)),
          ),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No sheikhs yet',
                    style: TextStyle(color: AppColors.mutedText)),
              ),
            ),
          );
        }
        return SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => SheikhSection(
            sheikh: list[i],
            accent: _accents[i % _accents.length],
          ),
        );
      },
    );
  }
}

/// Reusable "Section title  ›  See all" header for the coming browse sections.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.cream,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all',
                  style: TextStyle(color: AppColors.gold)),
            ),
        ],
      ),
    );
  }
}
