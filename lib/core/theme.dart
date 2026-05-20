import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App theme – Modern Professional design system
/// Business monitoring palette with Professional Blue, Cool Gray, and Warm Amber
/// Optimized for corporate dashboards with psychology-backed color choices
class AppColors {
  // ───────────────────────────────────────────────────────────────────────────
  // Light Mode Colors
  // ───────────────────────────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFFFFFFF); // Clean white background
  static const Color surfaceLight = Color(0xFFF5F7F9); // Light cool off-white
  static const Color cardLight = Color(0xFFFFFFFF); // Pure white cards
  static const Color primaryLight = Color(0xFF0F63DC); // Professional Blue
  static const Color accentLight = Color(0xFFF59E0B); // Warm Amber
  static const Color textPrimaryLight = Color(0xFF0F172A); // Deep Navy text
  static const Color textSecondaryLight = Color(0xFF5B6D6F); // Cool Gray
  static const Color borderLight = Color(0xFFDCE2E7); // Light cool gray border
  static const Color profitLight = Color(0xFF059669); // Emerald Green (success)
  static const Color lossLight = Color(0xFFF87171); // Coral Red (alert)

  // ───────────────────────────────────────────────────────────────────────────
  // Dark Mode Colors
  // ───────────────────────────────────────────────────────────────────────────
  static const Color bgDark = Color(0xFF0F172A); // Deep Navy background
  static const Color surfaceDark = Color(0xFF1A2332); // Slightly lighter navy
  static const Color cardDark = Color(0xFF242F3B); // Navy for card surfaces
  static const Color cardDark2 = Color(0xFF2E3A48); // Lighter variant for nested cards
  static const Color primaryDark = Color(0xFF60A5FA); // Light blue (dark mode)
  static const Color accentDark = Color(0xFFF59E0B); // Warm Amber (accent)
  static const Color textPrimaryDark = Color(0xFFF0F4F8); // Very light text
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Cool gray secondary
  static const Color borderDark = Color(0xFF3A4556); // Dark cool gray border
  static const Color profitDark = Color(0xFF4ADE80); // Lighter emerald (dark mode)
  static const Color lossDark = Color(0xFFFF7F7F); // Lighter coral (dark mode)
}

/// Radius constants for consistent border-radius values
class AppRadius {
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double pill = 999.0;
}

/// Spacing constants for consistent padding/margin values
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// Animation constants for consistent, calm UX
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
  static const Duration xslow = Duration(milliseconds: 800);
  static const Duration float = Duration(milliseconds: 3000);
  static const Duration glow = Duration(milliseconds: 2000);

  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve spring = Curves.easeOutBack;
}

/// Gradient palettes for the time-of-day hero
class TimeGradients {
  // Morning 5–11
  static const List<Color> morningLight = [
    Color(0xFFFF9A56), Color(0xFFFFC47A), Color(0xFFFFE4A6),
  ];
  static const List<Color> morningDark = [
    Color(0xFF7A3A10), Color(0xFFB05C20), Color(0xFFD4844A),
  ];

