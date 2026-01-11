import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6C63FF); // Deep Purple
  static const Color secondaryColor = Color(0xFF03DAC6); // Teal
  static const Color errorColor = Color(0xFFCF6679);
  static const Color successColor = Color(0xFF4CAF50);
  
  // Custom Dark Palette
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFE0E0E0);

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
      /*
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      */
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: GoogleFonts.outfit().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      /*
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      */
    );
  }
}
