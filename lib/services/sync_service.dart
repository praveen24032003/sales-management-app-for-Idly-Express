import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'database_service.dart';
import '../models/expense_model.dart';
import '../models/sales_entry_model.dart';

/// Service to handle synchronization between local SQLite and Firestore
class SyncService extends ChangeNotifier with WidgetsBindingObserver {
  static const Duration _syncInterval = Duration(seconds: 5);
  static const _syncOperationUpsert = 'upsert';
  static const _syncOperationDelete = 'delete';
  static const _syncEntitySales = 'sales';
  static const _syncEntityExpenses = 'expenses';

  final DatabaseService _db = DatabaseService.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  
  // Singleton
  static final SyncService instance = SyncService._init();
  SyncService._init() {
    WidgetsBinding.instance.addObserver(this);
    _initConnectivity();
  }

  Future<void>? _initialization;
  StreamSubscription<QuerySnapshot>? _salesSubscription;
  StreamSubscription<QuerySnapshot>? _expensesSubscription;
  Future<void> Function()? _salesReloadCallback;
  Future<void> Function()? _expensesReloadCallback;
  Timer? _periodicSyncTimer;

  bool _isOnline = false;
  bool _isSyncing = false;
  String? _lastError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  String? get lastError => _lastError;

  // Collections
  CollectionReference get _salesCollection => _firestore.collection('sales');
  CollectionReference get _expensesCollection => _firestore.collection('expenses');

  void registerReloadCallbacks({
    Future<void> Function()? onSalesChanged,
    Future<void> Function()? onExpensesChanged,
  }) {
    _salesReloadCallback = onSalesChanged;
    _expensesReloadCallback = onExpensesChanged;
  }

  Future<void> initialize() {
    return _initialization ??= _initializeInternal();
  }

  Future<void> syncNow() async {
    await _refreshConnectivityStatus();
    await syncAll();
  }

  Future<void> _initializeInternal() async {
    _startRealtimeListeners();
    _startPeriodicSync();
    await _refreshConnectivityStatus();
    if (_isOnline) {
      await syncAll();
    }
  }

  void _startPeriodicSync() {
    _periodicSyncTimer ??= Timer.periodic(_syncInterval, (_) async {
      if (_isOnline) {
        await syncAll();
      }
    });
  }

  void _startRealtimeListeners() {
    _salesSubscription ??= _salesCollection.snapshots().listen(
      (snapshot) async {
        await _applySalesSnapshot(snapshot);
      },
      onError: _handleRealtimeError,
    );

    _expensesSubscription ??= _expensesCollection.snapshots().listen(
      (snapshot) async {
        await _applyExpensesSnapshot(snapshot);
      },
      onError: _handleRealtimeError,
    );
  }

  void _handleRealtimeError(Object error) {
    _lastError = error.toString();
    debugPrint('Realtime sync error: $error');
    notifyListeners();
  }

  void _initConnectivity() {
    _connectivity.onConnectivityChanged.listen((dynamic result) async {
      final wasOnline = _isOnline;
      final isConnected = _hasNetworkConnection(result);

      _isOnline = isConnected;
      if (_isOnline && !wasOnline) {
        await syncAll();
      } else if (_isOnline != wasOnline) {
        notifyListeners();
      }
    });
  }

