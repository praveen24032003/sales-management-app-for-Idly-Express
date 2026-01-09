import 'package:flutter/material.dart';

/// App theme with Warm Terracotta color scheme
/// Supports both light and dark modes

class AppColors {
  // Light Mode Colors
  static const Color primaryLight = Color(0xFFD84315);
  static const Color surfaceLight = Color(0xFFFFF8E1);
  static const Color accentLight = Color(0xFF43A047);
  static const Color profitLight = Color(0xFF2E7D32);
  static const Color lossLight = Color(0xFFC62828);
  static const Color cardLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);

  // Dark Mode Colors
  static const Color primaryDark = Color(0xFFFF7043);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color accentDark = Color(0xFF66BB6A);
  static const Color profitDark = Color(0xFF81C784);
  static const Color lossDark = Color(0xFFEF5350);
  static const Color cardDark = Color(0xFF2D2D2D);
  static const Color textPrimaryDark = Color(0xFFFAFAFA);
  static const Color textSecondaryDark = Color(0xFFBDBDBD);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryLight,
        secondary: AppColors.accentLight,
        surface: AppColors.surfaceLight,
        error: AppColors.lossLight,
      ),
      scaffoldBackgroundColor: AppColors.surfaceLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textSecondaryLight,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.accentDark,
        surface: AppColors.surfaceDark,
        error: AppColors.lossDark,
      ),
      scaffoldBackgroundColor: AppColors.surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.black,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2D2D2D),
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.textSecondaryDark,
      ),
    );
  }
}

// Extension for easy access to profit/loss colors
extension ThemeExtensions on BuildContext {
  Color get profitColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.profitLight
      : AppColors.profitDark;

  Color get lossColor => Theme.of(this).brightness == Brightness.light
      ? AppColors.lossLight
      : AppColors.lossDark;
}
