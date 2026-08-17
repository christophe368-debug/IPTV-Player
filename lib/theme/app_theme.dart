import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Eigenes Farb-/Typografie-System der App - bewusst nicht das generische
/// Material-"colorSchemeSeed"-Lila vom Anfang, sondern an die Sendungs-/
/// Broadcast-Welt angelehnt: dunkler, leicht blaustichiger Hintergrund wie
/// ein Bildschirm im abgedunkelten Raum, warmes Signalrot als Hauptakzent
/// (erinnert an eine "On-Air"-Anzeige), Bernstein als Zweitakzent fuer
/// alles, was gerade laeuft (EPG "Jetzt", Live-Kennzeichnung).
class AppColors {
  AppColors._();

  // Akzente - identisch in Hell und Dunkel, sind das Wiedererkennungsmerkmal
  // der App (siehe LivePulse-Widget).
  static const primary = Color(0xFFFF4B3E);
  static const secondary = Color(0xFFFFB238);

  // Dunkel (Standard-Erlebnis - Live-TV/Streaming wird ueberwiegend im
  // abgedunkelten Raum geschaut).
  static const backgroundDark = Color(0xFF0B0E14);
  static const surfaceDark = Color(0xFF161B24);
  static const surfaceElevatedDark = Color(0xFF1F2733);
  static const textPrimaryDark = Color(0xFFF5F3EE);
  static const textSecondaryDark = Color(0xFF8A93A6);

  // Hell
  static const backgroundLight = Color(0xFFF7F5F0);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFEFEBE3);
  static const textPrimaryLight = Color(0xFF1A1D24);
  static const textSecondaryLight = Color(0xFF5C6470);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final surfaceElevated = isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceElevatedLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: const Color(0xFF1A1200),
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerHighest: surfaceElevated,
      error: const Color(0xFFCF6679),
      onError: Colors.white,
    );

    // Ueberschriften: Space Grotesk (kantig, technisch - passt zum
    // Broadcast-Thema). Fliesstext/Listen: Inter (neutral, sehr gut
    // lesbar in kleinen Groessen).
    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final displayFont = GoogleFonts.spaceGroteskTextTheme(baseTextTheme);
    final bodyFont = GoogleFonts.interTextTheme(baseTextTheme);
    final textTheme = bodyFont
        .copyWith(
          displayLarge: displayFont.displayLarge,
          displayMedium: displayFont.displayMedium,
          displaySmall: displayFont.displaySmall,
          headlineLarge: displayFont.headlineLarge,
          headlineMedium: displayFont.headlineMedium,
          headlineSmall: displayFont.headlineSmall,
          titleLarge: displayFont.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: displayFont.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          titleSmall: displayFont.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: textPrimary, displayColor: textPrimary);

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: textPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(color: textSecondary),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        labelStyle: textTheme.labelMedium,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: isDark ? Colors.white12 : Colors.black12,
    );
  }
}
