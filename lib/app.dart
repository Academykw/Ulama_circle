import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/root_router.dart';

class UlamaCircleApp extends StatelessWidget {
  const UlamaCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulama Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Dark-first brand (charcoal + gold). All screens are designed for the
      // dark palette; a light theme / toggle is a later feature (Day 29). Until
      // then we pin dark so a device in light mode doesn't render cream-on-cream.
      themeMode: ThemeMode.dark,
      // RootRouter runs the full launch flow:
      // onboarding (first launch) -> auth check -> home.
      home: const RootRouter(),
    );
  }
}
