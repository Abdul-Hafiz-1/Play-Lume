import 'package:flutter/material.dart';

enum AppThemePreset {
  lumeGlass,
  neonTabletop,
  caseFile,
}

class ThemeController {
  static final ValueNotifier<AppThemePreset> preset =
      ValueNotifier<AppThemePreset>(AppThemePreset.lumeGlass);

  static void setPreset(AppThemePreset value) {
    preset.value = value;
  }
}

class AppTheme {
  // EXACT COLORS EXTRACTED FROM YOUR IMAGE
  static const Color darkBase = Color(0xFF04060E); // Deepest space-navy (bottom of screen)
  static const Color surfaceBlue = Color(0xFF0E1329); // Card/Panel color
  static const Color borderBlue = Color(0xFF1F2947); // Subtle card borders
  
  static const Color primaryBlue = Color(0xFF2563EB); // The vibrant royal blue for buttons
  static const Color glowBlue = Color(0xFF3B82F6); // Lighter blue for active states

  static const Color textHigh = Colors.white;
  static const Color textMed = Color(0xFF8E95A3); // Muted blue-grey for subtitles

  static ThemeData themeFor(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.neonTabletop:
        return _buildTheme(
          base: const Color(0xFF101826),
          surface: const Color(0xFF172238),
          border: const Color(0xFF3B5278),
          primary: const Color(0xFFFFC857),
          secondary: const Color(0xFF47D7AC),
          textMed: const Color(0xFFC4CEDB),
        );
      case AppThemePreset.caseFile:
        return _buildTheme(
          base: const Color(0xFF15110C),
          surface: const Color(0xFF241C14),
          border: const Color(0xFF5A4632),
          primary: const Color(0xFFE0B56B),
          secondary: const Color(0xFFB85252),
          textMed: const Color(0xFFD6C8B2),
        );
      case AppThemePreset.lumeGlass:
        return darkTheme;
    }
  }

  static ThemeData get darkTheme {
    return _buildTheme(
      base: darkBase,
      surface: surfaceBlue,
      border: borderBlue,
      primary: primaryBlue,
      secondary: glowBlue,
      textMed: textMed,
    );
  }

  static ThemeData _buildTheme({
    required Color base,
    required Color surface,
    required Color border,
    required Color primary,
    required Color secondary,
    required Color textMed,
  }) {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: base,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: textHigh,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border, width: 1.2),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: textHigh, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: TextTheme(
        displaySmall: const TextStyle(color: textHigh, fontSize: 34, fontWeight: FontWeight.bold),
        titleLarge: const TextStyle(color: textHigh, fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(color: textHigh, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textHigh, fontSize: 16),
        bodyMedium: TextStyle(color: textMed, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primary.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: base,
        hintStyle: TextStyle(color: textMed),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: BorderSide(color: border, width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: BorderSide(color: border, width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18), 
          borderSide: BorderSide(color: primary, width: 1.5)
        ),
      ),
    );
  }
}
