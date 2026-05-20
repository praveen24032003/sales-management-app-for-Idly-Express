import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Pill-shaped chip for filtering and selection
/// Selected: gold bg + white text
/// Unselected: cream bg, gold border, gold text
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;

  const PillChip({
    required this.label,
    required this.selected,
    this.icon,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
  final isDark = context.isDark;

    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: selected
                ? primary
                : (isDark
                    ? AppColors.cardDark2
                    : AppColors.surfaceLight),
            border: Border.all(
              color: selected ? primary : primary,
              width: selected ? 0 : 1.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: selected ? Colors.white : primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
