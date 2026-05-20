import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/theme_controller.dart';
import '../providers/sales_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_card.dart';
import 'expenses_screen.dart';
import 'shop_balances_screen.dart';
import 'profit_screen.dart';
import 'supply_templates_screen.dart';
import 'dispatch_planner_screen.dart';
import 'contacts_screen.dart';

/// More tab- settings, navigation, and data management
class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Money Section ────────────────────────────────────
              SectionHeader(
                title: 'Money',
              ),
              const SizedBox(height: AppSpacing.md),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.receipt_long_rounded,
                  label: 'Expenses',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ExpensesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Shop Balances',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ShopBalancesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Profit Trends',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ProfitScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Operations Section ────────────────────────────────
              SectionHeader(
                title: 'Operations',
              ),
              const SizedBox(height: AppSpacing.md),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.list_rounded,
                  label: 'Supply Templates',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SupplyTemplatesScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Dispatch Planner',
                  onTap: () => Navigator.of(context).pushNamed('/dispatch-planner'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.contacts_rounded,
                  label: 'Contacts',
                  onTap: () => Navigator.of(context).pushNamed('/contacts'),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── Data Section ──────────────────────────────────────
              SectionHeader(
                title: 'Data',
              ),
              const SizedBox(height: AppSpacing.md),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.download_rounded,
                  label: 'Export CSV',
                  onTap: () async {
                    final provider = context.read<SalesProvider>();
                    await provider.exportToCsv();
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.upload_rounded,
                  label: 'Import CSV',
                  onTap: () async {
                    // TODO: Implement file picker for CSV import (moved to separate method)
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ─── App Section ───────────────────────────────────────
              SectionHeader(
                title: 'App',
              ),
              const SizedBox(height: AppSpacing.md),
              Consumer<ThemeController>(
                builder: (context, themeController, _) {
                  return SoftCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                themeController.mode ==
                                        ThemeMode.dark
                                    ? Icons.dark_mode_rounded
                                    : themeController.mode ==
                                            ThemeMode.light
                                        ? Icons.light_mode_rounded
                                        : Icons.brightness_auto_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Theme',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge,
                              ),
                            ],
                          ),
                          DropdownButton<ThemeMode>(
                            value: themeController.mode,
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('System'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
                              ),
                            ],
                            onChanged: (mode) {
                              if (mode != null) {
                                themeController.setThemeMode(mode);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.info_rounded,
                  label: 'About',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Idly Express',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SoftCard(
                child: _MenuRow(
                  icon: Icons.delete_rounded,
                  label: 'Delete All Data',
                  isDestructive: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete All Data?'),
                        content: const Text(
                          'This will permanently delete all sales, expenses, and shop data. This action cannot be undone.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              final messenger = ScaffoldMessenger.of(context);
                              final provider =
                                  context.read<SalesProvider>();
                              final expProvider =
                                  context.read<ExpenseProvider>();
                              await provider.deleteAllData();
                              await expProvider.loadExpenses();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('All data has been deleted'),
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ─── Bottom spacing ────────────────────────────────────
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? context.lossColor
        : Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: color,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.subtleText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
