import 'package:flutter/material.dart';

class AppTheme {
  // EXACT COLORS EXTRACTED FROM YOUR IMAGE
  static const Color darkBase = Color(0xFF04060E); // Deepest space-navy (bottom of screen)
  static const Color surfaceBlue = Color(0xFF0E1329); // Card/Panel color
  static const Color borderBlue = Color(0xFF1F2947); // Subtle card borders
  
  static const Color primaryBlue = Color(0xFF2563EB); // The vibrant royal blue for buttons
  static const Color glowBlue = Color(0xFF3B82F6); // Lighter blue for active states

  static const Color textHigh = Colors.white;
  static const Color textMed = Color(0xFF8E95A3); // Muted blue-grey for subtitles

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBase, // Fallback if gradient isn't used
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: glowBlue,
        surface: surfaceBlue,
        onSurface: textHigh,
      ),
      cardTheme: CardThemeData(
        color: surfaceBlue,
        elevation: 0, // Depth is created by the border now, like the image
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Highly rounded corners
          side: const BorderSide(color: borderBlue, width: 1.2), // Subtle outline
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: textHigh, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(color: textHigh, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.5), // "Meet Your AI Assistant"
        titleLarge: TextStyle(color: textHigh, fontSize: 24, fontWeight: FontWeight.bold), // "Premium Plan"
        titleMedium: TextStyle(color: textHigh, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textHigh, fontSize: 16),
        bodyMedium: TextStyle(color: textMed, fontSize: 14), // "Get answers, manage tasks..."
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: primaryBlue.withOpacity(0.4), // Subtle blue glow under button
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shaped
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A0E1F), // Slightly darker than cards for inputs
        hintStyle: const TextStyle(color: textMed),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), 
          borderSide: const BorderSide(color: borderBlue, width: 1)
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), 
          borderSide: const BorderSide(color: borderBlue, width: 1)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24), 
          borderSide: const BorderSide(color: primaryBlue, width: 1.5)
        ),
      ),
    );
  }
}