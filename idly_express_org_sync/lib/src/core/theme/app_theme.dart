import 'package:flutter/material.dart';

import 'brand_tokens.dart';

class AppTheme {
  static final light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF35A8D8),
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF6FAFD),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      surfaceTintColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: const Color(0xFFD8E9F4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF35A8D8), width: 1.4),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF5D7283)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        backgroundColor: const Color(0xFF35A8D8),
        foregroundColor: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(letterSpacing: -1.2),
      headlineSmall: TextStyle(letterSpacing: -0.8),
      titleLarge: TextStyle(letterSpacing: -0.5),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      BrandColors.light,
    ],
  );

  static final dark = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF35A8D8),
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: BrandColors.dark.surfaceTop,
    extensions: const <ThemeExtension<dynamic>>[
      BrandColors.dark,
    ],
  );
}