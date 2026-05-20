import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'home_tab.dart';
import 'orders_tab.dart';
import 'reports_screen.dart';
import 'more_tab.dart';

/// Main shell for the app with bottom nav and FAB-notched center
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onSwitchTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeTab(onSwitchTab: _onSwitchTab),
          OrdersTab(onSwitchTab: _onSwitchTab),
          ReportsScreen(),
          MoreTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/add-entry');
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onChanged: _onTabChanged,
        items: [
          BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
          BottomNavItem(icon: Icons.shopping_cart_rounded, label: 'Orders'),
          BottomNavItem(icon: Icons.assessment_rounded, label: 'Reports'),
          BottomNavItem(icon: Icons.more_horiz_rounded, label: 'More'),
        ],
      ),
    );
  }
}
