import 'package:flutter/foundation.dart';
import '../core/constants.dart';
import '../models/sales_entry_model.dart';
import '../models/supply_template_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';


/// Sales Provider - State management for the app
class SalesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  // State
  List<SalesEntry> _allEntries = [];
  List<SalesEntry> _todayEntries = [];
  List<SalesEntry> _monthEntries = [];
  List<SalesEntry> _yearEntries = [];
  List<SupplyTemplate> _supplyTemplates = [];
  List<String> _shopList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SalesEntry> get allEntries => _allEntries;
  List<SalesEntry> get todayEntries => _todayEntries;
  List<SalesEntry> get monthEntries => _monthEntries;
  List<SalesEntry> get yearEntries => _yearEntries;
  List<SupplyTemplate> get supplyTemplates => _supplyTemplates;
  List<String> get shopList => _shopList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isDateWithinDays(DateTime date, int daysFromToday) {
    final today = _dateOnly(DateTime.now());
    final target = today.add(Duration(days: daysFromToday));
    return _dateOnly(date) == target;
  }

  List<SalesEntry> get todayEverydaySupplyEntries =>
      _todayEntries.where((e) => e.orderType == OrderType.everydaySupply).toList();

  List<SalesEntry> get todayExternalOrders =>
      _todayEntries.where((e) => e.orderType == OrderType.externalOrder).toList();

  List<SalesEntry> get prepReminderEntries {
    final today = _dateOnly(DateTime.now());
    return _allEntries.where((entry) {
      final dispatchDate = _dateOnly(entry.date);
      final daysUntilDispatch = dispatchDate.difference(today).inDays;
      return daysUntilDispatch >= 1 &&
          daysUntilDispatch <= 2 &&
          daysUntilDispatch <= entry.prepLeadDays;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  int get prepQuantityForTomorrow => _allEntries
      .where((e) => _isDateWithinDays(e.date, 1) && e.prepLeadDays >= 1)
      .fold<int>(0, (sum, e) => sum + e.quantity);

  int get prepQuantityForDayAfterTomorrow => _allEntries
      .where((e) => _isDateWithinDays(e.date, 2) && e.prepLeadDays >= 2)
      .fold<int>(0, (sum, e) => sum + e.quantity);

  // ==================== DASHBOARD STATS ====================

  // Today's stats
  double get todayTotalSales =>
      _todayEntries.fold<double>(0.0, (sum, e) => sum + e.totalSalesAmount);
  int get todayTotalQuantity =>
      _todayEntries.fold<int>(0, (sum, e) => sum + e.quantity);
  double get todayTotalProfit =>
      _todayEntries.fold<double>(0.0, (sum, e) => sum + e.profit);
  double get todayTotalCost =>
      _todayEntries.fold<double>(0.0, (sum, e) => sum + e.totalCost);

  // Monthly stats
  double get monthTotalSales =>
      _monthEntries.fold<double>(0.0, (sum, e) => sum + e.totalSalesAmount);
  int get monthTotalQuantity =>
      _monthEntries.fold<int>(0, (sum, e) => sum + e.quantity);
  double get monthTotalProfit =>
      _monthEntries.fold<double>(0.0, (sum, e) => sum + e.profit);
  double get monthTotalCost =>
      _monthEntries.fold<double>(0.0, (sum, e) => sum + e.totalCost);

  // Annual stats
  double get yearTotalSales =>
      _yearEntries.fold<double>(0.0, (sum, e) => sum + e.totalSalesAmount);
  int get yearTotalQuantity =>
      _yearEntries.fold<int>(0, (sum, e) => sum + e.quantity);
  double get yearTotalProfit =>
      _yearEntries.fold<double>(0.0, (sum, e) => sum + e.profit);
  double get yearTotalCost =>
      _yearEntries.fold<double>(0.0, (sum, e) => sum + e.totalCost);

  // Total Pending Amount (across all entries)
  double get totalPendingAmount =>
      _allEntries.fold<double>(0.0, (sum, e) => sum + e.pendingAmount);

  Future<Map<String, double>> getAllPendingAmounts() async {
    return await _db.getAllPendingAmounts();
  }

  // ==================== PROFIT ANALYSIS ====================

  // Wholesale vs Retail profit comparison
  double get wholesaleProfit => _yearEntries
      .where((e) => e.saleType == SaleType.wholesale)
      .fold<double>(0.0, (sum, e) => sum + e.profit);

  double get retailProfit => _yearEntries
      .where((e) => e.saleType == SaleType.retail)
      .fold<double>(0.0, (sum, e) => sum + e.profit);

  // Monthly profit breakdown for charts
  Map<int, double> get monthlyProfits {
    final now = DateTime.now();
    final Map<int, double> profits = {};
    
    for (int i = 1; i <= 12; i++) {
      profits[i] = _yearEntries
          .where((e) => e.date.month == i && e.date.year == now.year)
          .fold<double>(0.0, (sum, e) => sum + e.profit);
    }
    return profits;
  }

  // Daily profit for current month
  Map<int, double> get dailyProfitsThisMonth {
    final now = DateTime.now();
    final Map<int, double> profits = {};
    
    for (final entry in _monthEntries) {
      if (entry.date.month == now.month && entry.date.year == now.year) {
        profits[entry.date.day] = (profits[entry.date.day] ?? 0) + entry.profit;
      }
    }
    return profits;
  }

  // ==================== DATA OPERATIONS ====================

  /// Initialize and load all data
  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.autoCreateTodaySupplyOrdersIfNeeded();
      _allEntries = await _db.getAllEntries();
      _todayEntries = await _db.getTodayEntries();
      _monthEntries = await _db.getCurrentMonthEntries();
      _yearEntries = await _db.getCurrentYearEntries();
      _supplyTemplates = await _db.getAllSupplyTemplates();
      _shopList = await _db.getAllShops();
    } catch (e) {
      _error = 'Failed to load data: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new sales entry
  Future<bool> addEntry(SalesEntry entry) async {
    try {
      await _db.insertSalesEntry(entry);
      await loadData(); // Refresh all data
      SyncService.instance.syncAll(); // Trigger sync
      return true;
    } catch (e) {
      _error = 'Failed to add entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing entry
  Future<bool> updateEntry(SalesEntry entry) async {
    try {
      await _db.updateSalesEntry(entry);
      await loadData();
      SyncService.instance.syncAll();
      return true;
    } catch (e) {
      _error = 'Failed to update entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(int id) async {
    try {
      await _db.deleteSalesEntry(id);
      await loadData();
      SyncService.instance.syncAll();
      return true;
    } catch (e) {
      _error = 'Failed to delete entry: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get shop suggestions for autocomplete
  Future<List<String>> getShopSuggestions(String query) async {
    if (query.isEmpty) return _shopList.take(5).toList();
    return await _db.getShopSuggestions(query);
  }

  /// Get entries by filters
  Future<List<SalesEntry>> getFilteredEntries({
    DateTime? startDate,
    DateTime? endDate,
    String? shopName,
    SaleType? saleType,
    ProductType? productType,
  }) async {
    List<SalesEntry> entries = _allEntries;

    if (startDate != null) {
      entries = entries.where((e) => !e.date.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      entries = entries.where((e) => !e.date.isAfter(endDate)).toList();
    }
    if (shopName != null && shopName.isNotEmpty) {
      entries = entries.where((e) => e.shopName == shopName).toList();
    }
    if (saleType != null) {
      entries = entries.where((e) => e.saleType == saleType).toList();
    }
    if (productType != null) {
      entries = entries.where((e) => e.productType == productType).toList();
    }

    return entries;
  }

  // ==================== CSV OPERATIONS ====================

  /// Export data to CSV
  Future<String> exportToCsv() async {
    return await _db.exportToCsv();
  }

  /// Import data from CSV
  Future<int> importFromCsv(String csvContent) async {
    final count = await _db.importFromCsv(csvContent);
    if (count > 0) {
      await loadData();
    }
    return count;
  }

  /// Delete all data
  Future<void> deleteAllData() async {
    await _db.deleteAllData();
    await loadData();
  }

  // ==================== RECURRING TEMPLATES ====================

  Future<bool> addSupplyTemplate(SupplyTemplate template) async {
    try {
      await _db.insertSupplyTemplate(template);
      await loadData();
      return true;
    } catch (e) {
      _error = 'Failed to add template: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplyTemplate(SupplyTemplate template) async {
    try {
      await _db.updateSupplyTemplate(template);
      await loadData();
      return true;
    } catch (e) {
      _error = 'Failed to update template: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplyTemplate(int id) async {
    try {
      await _db.deleteSupplyTemplate(id);
      await loadData();
      return true;
    } catch (e) {
      _error = 'Failed to delete template: $e';
      notifyListeners();
      return false;
    }
  }



  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
