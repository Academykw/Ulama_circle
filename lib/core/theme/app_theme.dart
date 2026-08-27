import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The two themes the app ships with: deep emerald (default) and neutral
/// near-black obsidian. Only the base surface differs — all gold/card/text
/// styling is shared.
enum AppThemeId { emerald, obsidian }

/// The Ulama Circle palette. Brand accents (gold/olive) are identical across all
/// themes; the four structural roles (background, surface, primary text, muted
/// text) are *swapped* by [apply] so the whole app can switch palette without
/// every widget needing a BuildContext.
///
/// Screens keep referring to `AppColors.charcoal` / `.cream` / etc. by name —
/// those names resolve to whichever theme is active.
class AppColors {
  AppColors._();

  // --- Brand accents: identical in every theme (antique gold) ---
  static const Color gold = Color(0xFFE8C877); // bright brand gold
  static const Color goldMid = Color(0xFFC9A24C); // solid mid-gold (links, ranks)
  static const Color goldDeep = Color(0xFF8B6B28); // gradient end / deep gold
  static const Color olive = Color(0xFF8B9A5B);
  static const Color surfaceLight = Color(0xFFFAF8F3);

  /// The signature gold gradient (play buttons, active chips, avatars).
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDeep],
  );

  // --- Theme-varying roles (mutable; set by apply). Default emerald. ---
  static Color charcoal = _emerald[0]; // app background / scaffold
  static Color surfaceDark = _emerald[1]; // cards, chips, elevated surfaces
  static Color cream = _emerald[2]; // primary text / on-surface
  static Color mutedText = _emerald[3]; // secondary text
  static Color navBg = _emeraldNav; // bottom nav / notification surface base

  // Tertiary/muted text (timestamps, placeholders, inactive) — same both themes.
  static const Color faintText = Color(0xFF6E8078);
  // Standard translucent-gold card border.
  static Color get cardBorder => const Color(0xFFC9A24C).withValues(alpha: 0.16);

  // Each palette is [background, surface, primaryText, mutedText].
  static const List<Color> _emerald = [
    Color(0xFF0D2620),
    Color(0xFF143A30),
    Color(0xFFF5F1E6),
    Color(0xFF93A89E),
  ];
  static const List<Color> _obsidian = [
    Color(0xFF131316),
    Color(0xFF1E1E20),
    Color(0xFFF5F1E6),
    Color(0xFF93A89E),
  ];
  static const Color _emeraldNav = Color(0xFF0A1F19);
  static const Color _obsidianNav = Color(0xFF0C0C0E);

  static AppThemeId _id = AppThemeId.emerald;
  static AppThemeId get id => _id;

  /// Swaps the structural roles to the given theme. Call before building the
  /// app's ThemeData so both stay in sync.
  static void apply(AppThemeId id) {
    _id = id;
    final p = id == AppThemeId.obsidian ? _obsidian : _emerald;
    charcoal = p[0];
    surfaceDark = p[1];
    cream = p[2];
    mutedText = p[3];
    navBg = id == AppThemeId.obsidian ? _obsidianNav : _emeraldNav;
  }
}

class AppTheme {
  AppTheme._();

  /// Serif display face (screen titles, section headers).
  static String get displayFont => GoogleFonts.petrona().fontFamily!;

  /// A Petrona title style, used for headers across the app.
  static TextStyle display(
          {double size = 20, FontWeight weight = FontWeight.w700, Color? color}) =>
      GoogleFonts.petrona(
          fontSize: size, fontWeight: weight, color: color ?? AppColors.cream);

  /// The radial background behind every screen (fixed, matches the redesign):
  /// `radial-gradient(120% 90% at 50% -10%, …)`.
  static BoxDecoration get backdrop => BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -1.15),
          radius: 1.35,
          colors: AppColors.id == AppThemeId.obsidian
              ? const [Color(0xFF232326), Color(0xFF131316), Color(0xFF050506)]
              : const [Color(0xFF163C30), Color(0xFF0D2620), Color(0xFF071A15)],
          stops: const [0.0, 0.45, 1.0],
        ),
      );

  /// The Now Playing overlay gradient (top-lit, per theme).
  static BoxDecoration get nowPlayingBackdrop => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6],
          colors: AppColors.id == AppThemeId.obsidian
              ? const [Color(0xFF232326), Color(0xFF0C0C0E)]
              : const [Color(0xFF163C30), Color(0xFF0A1F19)],
        ),
      );

  /// Builds a ThemeData from the *currently applied* [AppColors]. Call
  /// `AppColors.apply(...)` first.
  static ThemeData build() {
    // Derive Material brightness from the actual background luminance, so
    // Material widgets behave correctly for the deep-green Emerald theme too.
    final effective = ThemeData.estimateBrightnessForColor(AppColors.charcoal);
    final scheme = ColorScheme(
      brightness: effective,
      primary: AppColors.gold,
      onPrimary: const Color(0xFF0D2620),
      secondary: AppColors.goldMid,
      onSecondary: const Color(0xFF0D2620),
      surface: AppColors.surfaceDark,
      onSurface: AppColors.cream,
      error: const Color(0xFFE05656),
      onError: Colors.white,
    );

    final base = ThemeData(brightness: effective);
    return ThemeData(
      useMaterial3: true,
      brightness: effective,
      fontFamily: GoogleFonts.manrope().fontFamily,
      // Transparent so the radial [backdrop] (wrapped in MaterialApp.builder)
      // shows behind every screen.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: scheme,
      canvasColor: AppColors.charcoal,
      // Route transitions must composite over TRANSPARENT, not a flat surface
      // color — otherwise the incoming page flashes a solid emerald for the
      // duration of the animation before the radial [backdrop] shows through.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android:
              ZoomPageTransitionsBuilder(backgroundColor: Colors.transparent),
          TargetPlatform.iOS:
              ZoomPageTransitionsBuilder(backgroundColor: Colors.transparent),
        },
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surfaceDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.cream,
        elevation: 0,
        titleTextStyle: GoogleFonts.petrona(
            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.cream),
      ),
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme)
          .apply(bodyColor: AppColors.cream, displayColor: AppColors.cream),
      iconTheme: IconThemeData(color: AppColors.cream),
    );
  }
}
