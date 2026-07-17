import 'package:flutter/material.dart';

/// The three themes the app ships with.
enum AppThemeId { light, dark, emerald }

/// The Ulama Circle palette. Brand accents (gold/olive) are identical across all
/// themes; the four structural roles (background, surface, primary text, muted
/// text) are *swapped* by [apply] so the whole app can switch palette without
/// every widget needing a BuildContext.
///
/// Screens keep referring to `AppColors.charcoal` / `.cream` / etc. by name —
/// those names resolve to whichever theme is active.
class AppColors {
  AppColors._();

  // --- Brand accents: identical in every theme ---
  static const Color gold = Color(0xFFD9A441);
  static const Color olive = Color(0xFF8B9A5B);
  static const Color surfaceLight = Color(0xFFFAF8F3);

  // --- Theme-varying roles (mutable; set by apply). Default dark. ---
  static Color charcoal = _dark[0]; // app background / scaffold
  static Color surfaceDark = _dark[1]; // cards, chips, elevated surfaces
  static Color cream = _dark[2]; // primary text / on-surface
  static Color mutedText = _dark[3]; // secondary text

  // Each palette is [background, surface, primaryText, mutedText].
  static const List<Color> _light = [
    Color(0xFFF5F4EF),
    Color(0xFFFFFFFF),
    Color(0xFF23241F),
    Color(0xFF6E6F66),
  ];
  static const List<Color> _dark = [
    Color(0xFF20211D),
    Color(0xFF2A2B25),
    Color(0xFFEDE9DD),
    Color(0xFF9C9887),
  ];
  static const List<Color> _emerald = [
    Color(0xFF0A3B32),
    Color(0xFF104A3F),
    Color(0xFFEDE9DD),
    Color(0xFF8FA9A0),
  ];

  static AppThemeId _id = AppThemeId.dark;
  static AppThemeId get id => _id;

  /// Swaps the structural roles to the given theme. Call before building the
  /// app's ThemeData so both stay in sync.
  static void apply(AppThemeId id) {
    _id = id;
    final p = switch (id) {
      AppThemeId.light => _light,
      AppThemeId.dark => _dark,
      AppThemeId.emerald => _emerald,
    };
    charcoal = p[0];
    surfaceDark = p[1];
    cream = p[2];
    mutedText = p[3];
  }
}

class AppTheme {
  AppTheme._();

  /// Builds a ThemeData from the *currently applied* [AppColors]. Call
  /// `AppColors.apply(...)` first.
  static ThemeData build() {
    // Derive Material brightness from the actual background luminance, so
    // Material widgets behave correctly for the deep-green Emerald theme too.
    final effective = ThemeData.estimateBrightnessForColor(AppColors.charcoal);
    final scheme = ColorScheme(
      brightness: effective,
      primary: AppColors.gold,
      onPrimary: const Color(0xFF20211D),
      secondary: AppColors.olive,
      onSecondary: const Color(0xFF20211D),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.cream,
      error: const Color(0xFFE05656),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: effective,
      scaffoldBackgroundColor: AppColors.charcoal,
      colorScheme: scheme,
      canvasColor: AppColors.charcoal,
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surfaceDark),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.charcoal,
        foregroundColor: AppColors.cream,
        elevation: 0,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
            fontWeight: FontWeight.w600, color: AppColors.cream),
        bodyMedium: TextStyle(color: AppColors.cream),
      ),
      iconTheme: IconThemeData(color: AppColors.cream),
    );
  }
}
