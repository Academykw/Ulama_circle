import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

class UlamaCircleApp extends StatelessWidget {
  const UlamaCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ulama Circle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // Day 7 wires real routing (onboarding -> auth check -> home).
      // For now the splash screen is the entry point so the project runs.
      home: const SplashScreen(),
    );
  }
}
