import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../widgets/soft_card.dart';

/// Screen to show pending balances for all shops
class ShopBalancesScreen extends StatefulWidget {
  const ShopBalancesScreen({super.key});

  @override
  State<ShopBalancesScreen> createState() => _ShopBalancesScreenState();
}

class _ShopBalancesScreenState extends State<ShopBalancesScreen> {
  Map<String, double> _pendingMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final map = await context.read<SalesProvider>().getAllPendingAmounts();
      setState(() => _pendingMap = map);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recordPayment(String shopName, double pendingAmount) async {
    final provider = context.read<SalesProvider>();
    final controller = TextEditingController(text: pendingAmount.toStringAsFixed(0));
    String? validationMessage;

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
                  Text(shopName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Pending: ${NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol, decimalDigits: 2).format(pendingAmount)}'),
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
                        if (value > pendingAmount) {
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

    if (paidAmount == null || !mounted) return;

    final success = await provider.applyPaymentToShopPending(shopName, paidAmount);
    if (!mounted) return;

    if (success) {
      await _loadData();
      if (!mounted) return;
      final remaining = (pendingAmount - paidAmount).clamp(0, double.infinity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining == 0
                ? '$shopName fully settled'
                : '$shopName payment saved. Remaining ${NumberFormat.currency(locale: 'en_IN', symbol: currencySymbol, decimalDigits: 2).format(remaining)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    final totalPending = _pendingMap.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingMap.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No pending payments!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                            // Total Summary
                            SoftCard(
                      padding: const EdgeInsets.all(24),
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          Text(
                            'Total Pending',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currencyFormat.format(totalPending),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.lossColor,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    
                    // Shop List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingMap.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final shopName = _pendingMap.keys.elementAt(index);
                          final amount = _pendingMap[shopName]!;

                          return Dismissible(
                            key: ValueKey('pending_$shopName'),
                            direction: DismissDirection.startToEnd,
                            confirmDismiss: (_) async {
                              await _recordPayment(shopName, amount);
                              return false;
                            },
                            background: Container(
                              decoration: BoxDecoration(
                                color: context.profitColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.payments_rounded, color: Colors.white),
                            ),
                            child: Card(
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: context.lossColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.store, color: context.lossColor),
                                ),
                                title: Text(
                                  shopName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text('Tap or swipe right to record payment'),
                                trailing: Text(
                                  currencyFormat.format(amount),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.lossColor,
                                    fontSize: 16,
                                  ),
                                ),
                                onTap: () => _recordPayment(shopName, amount),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
