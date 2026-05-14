import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

/// Expense Provider
class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  bool _isLoading = false;
  String? _error;
  
  List<Expense> _monthExpenses = [];
  double _todayTotal = 0;
  double _monthTotal = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Expense> get monthExpenses => _monthExpenses;
  double get todayTotal => _todayTotal;
  double get monthTotal => _monthTotal;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      
      // Load current month expenses
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      _monthExpenses = await _db.getExpensesByDateRange(startOfMonth, endOfMonth);
      _monthTotal = _monthExpenses.fold(0, (sum, e) => sum + e.amount);

      // Calculate today's total
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todayExpenses = await _db.getExpensesByDateRange(startOfDay, endOfDay);
      _todayTotal = todayExpenses.fold(0, (sum, e) => sum + e.amount);

    } catch (e) {
      _error = 'Failed to load expenses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      await _db.insertExpense(expense);
      await loadExpenses();
      SyncService.instance.syncAll();
      return true;
    } catch (e) {
      _error = 'Failed to add expense: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(int id) async {
    try {
      await _db.deleteExpense(id);
      await loadExpenses();
      SyncService.instance.syncAll();
      return true;
    } catch (e) {
      _error = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }
}
