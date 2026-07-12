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
      themeMode: ThemeMode.system,
      // RootRouter runs the full launch flow:
      // onboarding (first launch) -> auth check -> home.
      home: const RootRouter(),
    );
  }
}
