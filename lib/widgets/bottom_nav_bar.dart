import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Custom bottom navigation bar with 4 items and notched center for FAB
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final List<BottomNavItem> items;

  const BottomNavBar({
    required this.selectedIndex,
    required this.onChanged,
    required this.items,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return BottomAppBar(
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      height: 72,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left 2 items
          Row(
            children: [
              _NavItem(
                icon: items[0].icon,
                label: items[0].label,
                isSelected: selectedIndex == 0,
                onTap: () => onChanged(0),
              ),
              _NavItem(
                icon: items[1].icon,
                label: items[1].label,
                isSelected: selectedIndex == 1,
                onTap: () => onChanged(1),
              ),
            ],
          ),
          // Center notch (for FAB)
          SizedBox(width: 48),
          // Right 2 items
          Row(
            children: [
              _NavItem(
                icon: items[2].icon,
                label: items[2].label,
                isSelected: selectedIndex == 2,
                onTap: () => onChanged(2),
              ),
              _NavItem(
                icon: items[3].icon,
                label: items[3].label,
                isSelected: selectedIndex == 3,
                onTap: () => onChanged(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = context.subtleText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? primary : secondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primary : secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;

  BottomNavItem({required this.icon, required this.label});
}
