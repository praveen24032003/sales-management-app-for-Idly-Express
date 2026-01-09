import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/sales_entry_model.dart';
import '../providers/sales_provider.dart';
import '../widgets/summary_card.dart';
import 'add_entry_screen.dart';

/// Reports screen with tabs for daily, monthly, annual, shop-wise reports
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Filters
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedShop;
  SaleType? _selectedSaleType;
  ProductType? _selectedProduct;

  final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: currencySymbol,
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportData,
            tooltip: 'Export CSV',
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: _importData,
            tooltip: 'Import CSV',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mock') {
                _generateMockData();
              } else if (value == 'clear') {
                _deleteAllData();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mock',
                child: Text('Generate Mock Data'),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear All Data'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Monthly'),
            Tab(text: 'Annual'),
            Tab(text: 'Shop-wise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDailyReport(),
          _buildMonthlyReport(),
          _buildAnnualReport(),
          _buildShopWiseReport(),
        ],
      ),
    );
  }

  // ==================== DAILY REPORT ====================
  Widget _buildDailyReport() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            _buildDateFilter(),
            _buildFilterChips(),
            Expanded(
              child: FutureBuilder<List<SalesEntry>>(
                future: provider.getFilteredEntries(
                  startDate: _startDate,
                  endDate: _endDate,
                  shopName: _selectedShop,
                  saleType: _selectedSaleType,
                  productType: _selectedProduct,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final entries = snapshot.data ?? [];
                  return _buildEntriesList(entries);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ==================== MONTHLY REPORT ====================
  Widget _buildMonthlyReport() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        final monthEntries = provider.monthEntries;
        
        // Group by day
        final Map<int, List<SalesEntry>> byDay = {};
        for (final entry in monthEntries) {
          byDay.putIfAbsent(entry.date.day, () => []).add(entry);
        }

        final totalSales = monthEntries.fold<double>(0.0, (s, e) => s + e.totalSalesAmount);
        final totalQty = monthEntries.fold<int>(0, (s, e) => s + e.quantity);
        final totalCost = monthEntries.fold<double>(0.0, (s, e) => s + e.totalCost);
        final totalProfit = monthEntries.fold<double>(0.0, (s, e) => s + e.profit);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(totalSales, totalQty, totalCost, totalProfit),
              const SizedBox(height: 16),
              Text(
                'Daily Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...byDay.entries.map((e) {
                final daySales = e.value.fold<double>(0.0, (s, x) => s + x.totalSalesAmount);
                final dayProfit = e.value.fold<double>(0.0, (s, x) => s + x.profit);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('Day ${e.key}'),
                    subtitle: Text('${e.value.length} entries'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_currencyFormat.format(daySales)),
                        Text(
                          'Profit: ${_currencyFormat.format(dayProfit)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: dayProfit >= 0
                                ? context.profitColor
                                : context.lossColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ==================== ANNUAL REPORT ====================
  Widget _buildAnnualReport() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        final yearEntries = provider.yearEntries;
        
        // Group by month
        final Map<int, List<SalesEntry>> byMonth = {};
        for (final entry in yearEntries) {
          byMonth.putIfAbsent(entry.date.month, () => []).add(entry);
        }

        final totalSales = yearEntries.fold<double>(0.0, (s, e) => s + e.totalSalesAmount);
        final totalQty = yearEntries.fold<int>(0, (s, e) => s + e.quantity);
        final totalCost = yearEntries.fold<double>(0.0, (s, e) => s + e.totalCost);
        final totalProfit = yearEntries.fold<double>(0.0, (s, e) => s + e.profit);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Year ${DateTime.now().year}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(totalSales, totalQty, totalCost, totalProfit),
              const SizedBox(height: 16),
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...List.generate(12, (i) {
                final month = i + 1;
                final entries = byMonth[month] ?? [];
                if (entries.isEmpty) return const SizedBox.shrink();
                
                final monthSales = entries.fold<double>(0.0, (s, e) => s + e.totalSalesAmount);
                final monthProfit = entries.fold<double>(0.0, (s, e) => s + e.profit);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(DateFormat('MMMM').format(DateTime(2024, month))),
                    subtitle: Text('${entries.length} entries'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_currencyFormat.format(monthSales)),
                        Text(
                          'Profit: ${_currencyFormat.format(monthProfit)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: monthProfit >= 0
                                ? context.profitColor
                                : context.lossColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ==================== SHOP-WISE REPORT ====================
  Widget _buildShopWiseReport() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        final allEntries = provider.allEntries;
        
        // Group by shop
        final Map<String, List<SalesEntry>> byShop = {};
        for (final entry in allEntries) {
          byShop.putIfAbsent(entry.shopName, () => []).add(entry);
        }

        final shopStats = byShop.entries.map((e) {
          final sales = e.value.fold<double>(0.0, (s, x) => s + x.totalSalesAmount);
          final profit = e.value.fold<double>(0.0, (s, x) => s + x.profit);
          final qty = e.value.fold<int>(0, (s, x) => s + x.quantity);
          return {
            'name': e.key,
            'entries': e.value.length,
            'quantity': qty,
            'sales': sales,
            'profit': profit,
          };
        }).toList();

        // Sort by sales descending
        shopStats.sort((a, b) => (b['sales'] as double).compareTo(a['sales'] as double));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: shopStats.length,
          itemBuilder: (context, index) {
            final shop = shopStats[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            (shop['name'] as String)[0].toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${shop['entries']} entries • ${shop['quantity']} items',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Sales'),
                            Text(
                              _currencyFormat.format(shop['sales']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Total Profit'),
                            Text(
                              _currencyFormat.format(shop['profit']),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: (shop['profit'] as double) >= 0
                                    ? context.profitColor
                                    : context.lossColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton('From', _startDate, (date) {
              setState(() => _startDate = date);
            }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildDateButton('To', _endDate, (date) {
              setState(() => _endDate = date);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(DateFormat('dd/MM/yyyy').format(date)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<SalesProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Shop filter
              FilterChip(
                label: Text(_selectedShop ?? 'All Shops'),
                selected: _selectedShop != null,
                onSelected: (_) => _showShopPicker(provider.shopList),
              ),
              const SizedBox(width: 8),
              // Sale type filter
              FilterChip(
                label: Text(_selectedSaleType?.displayName ?? 'All Types'),
                selected: _selectedSaleType != null,
                onSelected: (_) => _showSaleTypePicker(),
              ),
              const SizedBox(width: 8),
              // Product filter
              FilterChip(
                label: Text(_selectedProduct?.displayName ?? 'All Products'),
                selected: _selectedProduct != null,
                onSelected: (_) => _showProductPicker(),
              ),
              const SizedBox(width: 8),
              // Clear filters
              if (_selectedShop != null ||
                  _selectedSaleType != null ||
                  _selectedProduct != null)
                ActionChip(
                  label: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _selectedShop = null;
                      _selectedSaleType = null;
                      _selectedProduct = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showShopPicker(List<String> shops) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Shops'),
            onTap: () {
              setState(() => _selectedShop = null);
              Navigator.pop(context);
            },
          ),
          ...shops.map((shop) => ListTile(
                title: Text(shop),
                onTap: () {
                  setState(() => _selectedShop = shop);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showSaleTypePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Types'),
            onTap: () {
              setState(() => _selectedSaleType = null);
              Navigator.pop(context);
            },
          ),
          ...SaleType.values.map((type) => ListTile(
                title: Text(type.displayName),
                onTap: () {
                  setState(() => _selectedSaleType = type);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Products'),
            onTap: () {
              setState(() => _selectedProduct = null);
              Navigator.pop(context);
            },
          ),
          ...ProductType.values.map((product) => ListTile(
                title: Text(product.displayName),
                onTap: () {
                  setState(() => _selectedProduct = product);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      double totalSales, int totalQty, double totalCost, double totalProfit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ReportSummaryRow(
              label: 'Total Items Sold',
              value: '$totalQty',
              icon: Icons.shopping_basket,
            ),
            ReportSummaryRow(
              label: 'Total Sales',
              value: _currencyFormat.format(totalSales),
              icon: Icons.attach_money,
            ),
            ReportSummaryRow(
              label: 'Total Cost',
              value: _currencyFormat.format(totalCost),
              icon: Icons.money_off,
            ),
            const Divider(),
            ReportSummaryRow(
              label: 'Total Profit',
              value: _currencyFormat.format(totalProfit),
              icon: Icons.trending_up,
              valueColor:
                  totalProfit >= 0 ? context.profitColor : context.lossColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(List<SalesEntry> entries) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No entries found'),
      );
    }

    final totalSales = entries.fold<double>(0.0, (s, e) => s + e.totalSalesAmount);
    final totalQty = entries.fold<int>(0, (s, e) => s + e.quantity);
    final totalCost = entries.fold<double>(0.0, (s, e) => s + e.totalCost);
    final totalProfit = entries.fold<double>(0.0, (s, e) => s + e.profit);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildSummaryCard(totalSales, totalQty, totalCost, totalProfit),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(entry.productType.displayName[0]),
                  ),
                  title: Text(entry.shopName),
                  subtitle: Text(
                    '${DateFormat('dd/MM').format(entry.date)} • ${entry.productType.displayName} • ${entry.quantity} pcs',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(entry.totalSalesAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'P: ${_currencyFormat.format(entry.profit)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: entry.isProfitable
                                ? context.profitColor
                                : context.lossColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEntryScreen(editEntry: entry),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==================== EXPORT/IMPORT ====================

  Future<void> _exportData() async {
    try {
      final provider = context.read<SalesProvider>();
      final csv = await provider.exportToCsv();
      
      // Save to temp file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/idly_express_backup.csv');
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Idly Express Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: context.lossColor,
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        
        final provider = context.read<SalesProvider>();
        final count = await provider.importFromCsv(content);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $count entries'),
              backgroundColor: context.profitColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: context.lossColor,
          ),
        );
      }
    }
  }

  Future<void> _generateMockData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Mock Data?'),
        content: const Text('This will add random sales data for the last 90 days. Useful for testing reports.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<SalesProvider>().generateMockData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Mock data generated!'), backgroundColor: context.profitColor),
        );
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all sales and shop data. This action cannot be undone.'),
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
