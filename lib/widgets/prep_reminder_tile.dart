import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Tile displaying a prep reminder for an upcoming dispatch
class PrepReminderTile extends StatelessWidget {
  final dynamic entry;
  final int daysLeft;

  const PrepReminderTile({
    required this.entry,
    required this.daysLeft,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final urgentColor = daysLeft <= 1
        ? context.lossColor
        : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: urgentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.alarm_rounded,
              size: 18,
              color: urgentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.shopName} • ${entry.productType.displayName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Dispatch in $daysLeft day(s) · Qty: ${entry.quantity}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: urgentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              daysLeft == 1 ? 'Tomorrow' : '$daysLeft d',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: urgentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
