import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_db_provider.dart';

/// The user's appearance choice — two brand themes. Persisted in Hive
/// (app_meta 'theme_mode'). Emerald is the default.
enum ThemeChoice { emerald, obsidian }

final themeChoiceProvider =
    NotifierProvider<ThemeChoiceNotifier, ThemeChoice>(ThemeChoiceNotifier.new);

class ThemeChoiceNotifier extends Notifier<ThemeChoice> {
  @override
  ThemeChoice build() => _from(ref.read(localDbServiceProvider).themeMode);

  void set(ThemeChoice choice) {
    state = choice;
    ref.read(localDbServiceProvider).setThemeMode(choice.name);
  }

  static ThemeChoice _from(String s) {
    // Old values (system/dark/light) collapse into the new two-theme set:
    // the neutral 'dark' becomes Obsidian, everything else Emerald.
    if (s == 'obsidian' || s == 'dark') return ThemeChoice.obsidian;
    return ThemeChoice.emerald;
  }
}
