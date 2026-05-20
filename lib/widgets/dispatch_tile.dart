import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

/// Tile displaying a sales entry dispatch information
class DispatchTile extends StatelessWidget {
  final dynamic entry;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const DispatchTile({
    required this.entry,
    required this.currencyFormat,
    required this.onTap,
    super.key,
  });

  Color _accentColor() {
    switch (entry.orderType.index) {
      case 0:
        return const Color(0xFF00897B); // Supply
      case 1:
        return const Color(0xFF5E35B1); // External
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final accent = _accentColor();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(color: accent, width: 3),
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              right: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    size: 18,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.shopName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${entry.productType.displayName} · ${entry.quantity} pcs',
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(entry.totalSalesAmount),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.paymentStatus.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: entry.isFullyPaid
                            ? context.profitColor
                            : context.lossColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
