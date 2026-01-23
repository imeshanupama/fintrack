import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF064E3B); // Dark Forest Green
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color tertiaryColor = Color(0xFF34D399); // Mint Accent
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF4CAF50);
  
  // Custom Dark Palette
  static const Color darkBackground = Color(0xFF0A0A0A); // Deeper black
  static const Color darkSurface = Color(0xFF1A1A1A); // Slightly lighter
  static const Color darkSurfaceVariant = Color(0xFF242424); // For elevated cards
  static const Color darkOnSurface = Color(0xFFE8E8E8); // Better contrast
  static const Color darkOnSurfaceVariant = Color(0xFFB0B0B0); // Secondary text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: GoogleFonts.outfit().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondaryColor, // Use brighter emerald for dark mode primary visual
      scaffoldBackgroundColor: darkBackground,
      fontFamily: GoogleFonts.outfit().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: secondaryColor, // Use brighter emerald for dark mode seed
        brightness: Brightness.dark,
        secondary: secondaryColor,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: darkSurfaceVariant,
            width: 1,
          ),
        ),
      ),
      dividerColor: darkSurfaceVariant,
      // Improve text contrast
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: darkOnSurface),
        bodyMedium: TextStyle(color: darkOnSurface),
        bodySmall: TextStyle(color: darkOnSurfaceVariant),
        titleLarge: TextStyle(color: darkOnSurface),
        titleMedium: TextStyle(color: darkOnSurface),
        titleSmall: TextStyle(color: darkOnSurface),
      ),
    );
  }
}
