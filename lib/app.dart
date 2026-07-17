import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'routes/root_router.dart';

class UlamaCircleApp extends ConsumerStatefulWidget {
  const UlamaCircleApp({super.key});

  @override
  ConsumerState<UlamaCircleApp> createState() => _UlamaCircleAppState();
}

class _UlamaCircleAppState extends ConsumerState<UlamaCircleApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Only matters while following the system; rebuild so the palette re-resolves.
    if (ref.read(themeChoiceProvider) == ThemeChoice.system && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final choice = ref.watch(themeChoiceProvider);
    final id = switch (choice) {
      ThemeChoice.dark => AppThemeId.dark,
      ThemeChoice.emerald => AppThemeId.emerald,
      // With the white light theme hidden, "system" maps a light OS to Emerald
      // and a dark OS to Dark.
      ThemeChoice.system =>
        PlatformDispatcher.instance.platformBrightness == Brightness.dark
            ? AppThemeId.dark
            : AppThemeId.emerald,
    };
    // Swap the structural palette before building the theme so both agree.
    AppColors.apply(id);

    return MaterialApp(
      // Screens read AppColors (a swapped global) directly rather than through
      // an InheritedWidget, so keying the app to the active theme forces a clean
      // re-read of every widget when the theme changes. Riverpod state (player,
      // providers) lives above this and is preserved.
      key: ValueKey(id),
      title: 'Ulama Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: const RootRouter(),
    );
  }
}
