import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Soft card wrapper with drop shadow and optional gradient
/// Used as a container for form sections, summaries, and lists
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;

  const SoftCard({
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final effectiveColor = color ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);

    final card = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? effectiveColor : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: isDark
            ? Border.all(
                color: AppColors.borderDark,
                width: 1,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: card,
        ),
      );
    }

    return card;
  }
}
