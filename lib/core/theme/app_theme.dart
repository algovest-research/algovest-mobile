import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand colours ────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  static const accent  = Color(0xFF3F72AF);
  static const bg      = Color(0xFFF9F7F7);
  static const surface = Color(0xFFFFFFFF);
  static const border  = Color(0xFFDBE2EF);
  static const s2      = Color(0xFFDBE2EF);

  static const text    = Color(0xFF112D4E);
  static const muted   = Color(0xFF2A4A6E);
  static const dim     = Color(0xFF6683A3);

  static const buy     = Color(0xFF008060);
  static const sell    = Color(0xFFD62B3A);
  static const hold    = Color(0xFFC87A00);

  static const earlyBird = Color(0xFF25D366);
}

// ── Text styles ───────────────────────────────────────────────────────────────
class AppText {
  AppText._();

  static TextStyle fraunces({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color color = AppColors.text,
    double? height,
    double letterSpacing = -0.02,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle mono({
    double size = 13,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }
}

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.text,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: AppText.fraunces(size: 48, weight: FontWeight.w900),
        displayMedium: AppText.fraunces(size: 36, weight: FontWeight.w700),
        headlineLarge: AppText.fraunces(size: 28, weight: FontWeight.w700),
        headlineMedium: AppText.fraunces(size: 22, weight: FontWeight.w600),
        titleLarge: AppText.body(size: 16, weight: FontWeight.w600),
        bodyLarge: AppText.body(size: 15),
        bodyMedium: AppText.body(size: 14),
        bodySmall: AppText.body(size: 12, color: AppColors.muted),
        labelSmall: AppText.mono(size: 10, color: AppColors.dim),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppText.fraunces(size: 20, weight: FontWeight.w700),
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.accent.withOpacity(0.14),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.dim,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppText.body(
            size: 11,
            weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? AppColors.accent : AppColors.dim,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: AppText.body(size: 14, weight: FontWeight.w600, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.s2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}