  Future<void> _refreshConnectivityStatus() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _hasNetworkConnection(result);
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    () async {
      await _refreshConnectivityStatus();
      if (_isOnline) {
        await syncAll();
      }
    }();
  }

  bool _hasNetworkConnection(dynamic result) {
    if (result is List<ConnectivityResult>) {
      return result.any(_isConnectedResult);
    }
    if (result is ConnectivityResult) {
      return _isConnectedResult(result);
    }
    return false;
  }

  bool _isConnectedResult(ConnectivityResult result) {
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;
  }

  Future<void> syncAll() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      await _processSyncQueue();
      await _pushSales();
      await _pushExpenses();
      await _pullSales();
      await _pullExpenses();
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Sync Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _applySalesSnapshot(QuerySnapshot snapshot) async {
    final changed = await _mergeSalesDocuments(snapshot.docs);
    if (changed) {
      await _salesReloadCallback?.call();
    }
  }

  Future<void> _processSyncQueue() async {
    final queueItems = await _db.getPendingSyncQueue();
    for (final item in queueItems) {
      final queueId = item['id'] as int;
      try {
        final entityType = item['entity_type'] as String;
        final operation = item['operation'] as String;
        if (operation == _syncOperationUpsert) {
          await _processQueueUpsert(item, entityType);
        } else if (operation == _syncOperationDelete) {
          await _processQueueDelete(item, entityType);
        }
        await _db.removeSyncQueueItem(queueId);
      } catch (e) {
        await _db.markSyncQueueFailed(queueId, e);
      }
    }
  }

  Future<void> _processQueueUpsert(Map<String, dynamic> item, String entityType) async {
    final payloadRaw = item['payload'] as String?;
    if (payloadRaw == null || payloadRaw.isEmpty) {
      return;
    }

    final payload = Map<String, dynamic>.from(jsonDecode(payloadRaw) as Map);
    if (entityType == _syncEntitySales) {
      final entry = SalesEntry.fromMap(payload);
      final docRef = entry.firestoreId != null && entry.firestoreId!.isNotEmpty
          ? _salesCollection.doc(entry.firestoreId)
          : _salesCollection.doc();
      await docRef.set(entry.toMap()..remove('id')..remove('is_synced'));
      await _db.markSaleAsSynced(item['entity_local_id'] as int, docRef.id);
      return;
    }

    if (entityType == _syncEntityExpenses) {
      final expense = Expense.fromMap(payload);
      final docRef = expense.firestoreId != null && expense.firestoreId!.isNotEmpty
          ? _expensesCollection.doc(expense.firestoreId)
          : _expensesCollection.doc();
      await docRef.set(expense.toMap()..remove('id')..remove('is_synced'));
      await _db.markExpenseAsSynced(item['entity_local_id'] as int, docRef.id);
    }
  }

  Future<void> _processQueueDelete(Map<String, dynamic> item, String entityType) async {
    final firestoreId = item['firestore_id'] as String?;
    if (firestoreId == null || firestoreId.isEmpty) {
      return;
    }

    if (entityType == _syncEntitySales) {
      await _salesCollection.doc(firestoreId).delete();
      return;
    }

    if (entityType == _syncEntityExpenses) {
      await _expensesCollection.doc(firestoreId).delete();
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

  Future<void> _pullSales() async {
    final snapshot = await _salesCollection.get();
    final changed = await _mergeSalesDocuments(snapshot.docs);
    if (changed) {
      await _salesReloadCallback?.call();
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

  Future<void> _pullExpenses() async {
    final snapshot = await _expensesCollection.get();
    final changed = await _mergeExpenseDocuments(snapshot.docs);
    if (changed) {
      await _expensesReloadCallback?.call();
    }
  }

  Future<void> _applyExpensesSnapshot(QuerySnapshot snapshot) async {
    final changed = await _mergeExpenseDocuments(snapshot.docs);
    if (changed) {
      await _expensesReloadCallback?.call();
    }
  }

  Future<bool> _mergeSalesDocuments(List<QueryDocumentSnapshot> docs) async {
    final remoteIds = <String>{};
    var changed = false;

    for (final doc in docs) {
      try {
        remoteIds.add(doc.id);
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
          ..['firestore_id'] = doc.id
          ..['is_synced'] = 1;
        final entry = SalesEntry.fromMap(data);
        final applied = await _db.upsertSyncedSale(entry);
        changed = changed || applied;
      } catch (e) {
        debugPrint('Failed to merge sale ${doc.id}: $e');
      }
    }

    final pruned = await _db.pruneMissingSyncedSales(remoteIds);
    return changed || pruned;
  }

  Future<bool> _mergeExpenseDocuments(List<QueryDocumentSnapshot> docs) async {
    final remoteIds = <String>{};
    var changed = false;

    for (final doc in docs) {
      try {
        remoteIds.add(doc.id);
        final data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>)
          ..['firestore_id'] = doc.id
          ..['is_synced'] = 1;
        final expense = Expense.fromMap(data);
        final applied = await _db.upsertSyncedExpense(expense);
        changed = changed || applied;
      } catch (e) {
        debugPrint('Failed to merge expense ${doc.id}: $e');
      }
    }

    final pruned = await _db.pruneMissingSyncedExpenses(remoteIds);
    return changed || pruned;
  }

}
