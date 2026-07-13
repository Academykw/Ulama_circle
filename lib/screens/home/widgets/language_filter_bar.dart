import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/filter_providers.dart';

/// Horizontal filter chips at the top of Home: All / Yoruba / Hausa / English.
/// Drives [languageFilterProvider]; the banner and sheikh sections react to it.
class LanguageFilterBar extends ConsumerWidget {
  const LanguageFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageFilterProvider);

    // null (All) first, then each supported language.
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
          final isSelected = value == selected;
          final label = value == null ? 'All' : Formatters.titleCase(value);
          return Center(
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.charcoal : AppColors.cream,
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
                  ref.read(languageFilterProvider.notifier).select(value),
            ),
          );
        },
      ),
    );
  }
}
