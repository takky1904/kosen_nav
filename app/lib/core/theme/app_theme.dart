import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color neonGreen = Color(0xFF00FF87);
  static const Color neonRed = Color(0xFFFF2D55);
  static const Color neonYellow = Color(0xFFFFD60A);
  static const Color neonOrange = Color(0xFFFF6B2B);
  static const Color neonBlue = Color(0xFF00D2FF);
  static const Color bgDeep = Color(0xFF0A0E1A);
  static const Color bgSurface = Color(0xFF111827);
  static const Color bgCard = Color(0xFF1A2235);
  static const Color textPrimary = Color(0xFFE8F0FF);
  static const Color textSecondary = Color(0xFF8899BB);
  static const Color border = Color(0xFF1E2D44);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color statusPass = neonGreen;
  static const Color statusConditional = neonYellow;
  static const Color statusDanger = neonOrange;
  static const Color statusFailing = neonRed;

  static TextStyle get logoStyle => GoogleFonts.orbitron(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      );

  // ── Text Theme ─────────────────────────────────────────────────────────────
  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.notoSansJpTextTheme(ThemeData.dark().textTheme);
    return base.copyWith(
      displayLarge: GoogleFonts.notoSansJp(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: textPrimary,
        letterSpacing: 2,
      ),
      displayMedium: GoogleFonts.notoSansJp(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 1.5,
      ),
      headlineLarge: GoogleFonts.notoSansJp(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.notoSansJp(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.notoSansJp(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.notoSansJp(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.notoSansJp(fontSize: 14, color: textSecondary),
      labelLarge: GoogleFonts.notoSansJp(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: neonRed,
        surface: bgSurface,
        onPrimary: bgDeep,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        error: neonRed,
      ),
      textTheme: _buildTextTheme(),
      useMaterial3: true,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: bgDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSansJp(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: neonGreen,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Card
      cardTheme: const CardThemeData(
        color: bgCard,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: border, width: 1),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: neonGreen, width: 1.5),
        ),
        labelStyle: GoogleFonts.notoSansJp(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.notoSansJp(color: textSecondary, fontSize: 13),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: bgDeep,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.notoSansJp(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
      ),

      // Navigation Rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: bgSurface,
        selectedIconTheme: const IconThemeData(color: neonGreen),
        unselectedIconTheme: const IconThemeData(color: textSecondary),
        selectedLabelTextStyle: GoogleFonts.notoSansJp(
          color: neonGreen,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: GoogleFonts.notoSansJp(
          color: textSecondary,
          fontSize: 12,
        ),
        indicatorColor: const Color(0xff00ff8720),
      ),

      // Divider
      dividerTheme: const DividerThemeData(color: border, thickness: 1),

      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: neonGreen,
        thumbColor: neonGreen,
        inactiveTrackColor: border,
        overlayColor: Color(0xff00ff8730),
      ),
    );
  }

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: bgSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonGreen, width: 2),
      ),
      labelStyle: GoogleFonts.notoSansJp(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
