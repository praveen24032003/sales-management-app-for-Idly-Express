import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../widgets/pill_chip.dart';
import '../widgets/soft_card.dart';
import '../widgets/dispatch_tile.dart';

/// Orders tab - full list of dispatch orders with filtering
class OrdersTab extends StatefulWidget {
  final Function(int) onSwitchTab;

  const OrdersTab({required this.onSwitchTab, super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late final NumberFormat _currencyFormat;
  String _typeFilter = 'All';
  String _rangeFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 2,
    );
  }

  List<dynamic> _getFilteredEntries(List<dynamic> entries) {
    var filtered = entries.toList();

    // Date range filter
    final now = DateTime.now();
    if (_rangeFilter == 'Today') {
      filtered = filtered
          .where((e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day)
          .toList();
    } else if (_rangeFilter == 'This Week') {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      filtered = filtered
          .where((e) =>
              e.date.isAfter(weekStart) &&
              e.date.isBefore(now.add(const Duration(days: 1))))
          .toList();
    } else if (_rangeFilter == 'This Month') {
      filtered = filtered
          .where((e) =>
              e.date.year == now.year && e.date.month == now.month)
          .toList();
    }

    // Order type filter
    if (_typeFilter != 'All') {
      filtered = filtered
          .where((e) => e.orderType.displayName == _typeFilter)
          .toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) =>
              e.shopName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              e.productType.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        elevation: 0,
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, _) {
          final filtered = _getFilteredEntries(provider.allEntries);

          return SingleChildScrollView(
            child: Column(
              children: [
                // ─── Search ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                ),

                // ─── Type Filters ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PillChip(
                          label: 'All',
                          selected: _typeFilter == 'All',
                          onTap: () =>
                              setState(() => _typeFilter = 'All'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        PillChip(
                          label: 'Supply',
                          selected: _typeFilter == 'Supply',
                          onTap: () =>
                              setState(() => _typeFilter = 'Supply'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        PillChip(
                          label: 'External',
                          selected: _typeFilter == 'External',
                          onTap: () =>
                              setState(() => _typeFilter = 'External'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ─── Date Range Filters ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PillChip(
                          label: 'All',
                          selected: _rangeFilter == 'All',
                          onTap: () =>
                              setState(() => _rangeFilter = 'All'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        PillChip(
                          label: 'Today',
                          selected: _rangeFilter == 'Today',
                          onTap: () =>
                              setState(() => _rangeFilter = 'Today'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        PillChip(
                          label: 'This Week',
                          selected: _rangeFilter == 'This Week',
                          onTap: () =>
                              setState(() => _rangeFilter = 'This Week'),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        PillChip(
                          label: 'This Month',
                          selected: _rangeFilter == 'This Month',
                          onTap: () =>
                              setState(() => _rangeFilter = 'This Month'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ─── Orders List ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: filtered.isEmpty
                      ? SoftCard(
                          child: Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 32),
                              child: Text(
                                'No orders found',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ...filtered.map((entry) => Padding(
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
                                )),
                          ],
                        ),
                ),

                // ─── Bottom spacing for notched nav ────────────────
                const SizedBox(height: 96),
              ],
            ),
          );
        },
      ),
    );
  }
}
