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
                          
                          return Card(
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
                              trailing: Text(
                                currencyFormat.format(amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: context.lossColor,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                // TODO: Navigate to shop specific history
                              },
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
