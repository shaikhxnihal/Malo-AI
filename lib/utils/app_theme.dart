import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF0A0C10);
  static const surface = Color(0xFF12151C);
  static const card = Color(0xFF181D27);
  static const border = Color(0xFF232836);
  static const accent = Color(0xFF00E5C8);
  static const accentDim = Color(0x2000E5C8);
  static const accentGlow = Color(0x4000E5C8);
  static const warn = Color(0xFFFFB547);
  static const warnDim = Color(0x20FFB547);
  static const danger = Color(0xFFFF4D6A);
  static const dangerDim = Color(0x20FF4D6A);
  static const success = Color(0xFF00D68F);
  static const successDim = Color(0x2000D68F);
  static const textPrimary = Color(0xFFE8EDF5);
  static const textSub = Color(0xFF7A8499);
  static const textMuted = Color(0xFF3D4557);
  static const purple = Color(0xFF8B5CF6);
  static const purpleDim = Color(0x208B5CF6);
  static const blue = Color(0xFF3B82F6);
  static const blueDim = Color(0x203B82F6);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.bg,
        onBackground: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: AppColors.textPrimary),
          displayMedium: TextStyle(color: AppColors.textPrimary),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSub),
          bodySmall: TextStyle(color: AppColors.textMuted),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.textSub),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentDim,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: AppColors.textMuted, fontSize: 11);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  static TextStyle get displayFont =>
      GoogleFonts.dmSerifDisplay(color: AppColors.textPrimary);
  static TextStyle get monoFont =>
      GoogleFonts.dmMono(color: AppColors.textPrimary);
}