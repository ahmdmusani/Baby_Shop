import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors based on design requirements
  static const Color primaryColor = Color(0xFFFF4071);
  static const Color backgroundColor = Color(0xFFFAFAFC);
  static const Color textPrimary = Color(0xFF1E1F24);
  static const Color textSecondary = Color(0xFF888B97);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFECEFF3);

  // Dark Mode Colors
  static const Color darkBackgroundColor = Color(0xFF0F0F12);
  static const Color darkSurfaceColor = Color(0xFF1A1A1F);
  static const Color darkTextPrimary = Color(0xFFFAFAFC);
  static const Color darkTextSecondary = Color(0xFF8E909A);
  static const Color darkInputBackground = Color(0xFF1E1E24);
  static const Color darkBorderColor = Color(0xFF2D2E38);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        surface: backgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Rounded Corners: 20px+
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      fontFamily: GoogleFonts.poppins().fontFamily,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 32),
        displayMedium: GoogleFonts.poppins(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 28),
        displaySmall: GoogleFonts.poppins(color: darkTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
        headlineMedium: GoogleFonts.poppins(color: darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
        titleMedium: GoogleFonts.poppins(color: darkTextPrimary, fontWeight: FontWeight.w500, fontSize: 16),
        bodyLarge: GoogleFonts.poppins(color: darkTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
      ),
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: darkBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.poppins(color: darkTextSecondary),
      ),
    );
  }
}