  // Afternoon 12–16
  static const List<Color> afternoonLight = [
    Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFF7DD3FC),
  ];
  static const List<Color> afternoonDark = [
    Color(0xFF0C2B3D), Color(0xFF0F4B6E), Color(0xFF1565A0),
  ];

  // Evening 17–20
  static const List<Color> eveningLight = [
    Color(0xFFEC4899), Color(0xFFF97316), Color(0xFFFBBF24),
  ];
  static const List<Color> eveningDark = [
    Color(0xFF4A1232), Color(0xFF6B2020), Color(0xFF8B4C10),
  ];

  // Night 21–4
  static const List<Color> nightLight = [
    Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF020617),
  ];
  static const List<Color> nightDark = [
    Color(0xFF0D1117), Color(0xFF0A0F1A), Color(0xFF04060D),
  ];

  static List<Color> getGradient(int hour, bool isDark) {
    if (hour >= 5 && hour < 12) return isDark ? morningDark : morningLight;
    if (hour >= 12 && hour < 17) return isDark ? afternoonDark : afternoonLight;
    if (hour >= 17 && hour < 21) return isDark ? eveningDark : eveningLight;
    return isDark ? nightDark : nightLight;
  }

  static Color getSunMoonColor(int hour) {
    if (hour >= 5 && hour < 12) return const Color(0xFFFFD369);
    if (hour >= 12 && hour < 17) return const Color(0xFFFFF9C4);
    if (hour >= 17 && hour < 21) return const Color(0xFFFF7043);
    return const Color(0xFFE8EAF6);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Light Theme
// ─────────────────────────────────────────────────────────────────────────────
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.bgLight,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgLight,
    foregroundColor: AppColors.textPrimaryLight,
    elevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  ),
  colorScheme: ColorScheme.light(
    primary: AppColors.primaryLight,
    surface: AppColors.surfaceLight,
    surfaceContainerHighest: AppColors.surfaceLight,
    onPrimary: Colors.white,
    onSurface: AppColors.textPrimaryLight,
    secondary: AppColors.accentLight,
    onSecondary: AppColors.textPrimaryLight,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardLight,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(
        color: AppColors.primaryLight,
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryLight,
    foregroundColor: Colors.white,
    shape: const CircleBorder(),
    elevation: 6,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.primaryLight,
    unselectedLabelColor: AppColors.textSecondaryLight,
    indicatorColor: AppColors.primaryLight,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(
        color: AppColors.primaryLight,
        width: 3,
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimaryLight,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondaryLight,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondaryLight.withValues(alpha: 0.8),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.cardLight,
    selectedItemColor: AppColors.primaryLight,
    unselectedItemColor: AppColors.textSecondaryLight,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Dark Theme
// ─────────────────────────────────────────────────────────────────────────────
final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.bgDark,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.bgDark,
    foregroundColor: AppColors.textPrimaryDark,
    elevation: 0,
    centerTitle: false,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  ),
  colorScheme: ColorScheme.dark(
    primary: AppColors.primaryDark,
    surface: AppColors.surfaceDark,
    surfaceContainerHighest: AppColors.surfaceDark,
    onPrimary: AppColors.bgDark,
    onSurface: AppColors.textPrimaryDark,
    secondary: AppColors.accentDark,
    onSecondary: AppColors.bgDark,
  ),
  cardTheme: CardThemeData(
    color: AppColors.cardDark,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.borderDark, width: 1),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceDark,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.borderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(
        color: AppColors.primaryDark,
        width: 1.5,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.primaryDark,
    foregroundColor: AppColors.bgDark,
    shape: const CircleBorder(),
    elevation: 6,
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: AppColors.primaryDark,
    unselectedLabelColor: AppColors.textSecondaryDark,
    indicatorColor: AppColors.primaryDark,
    indicator: const UnderlineTabIndicator(
      borderSide: BorderSide(
        color: AppColors.primaryDark,
        width: 3,
      ),
    ),
  ),
  textTheme: TextTheme(
    headlineLarge: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimaryDark,
    ),
    headlineMedium: const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w900,
      color: AppColors.textPrimaryDark,
    ),
    titleLarge: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryDark,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondaryDark,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.cardDark,
    selectedItemColor: AppColors.primaryDark,
    unselectedItemColor: AppColors.textSecondaryDark,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Theme Context Extension – Convenience getters for theme colors
// ─────────────────────────────────────────────────────────────────────────────
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get profitColor =>
      isDark ? AppColors.profitDark : AppColors.profitLight;

  Color get lossColor => isDark ? AppColors.lossDark : AppColors.lossLight;

  Color get cardBg =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  Color get subtleText =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get goldAccent =>
      isDark ? AppColors.accentDark : AppColors.accentLight;

  Color get hairline =>
      isDark ? AppColors.borderDark : AppColors.borderLight;
}
