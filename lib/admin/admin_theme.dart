import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A clean, light dashboard theme for the admin panel — distinct from the
/// mobile app's charcoal look, but keeping the Ulama Circle gold accent. The
/// sidebar uses the brand charcoal for contrast.
class AdminTheme {
  AdminTheme._();

  static const Color bg = Color(0xFFF1F2EE);
  static const Color surface = Colors.white;
  // The admin panel is always a light dashboard with a fixed dark sidebar, so
  // these stay literals (independent of the app's swappable palette).
  static const Color sidebar = Color(0xFF1C1D19);
  static const Color sidebarHover = Color(0x14FFFFFF); // white 8%
  static const Color ink = Color(0xFF23241F);
  static const Color subtle = Color(0xFF6B6C64);
  static const Color faint = Color(0xFF9A9B92);
  static const Color border = Color(0xFFE6E7E2);
  static const Color gold = AppColors.gold;
  static const Color olive = AppColors.olive;

  /// Soft elevation used on every card/table/panel for a professional depth.
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF23241F).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// The standard surface card — white, rounded, subtle border + shadow.
  static BoxDecoration get card => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: cardShadow,
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(
          primary: gold,
          secondary: olive,
          surface: surface,
          onPrimary: sidebar,
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: ink),
          titleMedium:
              TextStyle(color: ink, fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: gold, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: sidebar,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      );
}
