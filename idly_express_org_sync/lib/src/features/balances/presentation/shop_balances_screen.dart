import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/brand_widgets.dart';
import '../../../domain/sales_entry.dart';
import '../../workspace/application/workspace_data_controller.dart';

class ShopBalancesScreen extends StatefulWidget {
  const ShopBalancesScreen({
    super.key,
    required this.workspace,
  });

  final WorkspaceDataController workspace;

  @override
  State<ShopBalancesScreen> createState() => _ShopBalancesScreenState();
}

enum _BalanceSortMode { highestDue, oldest, alphabetical }

class _ShopBalancesScreenState extends State<ShopBalancesScreen> {
  final TextEditingController _searchController = TextEditingController();
  _BalanceSortMode _sortMode = _BalanceSortMode.highestDue;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_PendingShopBalance> _visibleBalances(List<SalesEntry> sales) {
    final balances = _buildBalances(sales);
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? balances
        : balances.where((item) => item.shopName.toLowerCase().contains(query)).toList();

    switch (_sortMode) {
      case _BalanceSortMode.highestDue:
        filtered.sort((left, right) {
          final amount = right.pendingAmount.compareTo(left.pendingAmount);
          if (amount != 0) {
            return amount;
          }
          return left.shopName.toLowerCase().compareTo(right.shopName.toLowerCase());
        });
      case _BalanceSortMode.oldest:
        filtered.sort((left, right) {
          final oldest = left.oldestDate.compareTo(right.oldestDate);
          if (oldest != 0) {
            return oldest;
          }
          return right.pendingAmount.compareTo(left.pendingAmount);
        });
      case _BalanceSortMode.alphabetical:
        filtered.sort((left, right) => left.shopName.toLowerCase().compareTo(right.shopName.toLowerCase()));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.workspace,
      builder: (context, _) {
        final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
        final brand = context.brand;
        final balances = _visibleBalances(widget.workspace.sales);
        final totalPending = balances.fold<double>(0, (sum, item) => sum + item.pendingAmount);

        return Scaffold(
          backgroundColor: brand.surfaceTop,
          appBar: AppBar(
            title: const Text('Pending Collections'),
            backgroundColor: brand.surfaceCard,
            foregroundColor: brand.textStrong,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: brand.border),
            ),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: BrandTokens.scaffoldGradient(context)),
            child: widget.workspace.isLoading
              ? const Center(child: CircularProgressIndicator())
              : balances.isEmpty
                  ? BrandEmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No pending payments',
                      message: _searchController.text.trim().isEmpty
                          ? 'All open sales are fully settled for this organization.'
                          : 'No shops match your current search.',
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      children: [
                        BrandCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const BrandSectionHeader(
                                title: 'Pending Collections',
                                subtitle: 'Track due amounts, filter shops quickly, and record payments from one place.',
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _SummaryPill(
                                    label: 'Outstanding balance',
                                    value: currency.format(totalPending),
                                    accent: BrandTokens.accentOutstanding,
                                  ),
                                  _SummaryPill(
                                    label: 'Open shops',
                                    value: '${balances.length}',
                                    accent: BrandTokens.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                '${balances.length} shops still have pending collections.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: brand.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        BrandCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FilterSectionLabel(label: 'Quick filters'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Search shop',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _searchController.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.close_rounded),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _BalanceFilterChip(
                                      label: 'Highest due',
                                      selected: _sortMode == _BalanceSortMode.highestDue,
                                      onTap: () => setState(() => _sortMode = _BalanceSortMode.highestDue),
                                    ),
                                    const SizedBox(width: 8),
                                    _BalanceFilterChip(
                                      label: 'Oldest',
                                      selected: _sortMode == _BalanceSortMode.oldest,
                                      onTap: () => setState(() => _sortMode = _BalanceSortMode.oldest),
                                    ),
                                    const SizedBox(width: 8),
                                    _BalanceFilterChip(
                                      label: 'A-Z',
                                      selected: _sortMode == _BalanceSortMode.alphabetical,
                                      onTap: () => setState(() => _sortMode = _BalanceSortMode.alphabetical),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...balances.map(
                          (balance) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PendingBalanceCard(
                              balance: balance,
                              currency: currency,
                              onCollect: () => _recordPayment(context, balance),
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        );
      },
    );
  }

  List<_PendingShopBalance> _buildBalances(List<SalesEntry> sales) {
    final grouped = <String, List<SalesEntry>>{};
    for (final sale in sales) {
      if (sale.pendingAmount <= 0.1) {
        continue;
      }
      grouped.putIfAbsent(sale.shopName, () => <SalesEntry>[]).add(sale);
    }

    final balances = grouped.entries.map((entry) {
      final openSales = entry.value
        ..sort((left, right) => left.date.compareTo(right.date));
      final oldestDate = openSales.first.date;
      final pendingAmount = openSales.fold<double>(0, (sum, sale) => sum + sale.pendingAmount);
      return _PendingShopBalance(
        shopName: entry.key,
        pendingAmount: pendingAmount,
        openEntries: openSales.length,
        oldestDate: oldestDate,
      );
    }).toList();
    return balances;
  }

  Future<void> _recordPayment(BuildContext context, _PendingShopBalance balance) async {
    final controller = TextEditingController(text: balance.pendingAmount.toStringAsFixed(0));
    String? validationMessage;
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

    final paidAmount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Receive payment', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(balance.shopName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Pending: ${currency.format(balance.pendingAmount)}'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Paid amount',
                      errorText: validationMessage,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text.trim());
                        if (value == null || value <= 0) {
                          setModalState(() => validationMessage = 'Enter a valid amount');
                          return;
                        }
                        if (value > balance.pendingAmount) {
                          setModalState(() => validationMessage = 'Amount cannot exceed pending balance');
                          return;
                        }
                        Navigator.of(context).pop(value);
                      },
                      child: const Text('Save payment'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (paidAmount == null || !context.mounted) {
      return;
    }

    await widget.workspace.applyPaymentToShopPending(balance.shopName, paidAmount);
    if (!context.mounted) {
      return;
    }

    if (widget.workspace.errorMessage == null) {
      final remaining = (balance.pendingAmount - paidAmount).clamp(0, double.infinity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining == 0
                ? '${balance.shopName} fully settled'
                : '${balance.shopName} payment saved. Remaining ${currency.format(remaining)}',
          ),
        ),
      );
    }
  }
}

