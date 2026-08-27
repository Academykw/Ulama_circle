import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/filter_providers.dart';
import '../../../widgets/language_chips.dart';

/// Horizontal content-language filter at the top of Home: All / English /
/// Yoruba / Hausa. Multi-select — drives [languageFilterProvider]; the banner
/// and sheikh sections react to it.
class LanguageFilterBar extends ConsumerWidget {
  const LanguageFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageFilterProvider);
    return LanguageChips(
      selected: selected,
      onToggle: (lang) =>
          ref.read(languageFilterProvider.notifier).toggle(lang),
      onSelectAll: () => ref.read(languageFilterProvider.notifier).selectAll(),
    );
  }
}
