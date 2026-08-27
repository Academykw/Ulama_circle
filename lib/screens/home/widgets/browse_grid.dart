import 'package:flutter/material.dart';

import '../../../core/icons/px.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../playlist/playlists_screen.dart';
import '../../quran/quran_reciters_screen.dart';
import '../../ramadan/ramadan_screen.dart';
import '../../scholars/scholars_screen.dart';
import '../../trending/trending_screen.dart';
import '../home_screen.dart' show SectionHeader;

/// The Browse hub on Home — a grid of entry points into the catalog. This is
/// the navigation spine that replaces the old per-sheikh home rows, so Home
/// stays a fixed height no matter how many lectures exist.
///
/// Each item's destination is intentionally a placeholder for now; the user is
/// defining what each should open. Wiring one up later is a single line in
/// [_onTap].
class BrowseGrid extends StatelessWidget {
  const BrowseGrid({super.key});

  // Charts is intentionally omitted per the user's request.
  static const _items = <_BrowseItem>[
    _BrowseItem(BrowseDest.lecturers, 'Lecturers', Px.usersThree),
    _BrowseItem(BrowseDest.playlists, 'Playlists', Px.playlist),
    _BrowseItem(BrowseDest.ramadan, 'Ramadan', Px.moonStars),
    _BrowseItem(BrowseDest.quran, 'Quran', Px.bookOpen),
    _BrowseItem(BrowseDest.trending, 'Trending', Px.trendUp),
  ];

  void _onTap(BuildContext context, BrowseDest dest, String label) {
    switch (dest) {
      case BrowseDest.lecturers:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ScholarsScreen()),
        );
      case BrowseDest.quran:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuranRecitersScreen()),
        );
      case BrowseDest.playlists:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
        );
      case BrowseDest.trending:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TrendingScreen()),
        );
      case BrowseDest.ramadan:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RamadanScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: L10n.of(context).browse),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            children: [
              for (final item in _items)
                _BrowseCard(
                  item: item,
                  onTap: () => _onTap(context, item.dest, item.label),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum BrowseDest { lecturers, playlists, ramadan, quran, trending }

class _BrowseItem {
  const _BrowseItem(this.dest, this.label, this.icon);
  final BrowseDest dest;
  final String label;
  final PxData icon;
}

String _label(BuildContext context, BrowseDest dest) {
  final l = L10n.of(context);
  return switch (dest) {
    BrowseDest.lecturers => l.lecturers,
    BrowseDest.playlists => l.playlists,
    BrowseDest.ramadan => l.ramadan,
    BrowseDest.quran => l.quran,
    BrowseDest.trending => l.trending,
  };
}

class _BrowseCard extends StatelessWidget {
  const _BrowseCard({required this.item, required this.onTap});
  final _BrowseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.goldMid.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: PxIcon(item.icon, color: AppColors.gold, size: 21),
              ),
              const SizedBox(height: 10),
              Text(
                _label(context, item.dest),
                style: TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
