import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date chip displaying today's date
class DateChip extends StatelessWidget {
  const DateChip({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final label = DateFormat('EEEE, d MMMM yyyy').format(now);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
