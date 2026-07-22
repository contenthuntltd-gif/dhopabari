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
  static const dangerSoft = Color(0xFFFCE9EB);
  static const green = Color(0xFF12B886);
  static const skeleton = Color(0xFFEDF1F7);
}

class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
}

/// The only spacing values that should appear in `SizedBox`/`EdgeInsets`
/// across the app. Picking from this scale (instead of ad-hoc numbers like
/// 10, 14, 18, 22...) is what makes every screen's rhythm feel like one
/// product instead of a patchwork of screens.
class AppSpace {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
}

/// Icon sizes used across the app — pick the closest role, don't invent
/// one-off sizes per screen.
class AppIconSize {
  static const sm = 16.0; // inline w/ text, badges
  static const md = 20.0; // input prefixes, list-row leading icons
  static const lg = 24.0; // nav bar, app bar actions
  static const xl = 32.0; // empty-state / feature icons
}

/// Shared motion durations/curves so every screen's animations feel like
/// one system instead of ad-hoc per-widget timings.
class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const curve = Curves.easeOutCubic;
  static const entrance = Curves.easeOutQuart;
}

class AppShadows {
  static List<BoxShadow> card = [
    BoxShadow(color: AppColors.ink.withValues(alpha: 0.03), blurRadius: 2, offset: const Offset(0, 1)),
    BoxShadow(color: AppColors.ink.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> button = [
    BoxShadow(color: AppColors.blue.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
  ];
  static List<BoxShadow> soft = [
    BoxShadow(color: AppColors.ink.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
  ];
}

/// Reusable text styles so headings/body/caption sizing stays consistent
/// across every screen instead of hand-picked font sizes per widget.
class AppText {
  static const display = TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.25);
  static const h1 = TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.3);
  static const h2 = TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.ink, height: 1.3);
  static const h3 = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.ink, height: 1.3);
  static const body = TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink, height: 1.45);
  static const bodyMuted = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.45);
  static const caption = TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted, height: 1.4);
  static const label = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink);
  static const button = TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Colors.white);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.card,
    splashFactory: InkRipple.splashFactory,
    // Brand Bangla typeface everywhere — every Text in the app inherits
    // this family, so no Bangla word ever falls back to the system font.
    fontFamily: 'KohinoorBangla',
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
      fontFamily: 'KohinoorBangla',
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.blue,
      selectionColor: AppColors.blueSoft,
      selectionHandleColor: AppColors.blue,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.card,
      foregroundColor: AppColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: AppColors.ink),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFB9C8EE),
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
        animationDuration: AppMotion.fast,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blue,
        disabledForegroundColor: AppColors.muted,
        side: const BorderSide(color: AppColors.blue, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        animationDuration: AppMotion.fast,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: const Size(0, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(8),
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
        borderSide: const BorderSide(color: AppColors.blue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.line, width: 1.2),
      ),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 11.5, fontWeight: FontWeight.w700),
      hintStyle: const TextStyle(color: Color(0xFFA2ABB8), fontWeight: FontWeight.w600),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.05)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),
  );
}
