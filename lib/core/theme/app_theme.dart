import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_palette.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.primary,
      brightness: Brightness.light,
      primary: ColorPalette.primary,
      secondary: ColorPalette.secondary,
      surface: ColorPalette.surfaceLight,
      error: ColorPalette.danger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorPalette.backgroundLight,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: ColorPalette.backgroundLight,
        foregroundColor: Colors.black,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primary, width: 1.6),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: ColorPalette.primary,
      brightness: Brightness.dark,
      primary: ColorPalette.primary,
      secondary: ColorPalette.secondary,
      surface: ColorPalette.surfaceDark,
      error: ColorPalette.danger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: ColorPalette.backgroundDark,
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w700),
        headlineMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: ColorPalette.backgroundDark,
        foregroundColor: Colors.white,
        elevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorPalette.primary, width: 1.6),
        ),
      ),
    );
  }
}