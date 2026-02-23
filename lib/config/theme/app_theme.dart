// app_theme.dart
// ─────────────────────────────────────────────────────────────
// Material 3 theme. Uses ColorScheme.fromSeed — no custom colors.
// Responsive breakpoints for mobile / tablet / desktop.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(
    0xFF1A73E8,
  ); // Google-blue seed — clean, professional

  // ── Light theme ───────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: _inputTheme(Brightness.light),
    filledButtonTheme: _filledButtonTheme(),
    outlinedButtonTheme: _outlinedButtonTheme(),
    textButtonTheme: _textButtonTheme(),
    cardTheme: _cardTheme(),
    appBarTheme: _appBarTheme(),
  );

  // ── Dark theme ────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    inputDecorationTheme: _inputTheme(Brightness.dark),
    filledButtonTheme: _filledButtonTheme(),
    outlinedButtonTheme: _outlinedButtonTheme(),
    textButtonTheme: _textButtonTheme(),
    cardTheme: _cardTheme(),
    appBarTheme: _appBarTheme(),
  );

  // ── Shared component themes ───────────────────────────────

  static InputDecorationTheme _inputTheme(Brightness brightness) =>
      const InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      );

  static FilledButtonThemeData _filledButtonTheme() => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
    style: TextButton.styleFrom(
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  );

  static CardThemeData _cardTheme() => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  );

  static AppBarTheme _appBarTheme() => const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 1,
  );
}

// ── Responsive layout helper ──────────────────────────────────
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= 600 && w < 1024;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  /// Max content width for auth forms on large screens.
  static double authFormMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 440;
    if (isTablet(context)) return 480;
    return double.infinity;
  }
}
