import 'package:flutter/material.dart';

/// Dhopa Bari brand palette — premium blue & white, matches the
/// approved web/mobile mockups (login, home, admin screens).
class AppColors {
  static const ink = Color(0xFF0B1F3A);
  static const blueDeep = Color(0xFF0A3FB0);
  static const blue = Color(0xFF1259E8);
  static const blueSoft = Color(0xFFEAF1FF);
  static const teal = Color(0xFF0EA5A0);
  static const tealSoft = Color(0xFFE1F7F4);
  static const amber = Color(0xFFE8A93A);
  static const amberSoft = Color(0xFFFDF3E0);
  static const paper = Color(0xFFF5F7FB);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE7EBF3);
  static const muted = Color(0xFF66748F);
  static const danger = Color(0xFFE23F4F);
  static const green = Color(0xFF12B886);
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: AppColors.ink.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: AppColors.ink.withOpacity(0.10), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> button = [
    BoxShadow(color: AppColors.blue.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
  ];
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'HindSiliguri',
    scaffoldBackgroundColor: AppColors.card,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.teal,
      error: AppColors.danger,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        side: const BorderSide(color: AppColors.blue, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.line, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.line, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.6),
      ),
      hintStyle: const TextStyle(color: Color(0xFFA2ABB8), fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.ink.withOpacity(0.05)),
      ),
    ),
  );
}
