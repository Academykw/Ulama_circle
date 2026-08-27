import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/fallback_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/root_router.dart';

class UlamaCircleApp extends ConsumerWidget {
  const UlamaCircleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choice = ref.watch(themeChoiceProvider);
    final id = choice == ThemeChoice.obsidian
        ? AppThemeId.obsidian
        : AppThemeId.emerald;
    // Swap the structural palette before building the theme so both agree.
    AppColors.apply(id);

    final locale = ref.watch(localeProvider);

    return MaterialApp(
      // Screens read AppColors (a swapped global) directly rather than through
      // an InheritedWidget, so keying the app to the active theme forces a clean
      // re-read of every widget when the theme changes. Riverpod state (player,
      // providers) lives above this and is preserved.
      key: ValueKey(id),
      title: 'Ulama Circle',
      debugShowCheckedModeBanner: false,
      locale: locale, // null = follow device
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: [
        ...L10n.localizationsDelegates,
        // Hausa (and any future non-Flutter locale) falls back to English for
        // Material/Cupertino built-ins so the app doesn't crash.
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
      ],
      theme: AppTheme.build(),
      // The fixed radial background sits behind every screen; scaffolds are
      // transparent so it shows through. The AnnotatedRegion tints the system
      // status + navigation bars to match the active theme (instead of a stray
      // grey), and re-applies when the theme is swapped.
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark, // iOS
          // Transparent + edge-to-edge: the app's radial backdrop / bottom nav
          // paints behind the buttons, so it always matches the theme.
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: DecoratedBox(
          decoration: AppTheme.backdrop,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: const RootRouter(),
    );
  }
}
