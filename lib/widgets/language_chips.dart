import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../l10n/app_localizations.dart';

/// Reusable content-language filter chips: All · English · Yoruba · Hausa.
///
/// Multi-select: [selected] is a set of lowercase language codes; an **empty
/// set means "All"**. Tapping a language toggles it; tapping "All" clears the
/// set. Used on Home and the lecture list screens.
class LanguageChips extends StatelessWidget {
  const LanguageChips({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onSelectAll,
  });

  /// Currently active languages; empty = All.
  final Set<String> selected;

  /// Toggle a single language on/off.
  final ValueChanged<String> onToggle;

  /// Select "All" (clear the set).
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    // null sentinel = the "All" chip, then each supported language.
    final options = <String?>[null, ...AppConstants.supportedLanguages];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final value = options[i];
          final isSelected =
              value == null ? selected.isEmpty : selected.contains(value);
          final label = value == null
              ? L10n.of(context).filterAll
              : Formatters.titleCase(value);
          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0D2620) : AppColors.cream,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: AppColors.gold,
              backgroundColor: AppColors.surfaceDark,
              side: BorderSide(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.mutedText.withValues(alpha: 0.35),
              ),
              shape: const StadiumBorder(),
              onSelected: (_) =>
                  value == null ? onSelectAll() : onToggle(value),
            ),
          );
        },
      ),
    );
  }
}
