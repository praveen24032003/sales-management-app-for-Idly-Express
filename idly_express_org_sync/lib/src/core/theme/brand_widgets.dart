import 'package:flutter/material.dart';

import 'brand_tokens.dart';

/// Soft branded scaffold background — gradient + optional glow orbs.
class BrandScaffold extends StatelessWidget {
  const BrandScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.showOrbs = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
        child: Stack(
          children: [
            if (showOrbs) ...[
              Positioned(top: -50, right: -30, child: _GlowOrb(color: brand.orbA, size: 200)),
              Positioned(bottom: -60, left: -40, child: _GlowOrb(color: brand.orbB, size: 220)),
            ],
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.04)]),
        ),
      ),
    );
  }
}

/// Standard branded card surface (translucent, branded border) that adapts
/// to light or dark theme.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final content = Padding(padding: padding, child: child);
    return Material(
      color: brand.surfaceCardAlpha,
      borderRadius: BorderRadius.circular(BrandTokens.radiusCard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BrandTokens.radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BrandTokens.radiusCard),
            border: Border.all(color: brand.border),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Idly Express wordmark — pure-Flutter, scales cleanly.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.size = 28,
    this.showTagline = false,
  });

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BrandGlyph(size: size + 8),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Idly Express',
              style: TextStyle(
                color: brand.textStrong,
                fontWeight: FontWeight.w900,
                fontSize: size * 0.72,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              Text(
                'Branch workspace',
                style: TextStyle(
                  color: brand.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.34,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Idly Express glyph — the brand idli logo on a soft white badge so it reads
/// cleanly on both white app bars and tinted gradient surfaces.
class BrandGlyph extends StatelessWidget {
  const BrandGlyph({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: BrandTokens.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.1),
        child: Image.asset('assets/branding/logo_glyph.png', fit: BoxFit.contain),
      ),
    );
  }
}

/// Standardized empty-state for tabs.
class BrandEmptyState extends StatelessWidget {
  const BrandEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: BoxDecoration(
                  color: brand.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 36, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: brand.textMuted, height: 1.5),
              ),
              if (action != null) ...[
                const SizedBox(height: 18),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header used in feature tabs.
class BrandSectionHeader extends StatelessWidget {
  const BrandSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(color: brand.textMuted, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
