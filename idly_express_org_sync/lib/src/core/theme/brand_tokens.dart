import 'package:flutter/material.dart';

/// Centralized design tokens for the Idly Express brand surface.
///
/// Brand-identity values (primary, accents, radii) live as static constants
/// because they do not change between light and dark themes. Theme-dependent
/// values (surfaces, text, borders, gradients) live in [BrandColors], which is
/// registered as a [ThemeExtension] on light and dark `ThemeData` and read via
/// `context.brand`.
class BrandTokens {
  BrandTokens._();

  // Brand identity (theme-invariant)
  static const Color primary = Color(0xFF35A8D8);
  static const Color primaryDeep = Color(0xFF1A6E91);

  // Accents for tone-coded metrics and chips (theme-invariant identity)
  static const Color accentSales = Color(0xFF35A8D8);
  static const Color accentExpense = Color(0xFFE08A1F);
  static const Color accentOutstanding = Color(0xFF8C5BD6);
  static const Color accentProfit = Color(0xFF2BAE7E);

  // Standard rounding
  static const double radiusCard = 24;
  static const double radiusChip = 999;
  static const double radiusField = 18;

  /// Scaffold background gradient — picks the right variant for the active
  /// theme. Always prefer this over hardcoding gradient colors.
  static LinearGradient scaffoldGradient(BuildContext context) {
    final brand = context.brand;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: brand.scaffoldGradient,
    );
  }
}

