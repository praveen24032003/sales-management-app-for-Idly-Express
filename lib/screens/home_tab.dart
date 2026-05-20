import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/hero_card.dart';
import '../widgets/section_header.dart';
import '../widgets/soft_card.dart';
import '../widgets/dispatch_tile.dart';
import '../widgets/prep_reminder_tile.dart';

import '../widgets/time_greeting_hero.dart';

/// Home tab - slim dashboard view
class HomeTab extends StatefulWidget {
  final Function(int) onSwitchTab;

  const HomeTab({required this.onSwitchTab, super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 2,
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<SalesProvider, ExpenseProvider>(
        builder: (context, provider, expProv, _) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.loadData();
              if (mounted) {
                await expProv.loadExpenses();
              }
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ─── Cream AppBar removed — using TimeGreetingHero instead ───
                // ─── Animated Time-of-Day Hero ─────────────────────
                SliverToBoxAdapter(
                  child: TimeGreetingHero(),
                ),
                // ─── Quick Actions ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add_shopping_cart_rounded,
                            label: 'External Order',
                            color: Theme.of(context).colorScheme.primary,
                            onTap: () => Navigator.of(context).pushNamed('/external-order'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.local_shipping_rounded,
                            label: 'Dispatch Plan',
                            color: const Color(0xFF059669),
                            onTap: () => Navigator.of(context).pushNamed('/dispatch-planner'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ─── Content ───────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      // ─── Hero Card: Today's Net ────────────────────
                      HeroCard(
                        label: "Today's Net",
                        value: _currencyFormat.format(
                          provider.todayTotalProfit -
                              expProv.todayTotal,
                        ),
                        deltaLabel: provider.todayEntries.isNotEmpty
                            ? '+${provider.todayEntries.length} entries'
                            : 'No entries',
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ─── Row of 3 small stats ──────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: SoftCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sales',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _currencyFormat.format(
                                      provider.todayTotalSales,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SoftCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Items',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    '${provider.todayEntries.fold<int>(0, (sum, e) => sum + e.quantity)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: SoftCard(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Profit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    _currencyFormat.format(
                                      provider.todayTotalProfit,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: context.profitColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // ─── Prep Reminders ────────────────────────────
                      if (provider.prepReminderEntries.isNotEmpty) ...[
                        SectionHeader(
                          title: 'Prep Reminders',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...provider.prepReminderEntries.map((entry) {
                            final daysLeft = entry.date
                              .difference(DateTime.now())
                              .inDays;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: PrepReminderTile(
                              entry: entry,
                              daysLeft: daysLeft,
                            ),
                          );
                        }),
                        const SizedBox(height: AppSpacing.xl),
                      ],

                      // ─── Today's Dispatch ──────────────────────────
                      SectionHeader(
                        title: "Today's Dispatch",
                        trailing: TextButton(
                          onPressed: () => widget.onSwitchTab(1),
                          child: const Text('View all'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (provider.todayEntries.isNotEmpty)
                        ...provider.todayEntries
                            .take(3)
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: DispatchTile(
                                    entry: entry,
                                    currencyFormat: _currencyFormat,
                                    onTap: () {
                                      // Navigate to detail or edit
                                    },
                                  ),
                                ))
                      else
                        SoftCard(
                          child: Center(
                            child: Text(
                              'No dispatch today',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                            ),
                          ),
                        ),

                      // ─── Bottom spacing for notched nav ────────────
                      const SizedBox(height: 96),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
