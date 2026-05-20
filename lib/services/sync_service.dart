import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';

/// Service to handle synchronization between local SQLite and Firestore
class SyncService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton
  static final SyncService instance = SyncService._init();
  SyncService._init() {
    _initConnectivity();
  }

  bool _isOnline = false;
  bool _isSyncing = false;
  String? _lastError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  // Collections
  CollectionReference get _salesCollection => _firestore.collection('sales');
  CollectionReference get _expensesCollection => _firestore.collection('expenses');

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((dynamic result) {
      bool isConnected = false;
      if (result is List<ConnectivityResult>) {
        isConnected = result.contains(ConnectivityResult.mobile) || 
                      result.contains(ConnectivityResult.wifi);
      } else if (result is ConnectivityResult) {
        isConnected = result == ConnectivityResult.mobile || 
                      result == ConnectivityResult.wifi;
      }
      
      if (isConnected && !_isOnline) {
        _isOnline = true;
        syncAll(); // Auto-sync when back online
      } else if (!isConnected) {
        _isOnline = false;
      }
      notifyListeners();
    });
  }

  Future<void> syncAll() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _pushSales();
      await _pushExpenses();
      // Pull logic can be added here if multi-device sync is needed
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _pushSales() async {
    final unsynced = await _db.getUnsyncedSales();
    if (unsynced.isEmpty) return;

    for (final entry in unsynced) {
      try {
        final docRef = entry.firestoreId != null 
            ? _salesCollection.doc(entry.firestoreId)
            : _salesCollection.doc(); // New ID
        
        await docRef.set(entry.toMap()..remove('id')..remove('is_synced'));
        
        // Update local status
        await _db.markSaleAsSynced(entry.id!, docRef.id);
      } catch (e) {
        debugPrint('Failed to push sale ${entry.id}: $e');
      }
    }
  }

  Future<void> _pushExpenses() async {
    final unsynced = await _db.getUnsyncedExpenses();
    if (unsynced.isEmpty) return;

    for (final expense in unsynced) {
      try {
        final docRef = expense.firestoreId != null 
            ? _expensesCollection.doc(expense.firestoreId)
            : _expensesCollection.doc();
        
        await docRef.set(expense.toMap()..remove('id')..remove('is_synced'));
        
        await _db.markExpenseAsSynced(expense.id!, docRef.id);
      } catch (e) {
        debugPrint('Failed to push expense ${expense.id}: $e');
      }
    }
  }
}
