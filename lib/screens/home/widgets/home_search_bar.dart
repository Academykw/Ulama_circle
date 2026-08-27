import 'package:flutter/material.dart';

import '../../../core/icons/px.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../search/search_screen.dart';

/// Tappable search field on Home. It doesn't accept input inline — tapping opens
/// the full [SearchScreen] where the query, debounce, and results live.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        ),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              PxIcon(Px.magnifyingGlass,
                  color: AppColors.mutedText, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L10n.of(context).searchHint,
                  style: TextStyle(color: AppColors.faintText, fontSize: 15),
                ),
              ),
              PxIcon(Px.microphone, color: AppColors.goldMid, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
