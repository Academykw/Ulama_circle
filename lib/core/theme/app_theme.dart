import 'package:flutter/material.dart';

/// Colors pulled from the "Charcoal and olive gold" direction we settled on
/// for the Ulama Circle brand. Change these two swatches and the whole app
/// re-themes — don't hardcode colors in individual screens.
class AppColors {
  AppColors._();

  static const Color charcoal = Color(0xFF20211D);
  static const Color gold = Color(0xFFD9A441);
  static const Color olive = Color(0xFF8B9A5B);
  static const Color cream = Color(0xFFEDE9DD);
  static const Color mutedText = Color(0xFF9C9887);

  static const Color surfaceLight = Color(0xFFFAF8F3);
  static const Color surfaceDark = Color(0xFF2A2B25);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.surfaceLight,
        colorScheme: const ColorScheme.light(
          primary: AppColors.charcoal,
          secondary: AppColors.gold,
          tertiary: AppColors.olive,
          surface: AppColors.surfaceLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surfaceLight,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.charcoal),
          bodyMedium: TextStyle(color: AppColors.charcoal),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.charcoal,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.olive,
          tertiary: AppColors.gold,
          surface: AppColors.surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.charcoal,
          foregroundColor: AppColors.cream,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600, color: AppColors.cream),
          bodyMedium: TextStyle(color: AppColors.cream),
        ),
      );
}
