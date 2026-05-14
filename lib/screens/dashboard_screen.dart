import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/sales_provider.dart';
import '../widgets/summary_card.dart';
import 'add_entry_screen.dart';
import 'reports_screen.dart';
import 'profit_screen.dart';
import 'profit_screen.dart';
import 'shop_balances_screen.dart';
import 'expenses_screen.dart';
import '../providers/expense_provider.dart';

/// Dashboard screen - main home screen showing key stats
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: currencySymbol,
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().loadData();
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idly Express'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SalesProvider>().loadData();
              context.read<ExpenseProvider>().loadExpenses();
            },
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _deleteAllData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All Data'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SalesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Date
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      // Today's Sales
                      SummaryCard(
                        title: "Today's Sales",
                        value: _currencyFormat.format(provider.todayTotalSales),
                        icon: Icons.today,
                        iconColor: Theme.of(context).colorScheme.primary,
                      ),
                      // Today's Quantity
                      SummaryCard(
                        title: "Today's Items",
                        value: '${provider.todayTotalQuantity}',
                        icon: Icons.shopping_basket,
                        iconColor: Colors.orange,
                      ),
                      // Today's Profit
                      SummaryCard(
                        title: "Today's Profit",
                        value: _currencyFormat.format(provider.todayTotalProfit),
                        icon: Icons.trending_up,
                        iconColor: provider.todayTotalProfit >= 0
                            ? context.profitColor
                            : context.lossColor,
                        valueColor: provider.todayTotalProfit >= 0
                            ? context.profitColor
                            : context.lossColor,
                      ),
                      // Monthly Sales
                      SummaryCard(
                        title: "Month Sales",
                        value: _currencyFormat.format(provider.monthTotalSales),
                        icon: Icons.calendar_month,
                        iconColor: Colors.blue,
                      ),
                      // Month Expenses (New)
                      Consumer<ExpenseProvider>(
                        builder: (context, expenseProvider, _) => SummaryCard(
                          title: "Month Expenses",
                          value: _currencyFormat.format(expenseProvider.monthTotal),
                          icon: Icons.money_off,
                          iconColor: Colors.red,
                        ),
                      ),
                      // Month Net Profit (New)
                      Consumer<ExpenseProvider>(
                        builder: (context, expenseProvider, _) {
                          final netProfit = provider.monthTotalProfit - expenseProvider.monthTotal;
                          return SummaryCard(
                            title: "Month Net Profit",
                            value: _currencyFormat.format(netProfit),
                            icon: Icons.analytics,
                            iconColor: netProfit >= 0
                                ? context.profitColor
                                : context.lossColor,
                            valueColor: netProfit >= 0
                                ? context.profitColor
                                : context.lossColor,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      QuickActionButton(
                        label: 'Add Sale',
                        icon: Icons.add,
                        onTap: () => _navigateToAddEntry(),
                      ),
                      QuickActionButton(
                        label: 'Reports',
                        icon: Icons.bar_chart,
                        onTap: () => _navigateToReports(),
                        backgroundColor: Colors.blue,
                      ),
                      QuickActionButton(
                        label: 'Pending',
                        icon: Icons.pending_actions,
                        onTap: () => _navigateToShopBalances(),
                        backgroundColor: Colors.orange,
                      ),
                      QuickActionButton(
                        label: 'Expenses',
                        icon: Icons.receipt_long,
                        onTap: () => _navigateToExpenses(),
                        backgroundColor: Colors.redAccent,
                      ),
                      QuickActionButton(
                        label: 'Profit Analysis',
                        icon: Icons.insights,
                        onTap: () => _navigateToProfit(),
                        backgroundColor: context.profitColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Entries
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Entries",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: _navigateToReports,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (provider.todayEntries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 48,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No entries today',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _navigateToAddEntry,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Entry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.todayEntries.length,
                      itemBuilder: (context, index) {
                        final entry = provider.todayEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                entry.productType.displayName[0],
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(entry.shopName),
                            subtitle: Text(
                              '${entry.productType.displayName} • ${entry.quantity} pcs @ ${currencySymbol}${entry.ratePerUnit}',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _currencyFormat.format(entry.totalSalesAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Profit: ${_currencyFormat.format(entry.profit)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: entry.isProfitable
                                        ? context.profitColor
                                        : context.lossColor,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _showEntryDetails(entry),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddEntry,
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ),
    );
  }

  void _navigateToAddEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEntryScreen()),
    );
  }

  void _navigateToReports() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportsScreen()),
    );
  }

  void _navigateToProfit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfitScreen()),
    );
  }

  void _navigateToShopBalances() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShopBalancesScreen()),
    );
  }

  void _navigateToExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ExpensesScreen()),
    );
  }

  void _showEntryDetails(entry) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.shopName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Product', entry.productType.displayName),
            _buildDetailRow('Sale Type', entry.saleType.displayName),
            _buildDetailRow('Quantity', '${entry.quantity}'),
            _buildDetailRow('Rate', '$currencySymbol${entry.ratePerUnit}'),
            _buildDetailRow('Cost/Unit', '$currencySymbol${entry.costPerUnit}'),
            const Divider(),
            _buildDetailRow(
                'Total Sales', '$currencySymbol${entry.totalSalesAmount}'),
            _buildDetailRow('Total Cost', '$currencySymbol${entry.totalCost}'),
            _buildDetailRow(
              'Profit',
              '$currencySymbol${entry.profit}',
              valueColor:
                  entry.isProfitable ? context.profitColor : context.lossColor,
            ),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const Divider(),
              _buildDetailRow('Notes', entry.notes!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEntryScreen(editEntry: entry),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(entry.id!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.lossColor,
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<SalesProvider>().deleteEntry(id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.lossColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }



  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all sales data. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.lossColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SalesProvider>().deleteAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data deleted.')),
        );
      }
    }
  }
}