/// Theme-aware brand palette. Light and dark variants live as static instances
/// on this class. Read inside a widget with `context.brand`.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.surfaceTop,
    required this.surfaceMid,
    required this.surfaceCard,
    required this.surfaceCardAlpha,
    required this.surfaceSheet,
    required this.surfaceSoft,
    required this.border,
    required this.borderStrong,
    required this.textStrong,
    required this.textBody,
    required this.textMuted,
    required this.textLabel,
    required this.primarySoft,
    required this.primaryDeep,
    required this.successFg,
    required this.successBg,
    required this.successBorder,
    required this.warningFg,
    required this.warningBg,
    required this.warningBorder,
    required this.scaffoldGradient,
    required this.orbA,
    required this.orbB,
  });

  // Surfaces
  final Color surfaceTop;
  final Color surfaceMid;
  final Color surfaceCard;
  final Color surfaceCardAlpha;
  final Color surfaceSheet;
  final Color surfaceSoft;

  // Borders
  final Color border;
  final Color borderStrong;

  // Text
  final Color textStrong;
  final Color textBody;
  final Color textMuted;
  final Color textLabel;

  // Brand tints
  final Color primarySoft;
  final Color primaryDeep;

  // Status palettes (theme-resolved versions; identity hues stay close).
  final Color successFg;
  final Color successBg;
  final Color successBorder;
  final Color warningFg;
  final Color warningBg;
  final Color warningBorder;

  // Gradient + orbs
  final List<Color> scaffoldGradient;
  final Color orbA;
  final Color orbB;

  static const light = BrandColors(
    surfaceTop: Color(0xFFF8FCFF),
    surfaceMid: Color(0xFFFDFEFF),
    surfaceCard: Colors.white,
    surfaceCardAlpha: Color(0xEBFFFFFF), // white @ ~92% alpha
    surfaceSheet: Color(0xFFF6FBFE),
    surfaceSoft: Color(0xFFF1F9FD),
    border: Color(0xFFD6EAF4),
    borderStrong: Color(0xFFC0DEEC),
    textStrong: Color(0xFF20313C),
    textBody: Color(0xFF365060),
    textMuted: Color(0xFF6A8391),
    textLabel: Color(0xFF5A7382),
    primarySoft: Color(0xFFE9F8FD),
    primaryDeep: Color(0xFF1A6E91),
    successFg: Color(0xFF1F7A4F),
    successBg: Color(0xFFE6F8EE),
    successBorder: Color(0xFFC9EAD6),
    warningFg: Color(0xFF8A5A12),
    warningBg: Color(0xFFFFF4E0),
    warningBorder: Color(0xFFF1D7A6),
    scaffoldGradient: [
      Color(0xFFF8FCFF),
      Color(0xFFFDFEFF),
      Color(0x4035A8D8),
    ],
    orbA: Color(0xFFBEEBFA),
    orbB: Color(0xFFE4F5FC),
  );

  static const dark = BrandColors(
    surfaceTop: Color(0xFF0E1820),
    surfaceMid: Color(0xFF111D28),
    surfaceCard: Color(0xFF162533),
    surfaceCardAlpha: Color(0xE0162533), // ~88% alpha dark card
    surfaceSheet: Color(0xFF13202D),
    surfaceSoft: Color(0xFF1A2C3B),
    border: Color(0xFF2B4558),
    borderStrong: Color(0xFF3C6480),
    textStrong: Color(0xFFEFF7FC),
    textBody: Color(0xFFC5D5E0),
    textMuted: Color(0xFF95ABBA),
    textLabel: Color(0xFFA6BCCB),
    primarySoft: Color(0xFF1C445A),
    primaryDeep: Color(0xFF7CCFEC),
    successFg: Color(0xFF7CE0AE),
    successBg: Color(0xFF143526),
    successBorder: Color(0xFF1F5B40),
    warningFg: Color(0xFFFFC980),
    warningBg: Color(0xFF3C2B14),
    warningBorder: Color(0xFF725020),
    scaffoldGradient: [
      Color(0xFF0E1820),
      Color(0xFF111D28),
      Color(0x662D9DCA),
    ],
    orbA: Color(0xFF173F57),
    orbB: Color(0xFF214A63),
  );

  @override
  BrandColors copyWith({
    Color? surfaceTop,
    Color? surfaceMid,
    Color? surfaceCard,
    Color? surfaceCardAlpha,
    Color? surfaceSheet,
    Color? surfaceSoft,
    Color? border,
    Color? borderStrong,
    Color? textStrong,
    Color? textBody,
    Color? textMuted,
    Color? textLabel,
    Color? primarySoft,
    Color? primaryDeep,
    Color? successFg,
    Color? successBg,
    Color? successBorder,
    Color? warningFg,
    Color? warningBg,
    Color? warningBorder,
    List<Color>? scaffoldGradient,
    Color? orbA,
    Color? orbB,
  }) {
    return BrandColors(
      surfaceTop: surfaceTop ?? this.surfaceTop,
      surfaceMid: surfaceMid ?? this.surfaceMid,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceCardAlpha: surfaceCardAlpha ?? this.surfaceCardAlpha,
      surfaceSheet: surfaceSheet ?? this.surfaceSheet,
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      textStrong: textStrong ?? this.textStrong,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textLabel: textLabel ?? this.textLabel,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      successFg: successFg ?? this.successFg,
      successBg: successBg ?? this.successBg,
      successBorder: successBorder ?? this.successBorder,
      warningFg: warningFg ?? this.warningFg,
      warningBg: warningBg ?? this.warningBg,
      warningBorder: warningBorder ?? this.warningBorder,
      scaffoldGradient: scaffoldGradient ?? this.scaffoldGradient,
      orbA: orbA ?? this.orbA,
      orbB: orbB ?? this.orbB,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      surfaceTop: Color.lerp(surfaceTop, other.surfaceTop, t)!,
      surfaceMid: Color.lerp(surfaceMid, other.surfaceMid, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      surfaceCardAlpha: Color.lerp(surfaceCardAlpha, other.surfaceCardAlpha, t)!,
      surfaceSheet: Color.lerp(surfaceSheet, other.surfaceSheet, t)!,
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      textStrong: Color.lerp(textStrong, other.textStrong, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textLabel: Color.lerp(textLabel, other.textLabel, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      successFg: Color.lerp(successFg, other.successFg, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      warningFg: Color.lerp(warningFg, other.warningFg, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t)!,
      scaffoldGradient: [
        for (var i = 0; i < scaffoldGradient.length; i++)
          Color.lerp(scaffoldGradient[i], other.scaffoldGradient[i], t)!,
      ],
      orbA: Color.lerp(orbA, other.orbA, t)!,
      orbB: Color.lerp(orbB, other.orbB, t)!,
    );
  }
}

extension BrandContext on BuildContext {
  /// Theme-aware brand palette for the current `Theme.of(context)`.
  /// Falls back to the light palette if the extension isn't registered
  /// (defensive, should not happen in production).
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ?? BrandColors.light;
}