class _PendingBalanceCard extends StatelessWidget {
  const _PendingBalanceCard({
    required this.balance,
    required this.currency,
    required this.onCollect,
  });

  final _PendingShopBalance balance;
  final NumberFormat currency;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return BrandCard(
      onTap: onCollect,
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shouldStackAction = constraints.maxWidth < 360;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: BrandTokens.accentOutstanding.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.storefront_outlined, color: BrandTokens.accentOutstanding),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          balance.shopName,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${balance.openEntries} open entries • Oldest ${DateFormat('dd MMM yyyy').format(balance.oldestDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: brand.textMuted, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currency.format(balance.pendingAmount),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: brand.textStrong),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pending',
                        style: theme.textTheme.labelMedium?.copyWith(color: brand.textMuted, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (shouldStackAction) ...[
                _PendingHintCard(brand: brand, theme: theme),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: onCollect,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Collect'),
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _PendingHintCard(brand: brand, theme: theme)),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onCollect,
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Collect'),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PendingHintCard extends StatelessWidget {
  const _PendingHintCard({required this.brand, required this.theme});

  final BrandColors brand;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: brand.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Text(
        'Record a payment for this shop using Collect.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: brand.textBody,
          height: 1.4,
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: brand.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: brand.textStrong, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.brand.textMuted,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _BalanceFilterChip extends StatelessWidget {
  const _BalanceFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? BrandTokens.primary.withValues(alpha: 0.18) : brand.surfaceSoft,
            border: Border.all(
              color: selected ? BrandTokens.primary.withValues(alpha: 0.45) : brand.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? BrandTokens.primaryDeep : brand.textBody,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingShopBalance {
  const _PendingShopBalance({
    required this.shopName,
    required this.pendingAmount,
    required this.openEntries,
    required this.oldestDate,
  });

  final String shopName;
  final double pendingAmount;
  final int openEntries;
  final DateTime oldestDate;
}