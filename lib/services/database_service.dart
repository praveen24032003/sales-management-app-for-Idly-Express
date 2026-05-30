import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants.dart';
import '../models/sales_entry_model.dart';
import '../models/expense_model.dart';
import '../models/supply_template_model.dart';
import '../models/dispatch_leave_model.dart';

/// Database service for offline-first data storage
class DatabaseService {
  static const _syncOperationUpsert = 'upsert';
  static const _syncOperationDelete = 'delete';
  static const _syncEntitySales = 'sales';
  static const _syncEntityExpenses = 'expenses';

  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  Future<void> _onOpen(Database db) async {
    await _ensureCurrentSchema(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Preserve existing user data instead of recreating tables during upgrade.
      await _ensureTableExists(
        db,
        salesTable,
        '''
        CREATE TABLE IF NOT EXISTS $salesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          shopName TEXT NOT NULL,
          productType INTEGER NOT NULL,
          saleType INTEGER NOT NULL,
          ratePerUnit REAL NOT NULL,
          quantity INTEGER NOT NULL,
          costPerUnit REAL NOT NULL,
          totalSalesAmount REAL NOT NULL,
          totalCost REAL NOT NULL,
          profit REAL NOT NULL,
          paymentStatus INTEGER NOT NULL,
          paidAmount REAL NOT NULL,
          notes TEXT
        )
      ''',
      );
      await _ensureTableExists(
        db,
        shopsTable,
        '''
        CREATE TABLE IF NOT EXISTS $shopsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          lastUsed TEXT NOT NULL
        )
      ''',
      );
      await _ensureTableExists(
        db,
        'expenses',
        '''
        CREATE TABLE IF NOT EXISTS expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          category INTEGER NOT NULL,
          amount REAL NOT NULL,
          notes TEXT
        )
      ''',
      );
    }
    
    if (oldVersion < 3) {
      // Add sync columns for v2->v3
      // Sales Table
      await _addColumnIfMissing(db, salesTable, 'firestore_id', 'TEXT');
      await _addColumnIfMissing(db, salesTable, 'last_modified', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, salesTable, 'is_synced', 'INTEGER NOT NULL DEFAULT 0');
      
      // Expenses Table
      await _addColumnIfMissing(db, 'expenses', 'firestore_id', 'TEXT');
      await _addColumnIfMissing(db, 'expenses', 'last_modified', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, 'expenses', 'is_synced', 'INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      await _addColumnIfMissing(db, salesTable, 'order_type', 'INTEGER NOT NULL DEFAULT 1');
      await _addColumnIfMissing(db, salesTable, 'delivery_slot', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, salesTable, 'delivery_time', 'TEXT');
      await _addColumnIfMissing(db, salesTable, 'prep_lead_days', 'INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 5) {
      await _ensureTableExists(
        db,
        supplyTemplatesTable,
        '''
        CREATE TABLE IF NOT EXISTS $supplyTemplatesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          shop_name TEXT NOT NULL,
          product_type INTEGER NOT NULL,
          sale_type INTEGER NOT NULL,
          quantity INTEGER NOT NULL,
          rate_per_unit REAL NOT NULL,
          cost_per_unit REAL NOT NULL,
          delivery_slot INTEGER NOT NULL DEFAULT 0,
          delivery_time TEXT,
          prep_lead_days INTEGER NOT NULL DEFAULT 1,
          active_weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
          start_date TEXT,
          end_date TEXT,
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''',
      );

      await _ensureTableExists(
        db,
        appSettingsTable,
        '''
        CREATE TABLE IF NOT EXISTS $appSettingsTable (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''',
      );
    }

    if (oldVersion >= 5 && oldVersion < 6) {
      await _addColumnIfMissing(
        db,
        supplyTemplatesTable,
        'active_weekdays',
        "TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7'",
      );
      await _addColumnIfMissing(db, supplyTemplatesTable, 'start_date', 'TEXT');
      await _addColumnIfMissing(db, supplyTemplatesTable, 'end_date', 'TEXT');
    }

    if (oldVersion < 7) {
      // Add mobile column to shops
      await _addColumnIfMissing(db, shopsTable, 'mobile', 'TEXT');
      // Add customer_mobile to sales_entries
      await _addColumnIfMissing(db, salesTable, 'customer_mobile', 'TEXT');
      // Add morning/evening split to supply templates
      await _addColumnIfMissing(db, supplyTemplatesTable, 'morning_quantity', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, supplyTemplatesTable, 'evening_quantity', 'INTEGER NOT NULL DEFAULT 0');
      await _addColumnIfMissing(db, supplyTemplatesTable, 'shop_mobile', 'TEXT');
      // Create dispatch_leaves table
      await _ensureTableExists(
        db,
        dispatchLeavesTable,
        '''
        CREATE TABLE IF NOT EXISTS $dispatchLeavesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          leave_date TEXT NOT NULL,
          delivery_slot INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''',
      );
    }

    if (oldVersion < 8) {
      await _ensureTableExists(
        db,
        contactsTable,
        '''
        CREATE TABLE IF NOT EXISTS $contactsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          mobile TEXT,
          contact_type TEXT NOT NULL,
          last_used TEXT NOT NULL,
          UNIQUE(name, contact_type)
        )
      ''',
      );
    }

    if (oldVersion < 9) {
      await _ensureTableExists(
        db,
        syncQueueTable,
        '''
        CREATE TABLE IF NOT EXISTS $syncQueueTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entity_type TEXT NOT NULL,
          entity_local_id INTEGER NOT NULL,
          operation TEXT NOT NULL,
          firestore_id TEXT,
          payload TEXT,
          created_at INTEGER NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_error TEXT,
          UNIQUE(entity_type, entity_local_id)
        )
      ''',
      );
    }

    await _ensureCurrentSchema(db);
  }

  Future<void> _createDB(Database db, int version) async {
    // Sales entries table
    await db.execute('''
      CREATE TABLE $salesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        shopName TEXT NOT NULL,
        order_type INTEGER NOT NULL DEFAULT 1,
        delivery_slot INTEGER NOT NULL DEFAULT 0,
        delivery_time TEXT,
        prep_lead_days INTEGER NOT NULL DEFAULT 1,
        productType INTEGER NOT NULL,
        saleType INTEGER NOT NULL,
        ratePerUnit REAL NOT NULL,
        quantity INTEGER NOT NULL,
        costPerUnit REAL NOT NULL,
        totalSalesAmount REAL NOT NULL,
        totalCost REAL NOT NULL,
        profit REAL NOT NULL,
        paymentStatus INTEGER NOT NULL,
        paidAmount REAL NOT NULL,
        notes TEXT,
        customer_mobile TEXT,
        firestore_id TEXT,
        last_modified INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Shops table for auto-suggestions
    await db.execute('''
      CREATE TABLE $shopsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        mobile TEXT,
        lastUsed TEXT NOT NULL
      )
    ''');
    
    // Expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        category INTEGER NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        firestore_id TEXT,
        last_modified INTEGER NOT NULL DEFAULT 0,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Recurring everyday supply templates
    await db.execute('''
      CREATE TABLE $supplyTemplatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        product_type INTEGER NOT NULL,
        sale_type INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        rate_per_unit REAL NOT NULL,
        cost_per_unit REAL NOT NULL,
        delivery_slot INTEGER NOT NULL DEFAULT 0,
        delivery_time TEXT,
        prep_lead_days INTEGER NOT NULL DEFAULT 1,
        active_weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        start_date TEXT,
        end_date TEXT,
        morning_quantity INTEGER NOT NULL DEFAULT 0,
        evening_quantity INTEGER NOT NULL DEFAULT 0,
        shop_mobile TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE $appSettingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $dispatchLeavesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        leave_date TEXT NOT NULL,
        delivery_slot INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $contactsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT,
        contact_type TEXT NOT NULL,
        last_used TEXT NOT NULL,
        UNIQUE(name, contact_type)
      )
    ''');

    await db.execute('''
      CREATE TABLE $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_local_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        firestore_id TEXT,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        UNIQUE(entity_type, entity_local_id)
      )
    ''');
  }

  Future<void> _ensureCurrentSchema(Database db) async {
    await _ensureTableExists(
      db,
      supplyTemplatesTable,
      '''
      CREATE TABLE IF NOT EXISTS $supplyTemplatesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT NOT NULL,
        product_type INTEGER NOT NULL,
        sale_type INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        rate_per_unit REAL NOT NULL,
        cost_per_unit REAL NOT NULL,
        delivery_slot INTEGER NOT NULL DEFAULT 0,
        delivery_time TEXT,
        prep_lead_days INTEGER NOT NULL DEFAULT 1,
        active_weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        start_date TEXT,
        end_date TEXT,
        morning_quantity INTEGER NOT NULL DEFAULT 0,
        evening_quantity INTEGER NOT NULL DEFAULT 0,
        shop_mobile TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''',
    );
    await _ensureTableExists(
      db,
      dispatchLeavesTable,
      '''
      CREATE TABLE IF NOT EXISTS $dispatchLeavesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        leave_date TEXT NOT NULL,
        delivery_slot INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''',
    );
    await _ensureTableExists(
      db,
      contactsTable,
      '''
      CREATE TABLE IF NOT EXISTS $contactsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT,
        contact_type TEXT NOT NULL,
        last_used TEXT NOT NULL,
        UNIQUE(name, contact_type)
      )
    ''',
    );
    await _ensureTableExists(
      db,
      appSettingsTable,
      '''
      CREATE TABLE IF NOT EXISTS $appSettingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''',
    );
    await _ensureTableExists(
      db,
      syncQueueTable,
      '''
      CREATE TABLE IF NOT EXISTS $syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_local_id INTEGER NOT NULL,
        operation TEXT NOT NULL,
        firestore_id TEXT,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        UNIQUE(entity_type, entity_local_id)
      )
    ''',
    );

    await _addColumnIfMissing(
      db,
      supplyTemplatesTable,
      'active_weekdays',
      "TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7'",
    );
    await _addColumnIfMissing(db, supplyTemplatesTable, 'start_date', 'TEXT');
    await _addColumnIfMissing(db, supplyTemplatesTable, 'end_date', 'TEXT');
    await _addColumnIfMissing(db, supplyTemplatesTable, 'morning_quantity', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, supplyTemplatesTable, 'evening_quantity', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, supplyTemplatesTable, 'shop_mobile', 'TEXT');
    await _addColumnIfMissing(db, supplyTemplatesTable, 'is_active', 'INTEGER NOT NULL DEFAULT 1');

    await _addColumnIfMissing(db, shopsTable, 'mobile', 'TEXT');
    await _addColumnIfMissing(db, salesTable, 'customer_mobile', 'TEXT');
    await _addColumnIfMissing(db, salesTable, 'order_type', 'INTEGER NOT NULL DEFAULT 1');
    await _addColumnIfMissing(db, salesTable, 'delivery_slot', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, salesTable, 'delivery_time', 'TEXT');
    await _addColumnIfMissing(db, salesTable, 'prep_lead_days', 'INTEGER NOT NULL DEFAULT 1');
    await _addColumnIfMissing(db, salesTable, 'firestore_id', 'TEXT');
    await _addColumnIfMissing(db, salesTable, 'last_modified', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, salesTable, 'is_synced', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'expenses', 'firestore_id', 'TEXT');
    await _addColumnIfMissing(db, 'expenses', 'last_modified', 'INTEGER NOT NULL DEFAULT 0');
    await _addColumnIfMissing(db, 'expenses', 'is_synced', 'INTEGER NOT NULL DEFAULT 0');
  }

  Future<void> _ensureTableExists(Database db, String tableName, String createSql) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    if (result.isEmpty) {
      await db.execute(createSql);
    }
  }

  Future<void> _addColumnIfMissing(Database db, String tableName, String columnName, String definition) async {
    if (!await _tableExists(db, tableName)) {
      return;
    }
    if (await _columnExists(db, tableName, columnName)) {
      return;
    }

    await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $definition');
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  Future<bool> _columnExists(Database db, String tableName, String columnName) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  // ==================== RECURRING TEMPLATES ====================

  Future<List<SupplyTemplate>> getAllSupplyTemplates() async {
    final db = await database;
    final result = await db.query(supplyTemplatesTable, orderBy: 'shop_name ASC');
    return result.map((map) => SupplyTemplate.fromMap(map)).toList();
  }

  Future<int> insertSupplyTemplate(SupplyTemplate template) async {
    final db = await database;
    await _saveShopName(template.shopName);
    return db.insert(supplyTemplatesTable, template.toMap());
  }

  Future<int> updateSupplyTemplate(SupplyTemplate template) async {
    final db = await database;
    await _saveShopName(template.shopName);
    return db.update(
      supplyTemplatesTable,
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  Future<int> deleteSupplyTemplate(int id) async {
    final db = await database;
    await db.delete(dispatchLeavesTable, where: 'template_id = ?', whereArgs: [id]);
    return db.delete(supplyTemplatesTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> _getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      appSettingsTable,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> _setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      appSettingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  List<DeliverySlot> _templateSlots(SupplyTemplate template) {
    final slots = <DeliverySlot>[];
    if (template.morningQuantity > 0) {
      slots.add(DeliverySlot.morning);
    }
    if (template.eveningQuantity > 0) {
      slots.add(DeliverySlot.evening);
    }
    if (slots.isEmpty) {
      slots.add(template.deliverySlot);
    }
    return slots;
  }

  int _templateQuantityForSlot(SupplyTemplate template, DeliverySlot slot) {
    if (slot == DeliverySlot.morning && template.morningQuantity > 0) {
      return template.morningQuantity;
    }
    if (slot == DeliverySlot.evening && template.eveningQuantity > 0) {
      return template.eveningQuantity;
    }
    return template.quantity;
  }

  Future<bool> _hasEverydayOrderForTemplateToday(SupplyTemplate template) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    for (final slot in _templateSlots(template)) {
      final result = await db.query(
        salesTable,
        columns: ['id'],
        where: 'shopName = ? AND productType = ? AND saleType = ? AND delivery_slot = ? AND order_type = ? AND date >= ? AND date < ?',
        whereArgs: [
          template.shopName,
          template.productType.index,
          template.saleType.index,
          slot.index,
          OrderType.everydaySupply.index,
          start,
          end,
        ],
        limit: 1,
      );

      if (result.isEmpty) {
        return false;
      }
    }

    return true;
  }

  Future<int> autoCreateTodaySupplyOrdersIfNeeded() async {
    final now = DateTime.now();
    final todayKey = now.toIso8601String().split('T').first;
    final lastGenerated = await _getSetting(settingLastTemplateGenerationDate);
    if (lastGenerated == todayKey) {
      return 0;
    }

    final templates = (await getAllSupplyTemplates())
        .where((t) => t.isActiveOnDate(now))
        .toList();

    int created = 0;
    for (final template in templates) {
      final alreadyExists = await _hasEverydayOrderForTemplateToday(template);
      if (alreadyExists) continue;

      for (final slot in _templateSlots(template)) {
        final entry = SalesEntry(
          date: DateTime.now(),
          shopName: template.shopName,
          orderType: OrderType.everydaySupply,
          deliverySlot: slot,
          deliveryTime: template.deliveryTime,
          prepLeadDays: template.prepLeadDays,
          productType: template.productType,
          saleType: template.saleType,
          ratePerUnit: template.ratePerUnit,
          quantity: _templateQuantityForSlot(template, slot),
          costPerUnit: template.costPerUnit,
          paymentStatus: PaymentStatus.pending,
          paidAmount: 0,
          notes: 'Auto-created from recurring template',
        );

        await insertSalesEntry(entry);
        created++;
      }
    }

    await _setSetting(settingLastTemplateGenerationDate, todayKey);
    return created;
  }

  // ==================== SALES CRUD ====================

  /// Insert a new sales entry
  Future<int> insertSalesEntry(SalesEntry entry) async {
    final db = await database;
    final localEntry = entry.copyWith(
      lastModified: DateTime.now().millisecondsSinceEpoch,
      isSynced: false,
    );
    
    // Also save/update shop name for suggestions
    await _saveShopName(localEntry.shopName);
    
    final id = await db.insert(salesTable, localEntry.toMap());
    await _enqueueSyncUpsert(
      entityType: _syncEntitySales,
      entityLocalId: id,
      payload: localEntry.copyWith(id: id).toMap(),
    );
    return id;
  }

  /// Batch insert sales entries
  Future<int> batchInsert(List<SalesEntry> entries) async {
    final db = await database;
    final batch = db.batch();

    for (final entry in entries) {
      batch.insert(salesTable, entry.toMap());
      // Also save shop name logic if needed, but for batch performance we might skip or do it separately
      // For now, let's just insert sales entries fast
    }
    
    // We also need to update shop suggestions for unique names
    final uniqueShops = entries.map((e) => e.shopName).toSet();
    for (final shop in uniqueShops) {
       batch.insert(
        shopsTable,
        {'name': shop, 'lastUsed': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit(noResult: false);
    return results.length;
  }

  /// Update existing sales entry
  Future<int> updateSalesEntry(SalesEntry entry) async {
    final db = await database;
    final localEntry = entry.copyWith(
      lastModified: DateTime.now().millisecondsSinceEpoch,
      isSynced: false,
    );
    await _saveShopName(localEntry.shopName);
    final updated = await db.update(
      salesTable,
      localEntry.toMap(),
      where: 'id = ?',
      whereArgs: [localEntry.id],
    );
    if (updated > 0 && localEntry.id != null) {
      await _enqueueSyncUpsert(
        entityType: _syncEntitySales,
        entityLocalId: localEntry.id!,
        payload: localEntry.toMap(),
      );
    }
    return updated;
  }

  /// Delete a sales entry
  Future<int> deleteSalesEntry(int id) async {
    final db = await database;
    final existing = await getSalesEntryById(id);
    final deleted = await db.delete(
      salesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted > 0) {
      await _enqueueSyncDelete(
        entityType: _syncEntitySales,
        entityLocalId: id,
        firestoreId: existing?.firestoreId,
      );
    }
    return deleted;
  }

  /// Get all sales entries
  Future<List<SalesEntry>> getAllEntries() async {
    final db = await database;
    final result = await db.query(salesTable, orderBy: 'date DESC');
    return result.map((map) => SalesEntry.fromMap(map)).toList();
  }

  /// Get entries by date range
  Future<List<SalesEntry>> getEntriesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      salesTable,
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => SalesEntry.fromMap(map)).toList();
  }

  /// Get today's entries
  Future<List<SalesEntry>> getTodayEntries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getEntriesByDateRange(startOfDay, endOfDay);
  }

  /// Get entries for current month
  Future<List<SalesEntry>> getCurrentMonthEntries() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return getEntriesByDateRange(startOfMonth, endOfMonth);
  }

  /// Get entries for current year
  Future<List<SalesEntry>> getCurrentYearEntries() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);
    return getEntriesByDateRange(startOfYear, endOfYear);
  }

  /// Get entries by shop name
  Future<List<SalesEntry>> getEntriesByShop(String shopName) async {
    final db = await database;
    final result = await db.query(
      salesTable,
      where: 'shopName = ?',
      whereArgs: [shopName],
      orderBy: 'date DESC',
    );
    return result.map((map) => SalesEntry.fromMap(map)).toList();
  }

  /// Get entries by sale type
  Future<List<SalesEntry>> getEntriesBySaleType(SaleType saleType) async {
    final db = await database;
    final result = await db.query(
      salesTable,
      where: 'saleType = ?',
      whereArgs: [saleType.index],
      orderBy: 'date DESC',
    );
    return result.map((map) => SalesEntry.fromMap(map)).toList();
  }

  // ==================== SHOP SUGGESTIONS ====================

  /// Save shop name for auto-suggestions (preserves mobile if already stored)
  Future<void> _saveShopName(String name) async {
    final db = await database;
    final existing = await db.query(shopsTable, where: 'name = ?', whereArgs: [name], limit: 1);
    if (existing.isNotEmpty) {
      await db.update(
        shopsTable,
        {'lastUsed': DateTime.now().toIso8601String()},
        where: 'name = ?',
        whereArgs: [name],
      );
    } else {
      await db.insert(shopsTable, {'name': name, 'lastUsed': DateTime.now().toIso8601String()});
    }
  }

  Future<void> updateShopMobile(String name, String mobile) async {
    final db = await database;
    await db.update(shopsTable, {'mobile': mobile}, where: 'name = ?', whereArgs: [name]);
  }

  Future<void> saveManualContact({
    required String contactType,
    required String name,
    String? mobile,
  }) async {
    final db = await database;
    final normalizedName = name.trim();
    final normalizedMobile = mobile?.trim();
    final now = DateTime.now().toIso8601String();

    await db.insert(
      contactsTable,
      {
        'name': normalizedName,
        'mobile': normalizedMobile,
        'contact_type': contactType,
        'last_used': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (contactType == contactTypeShop) {
      final existing = await db.query(
        shopsTable,
        columns: ['name'],
        where: 'name = ?',
        whereArgs: [normalizedName],
        limit: 1,
      );
      if (existing.isEmpty) {
        await db.insert(
          shopsTable,
          {'name': normalizedName, 'mobile': normalizedMobile, 'lastUsed': now},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.update(
          shopsTable,
          {'mobile': normalizedMobile, 'lastUsed': now},
          where: 'name = ?',
          whereArgs: [normalizedName],
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getManualContacts(String contactType) async {
    final db = await database;
    return db.query(
      contactsTable,
      columns: ['name', 'mobile', 'last_used'],
      where: 'contact_type = ?',
      whereArgs: [contactType],
      orderBy: 'last_used DESC',
    );
  }

  List<Map<String, dynamic>> _mergeContacts(List<Map<String, dynamic>> primary, List<Map<String, dynamic>> secondary) {
    final merged = <String, Map<String, dynamic>>{};

    void mergeOne(Map<String, dynamic> contact) {
      final name = (contact['name'] as String? ?? '').trim();
      if (name.isEmpty) return;
      final key = name.toLowerCase();
      final mobile = (contact['mobile'] as String?)?.trim();
      final lastUsed = (contact['lastUsed'] ?? contact['last_used'] ?? '') as String;
      final current = merged[key];

      if (current == null) {
        merged[key] = {'name': name, 'mobile': mobile, 'lastUsed': lastUsed};
        return;
      }

      final currentMobile = (current['mobile'] as String?)?.trim();
      final chosenMobile = (mobile != null && mobile.isNotEmpty) ? mobile : currentMobile;
      final currentLastUsed = (current['lastUsed'] as String?) ?? '';
      merged[key] = {
        'name': current['name'] ?? name,
        'mobile': chosenMobile,
        'lastUsed': currentLastUsed.compareTo(lastUsed) >= 0 ? currentLastUsed : lastUsed,
      };
    }

    for (final contact in primary) {
      mergeOne(contact);
    }
    for (final contact in secondary) {
      mergeOne(contact);
    }

    final contacts = merged.values.toList();
    contacts.sort((a, b) => ((b['lastUsed'] as String?) ?? '').compareTo((a['lastUsed'] as String?) ?? ''));
    return contacts;
  }

  Future<void> updateShopContact({
    required String oldName,
    required String newName,
    String? mobile,
  }) async {
    final db = await database;
    final normalizedNewName = newName.trim();
    final normalizedMobile = mobile?.trim();
    final affectedSalesIds = (await db.query(
      salesTable,
      columns: ['id'],
      where: 'shopName = ?',
      whereArgs: [oldName],
    ))
        .map((row) => row['id'] as int)
        .toList();

    await db.transaction((txn) async {
      await txn.update(
        salesTable,
        {'shopName': normalizedNewName},
        where: 'shopName = ?',
        whereArgs: [oldName],
      );

      await txn.update(
        supplyTemplatesTable,
        {
          'shop_name': normalizedNewName,
          'shop_mobile': normalizedMobile,
        },
        where: 'shop_name = ?',
        whereArgs: [oldName],
      );

      final existing = await txn.query(
        shopsTable,
        columns: ['name'],
        where: 'name = ?',
        whereArgs: [normalizedNewName],
        limit: 1,
      );

      if (existing.isEmpty) {
        await txn.update(
          shopsTable,
          {
            'name': normalizedNewName,
            'mobile': normalizedMobile,
            'lastUsed': DateTime.now().toIso8601String(),
          },
          where: 'name = ?',
          whereArgs: [oldName],
        );
      } else {
        await txn.update(
          shopsTable,
          {
            'mobile': normalizedMobile,
            'lastUsed': DateTime.now().toIso8601String(),
          },
          where: 'name = ?',
          whereArgs: [normalizedNewName],
        );
        if (oldName != normalizedNewName) {
          await txn.delete(shopsTable, where: 'name = ?', whereArgs: [oldName]);
        }
      }

      await txn.insert(
        contactsTable,
        {
          'name': normalizedNewName,
          'mobile': normalizedMobile,
          'contact_type': contactTypeShop,
          'last_used': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (oldName != normalizedNewName) {
        await txn.delete(
          contactsTable,
          where: 'name = ? AND contact_type = ?',
          whereArgs: [oldName, contactTypeShop],
        );
      }
    });

    for (final id in affectedSalesIds) {
      final entry = await getSalesEntryById(id);
      if (entry != null) {
        await updateSalesEntry(entry);
      }
    }
  }

  Future<void> updateExternalCustomerContact({
    required String oldName,
    required String newName,
    String? mobile,
  }) async {
    final db = await database;
    final normalizedNewName = newName.trim();
    final normalizedMobile = mobile?.trim();
    final affectedSalesIds = (await db.query(
      salesTable,
      columns: ['id'],
      where: 'order_type = ? AND shopName = ?',
      whereArgs: [OrderType.externalOrder.index, oldName],
    ))
        .map((row) => row['id'] as int)
        .toList();

    await db.update(
      salesTable,
      {
        'shopName': normalizedNewName,
        'customer_mobile': normalizedMobile,
      },
      where: 'order_type = ? AND shopName = ?',
      whereArgs: [OrderType.externalOrder.index, oldName],
    );

    await db.insert(
      contactsTable,
      {
        'name': normalizedNewName,
        'mobile': normalizedMobile,
        'contact_type': contactTypeCustomer,
        'last_used': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (oldName != normalizedNewName) {
      await db.delete(
        contactsTable,
        where: 'name = ? AND contact_type = ?',
        whereArgs: [oldName, contactTypeCustomer],
      );
    }

    for (final id in affectedSalesIds) {
      final entry = await getSalesEntryById(id);
      if (entry != null) {
        await updateSalesEntry(entry);
      }
    }
  }

  Future<String?> getShopMobile(String name) async {
    final db = await database;
    final result = await db.query(shopsTable, columns: ['mobile'], where: 'name = ?', whereArgs: [name], limit: 1);
    if (result.isEmpty) return null;
    return result.first['mobile'] as String?;
  }

  Future<List<Map<String, dynamic>>> getAllShopsWithMobile() async {
    final db = await database;
    final result = await db.query(shopsTable, columns: ['name', 'mobile', 'lastUsed'], orderBy: 'lastUsed DESC');
    final manual = await getManualContacts(contactTypeShop);
    return _mergeContacts(
      result.map((r) => {'name': r['name'] as String?, 'mobile': r['mobile'] as String?, 'lastUsed': r['lastUsed'] as String? ?? ''}).toList(),
      manual.map((r) => {'name': r['name'] as String?, 'mobile': r['mobile'] as String?, 'lastUsed': r['last_used'] as String? ?? ''}).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> getRecentExternalCustomers() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT shopName as name, customer_mobile as mobile, MAX(date) as lastUsed
      FROM $salesTable
      WHERE order_type = ${OrderType.externalOrder.index}
      GROUP BY shopName, customer_mobile
      ORDER BY lastUsed DESC
      LIMIT 30
    ''');
    final manual = await getManualContacts(contactTypeCustomer);
    return _mergeContacts(
      result,
      manual.map((r) => {'name': r['name'] as String?, 'mobile': r['mobile'] as String?, 'lastUsed': r['last_used'] as String? ?? ''}).toList(),
    );
  }

  /// Get shop suggestions based on query
  Future<List<String>> getShopSuggestions(String query) async {
    final db = await database;
    final result = await db.query(
      shopsTable,
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'lastUsed DESC',
      limit: 10,
    );
    return result.map((map) => map['name'] as String).toList();
  }

  /// Get all shop names
  Future<List<String>> getAllShops() async {
    final db = await database;
    final result = await db.query(shopsTable, orderBy: 'lastUsed DESC');
    return result.map((map) => map['name'] as String).toList();
  }

  // ==================== AGGREGATIONS ====================

  /// Get total sales amount for a date range
  Future<double> getTotalSalesAmount(DateTime start, DateTime end) async {
    final entries = await getEntriesByDateRange(start, end);
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.totalSalesAmount);
  }

  /// Get total quantity for a date range
  Future<int> getTotalQuantity(DateTime start, DateTime end) async {
    final entries = await getEntriesByDateRange(start, end);
    return entries.fold<int>(0, (sum, entry) => sum + entry.quantity);
  }

  /// Get total profit for a date range
  Future<double> getTotalProfit(DateTime start, DateTime end) async {
    final entries = await getEntriesByDateRange(start, end);
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.profit);
  }

  /// Get total pending amount for a shop
  Future<double> getPendingAmountByShop(String shopName) async {
    final entries = await getEntriesByShop(shopName);
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.pendingAmount);
  }

  /// Get all shops with pending amounts
  Future<Map<String, double>> getAllPendingAmounts() async {
    final entries = await getAllEntries();
    final Map<String, double> pendingMap = {};
    
    for (final entry in entries) {
      if (entry.pendingAmount > 0) {
        pendingMap[entry.shopName] = (pendingMap[entry.shopName] ?? 0) + entry.pendingAmount;
      }
    }
    return pendingMap;
  }

  Future<void> applyPaymentToShopPending(String shopName, double paidAmount) async {
    if (paidAmount <= 0) return;

    final db = await database;
    final entries = await getEntriesByShop(shopName);
    final pendingEntries = entries
        .where((entry) => entry.pendingAmount > 0.1)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    double remaining = paidAmount;
    final updatedEntryIds = <int>[];

    await db.transaction((txn) async {
      for (final entry in pendingEntries) {
        if (remaining <= 0.01) break;

        final payable = entry.pendingAmount < remaining ? entry.pendingAmount : remaining;
        final updatedPaidAmount = (entry.paidAmount ?? 0) + payable;
        final updatedEntry = entry.copyWith(
          paidAmount: updatedPaidAmount,
          paymentStatus: (entry.totalSalesAmount - updatedPaidAmount) <= 0.1
              ? PaymentStatus.paid
              : PaymentStatus.pending,
        );

        await txn.update(
          salesTable,
          updatedEntry.toMap(),
          where: 'id = ?',
          whereArgs: [entry.id],
        );
        if (entry.id != null) {
          updatedEntryIds.add(entry.id!);
        }

        remaining -= payable;
      }
    });

    for (final id in updatedEntryIds) {
      final entry = await getSalesEntryById(id);
      if (entry != null) {
        await updateSalesEntry(entry);
      }
    }
  }

  // ==================== EXPENSES CRUD ====================

  /// Insert expense
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    final expenseMap = expense.toMap()
      ..['last_modified'] = DateTime.now().millisecondsSinceEpoch
      ..['is_synced'] = 0;
    final id = await db.insert('expenses', expenseMap);
    await _enqueueSyncUpsert(
      entityType: _syncEntityExpenses,
      entityLocalId: id,
      payload: {...expenseMap, 'id': id},
    );
    return id;
  }

  Future<bool> upsertSyncedSale(SalesEntry entry) async {
    final db = await database;
    final firestoreId = entry.firestoreId;
    if (firestoreId == null || firestoreId.isEmpty) return false;

    final existing = await db.query(
      salesTable,
      columns: ['id', 'last_modified', 'is_synced'],
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final row = existing.first;
      final localId = row['id'] as int;
      final localLastModified = row['last_modified'] as int? ?? 0;
      final localIsSynced = (row['is_synced'] as int? ?? 0) == 1;
      if (!localIsSynced && localLastModified > entry.lastModified) {
        return false;
      }

      await _saveShopName(entry.shopName);
      final updatedEntry = entry.copyWith(id: localId, isSynced: true);
      if (SalesEntry.fromMap({...updatedEntry.toMap(), 'id': localId}).toMap().toString() ==
          (await db.query(salesTable, where: 'id = ?', whereArgs: [localId], limit: 1)).first.toString()) {
        return false;
      }
      await db.update(
        salesTable,
        updatedEntry.toMap(),
        where: 'id = ?',
        whereArgs: [localId],
      );
      return true;
    }

    await _saveShopName(entry.shopName);
    await db.insert(salesTable, entry.copyWith(isSynced: true).toMap()..remove('id'));
    return true;
  }

  Future<bool> upsertSyncedExpense(Expense expense) async {
    final db = await database;
    final firestoreId = expense.firestoreId;
    if (firestoreId == null || firestoreId.isEmpty) return false;

    final existing = await db.query(
      'expenses',
      columns: ['id', 'last_modified', 'is_synced'],
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
      limit: 1,
    );

    final expenseMap = expense.toMap()
      ..['is_synced'] = 1
      ..remove('id');

    if (existing.isNotEmpty) {
      final row = existing.first;
      final localId = row['id'] as int;
      final localLastModified = row['last_modified'] as int? ?? 0;
      final localIsSynced = (row['is_synced'] as int? ?? 0) == 1;
      if (!localIsSynced && localLastModified > expense.lastModified) {
        return false;
      }

      final currentRow = await db.query('expenses', where: 'id = ?', whereArgs: [localId], limit: 1);
      if (currentRow.isNotEmpty) {
        final comparable = {...expenseMap, 'id': localId};
        if (currentRow.first.toString() == comparable.toString()) {
          return false;
        }
      }
      await db.update(
        'expenses',
        expenseMap,
        where: 'id = ?',
        whereArgs: [localId],
      );
      return true;
    }

    await db.insert('expenses', expenseMap);
    return true;
  }

  Future<SalesEntry?> getSalesEntryById(int id) async {
    final db = await database;
    final rows = await db.query(salesTable, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return SalesEntry.fromMap(rows.first);
  }

  Future<Expense?> getExpenseById(int id) async {
    final db = await database;
    final rows = await db.query('expenses', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<bool> pruneMissingSyncedSales(Set<String> remoteFirestoreIds) async {
    final db = await database;
    final syncedRows = await db.query(
      salesTable,
      columns: ['id', 'firestore_id'],
      where: 'is_synced = 1 AND firestore_id IS NOT NULL AND firestore_id != ?',
      whereArgs: [''],
    );

    final idsToDelete = syncedRows
        .where((row) => !remoteFirestoreIds.contains(row['firestore_id']))
        .map((row) => row['id'] as int)
        .toList();
    if (idsToDelete.isEmpty) return false;

    for (final id in idsToDelete) {
      await db.delete(salesTable, where: 'id = ?', whereArgs: [id]);
    }
    return true;
  }

  Future<bool> pruneMissingSyncedExpenses(Set<String> remoteFirestoreIds) async {
    final db = await database;
    final syncedRows = await db.query(
      'expenses',
      columns: ['id', 'firestore_id'],
      where: 'is_synced = 1 AND firestore_id IS NOT NULL AND firestore_id != ?',
      whereArgs: [''],
    );

    final idsToDelete = syncedRows
        .where((row) => !remoteFirestoreIds.contains(row['firestore_id']))
        .map((row) => row['id'] as int)
        .toList();
    if (idsToDelete.isEmpty) return false;

    for (final id in idsToDelete) {
      await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    }
    return true;
  }

  /// Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    final existing = await getExpenseById(id);
    final deleted = await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    if (deleted > 0) {
      await _enqueueSyncDelete(
        entityType: _syncEntityExpenses,
        entityLocalId: id,
        firestoreId: existing?.firestoreId,
      );
    }
    return deleted;
  }

  /// Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  /// Get total expenses for date range
  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final expenses = await getExpensesByDateRange(start, end);
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  // ==================== CSV EXPORT/IMPORT ====================

  /// Export all entries to CSV string
  Future<String> exportToCsv() async {
    final entries = await getAllEntries();
    final buffer = StringBuffer();
    buffer.writeln(SalesEntry.csvHeader);
    for (final entry in entries) {
      buffer.writeln(entry.toCsvRow());
    }
    return buffer.toString();
  }

  /// Import entries from CSV string
  Future<int> importFromCsv(String csvContent) async {
    final lines = csvContent.split('\n');
    if (lines.isEmpty) return 0;

    int imported = 0;
    // Skip header row
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final parts = line.split(',');
        if (parts.length < 10) continue;

        final hasOrderColumns = parts.length >= 18;

        final entry = SalesEntry(
          date: DateTime.parse(parts[0]),
          shopName: parts[1],
          orderType: hasOrderColumns
              ? OrderType.values.firstWhere(
                  (o) => o.displayName == parts[2],
                  orElse: () => OrderType.externalOrder,
                )
              : OrderType.externalOrder,
          deliverySlot: hasOrderColumns
              ? DeliverySlot.values.firstWhere(
                  (d) => d.displayName == parts[3],
                  orElse: () => DeliverySlot.morning,
                )
              : DeliverySlot.morning,
          deliveryTime: hasOrderColumns && parts[4].trim().isNotEmpty ? parts[4] : null,
          prepLeadDays: hasOrderColumns ? int.tryParse(parts[5]) ?? 1 : 1,
          productType: ProductType.values.firstWhere(
            (p) => p.displayName == (hasOrderColumns ? parts[6] : parts[2]),
            orElse: () => ProductType.idly,
          ),
          saleType: SaleType.values.firstWhere(
            (s) => s.displayName == (hasOrderColumns ? parts[7] : parts[3]),
            orElse: () => SaleType.retail,
          ),
          ratePerUnit: double.parse(hasOrderColumns ? parts[8] : parts[4]),
          quantity: int.parse(hasOrderColumns ? parts[9] : parts[5]),
          costPerUnit: double.parse(hasOrderColumns ? parts[10] : parts[6]),
          paymentStatus: parts.length > (hasOrderColumns ? 14 : 10)
              ? PaymentStatus.values.firstWhere((e) => e.displayName == (hasOrderColumns ? parts[14] : parts[10]), orElse: () => PaymentStatus.paid)
              : PaymentStatus.paid,
          paidAmount: parts.length > (hasOrderColumns ? 15 : 11)
              ? double.tryParse(hasOrderColumns ? parts[15] : parts[11])
              : null,
          notes: hasOrderColumns
              ? (parts.length > 17 ? parts[17] : null)
              : (parts.length > 13 ? parts[13] : (parts.length > 10 && parts.length < 13 ? parts[10] : null)),
        );

        await insertSalesEntry(entry);
        imported++;
      } catch (e) {
        // Skip malformed rows
        continue;
      }
    }
    return imported;
  }

  /// Delete all data (with caution)
  Future<void> deleteAllData() async {
    final db = await database;
    await db.delete(salesTable);
    await db.delete(shopsTable);
    await db.delete('expenses');
    await db.delete(supplyTemplatesTable);
    await db.delete(appSettingsTable);
    await db.delete(syncQueueTable);
  }

  // ==================== SYNC HELPERS ====================

  Future<void> _enqueueSyncUpsert({
    required String entityType,
    required int entityLocalId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert(
      syncQueueTable,
      {
        'entity_type': entityType,
        'entity_local_id': entityLocalId,
        'operation': _syncOperationUpsert,
        'firestore_id': payload['firestore_id'] as String?,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _enqueueSyncDelete({
    required String entityType,
    required int entityLocalId,
    String? firestoreId,
  }) async {
    final db = await database;
    await db.insert(
      syncQueueTable,
      {
        'entity_type': entityType,
        'entity_local_id': entityLocalId,
        'operation': _syncOperationDelete,
        'firestore_id': firestoreId,
        'payload': null,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    final db = await database;
    return db.query(syncQueueTable, orderBy: 'created_at ASC');
  }

  Future<void> removeSyncQueueItem(int queueId) async {
    final db = await database;
    await db.delete(syncQueueTable, where: 'id = ?', whereArgs: [queueId]);
  }

  Future<void> markSyncQueueFailed(int queueId, Object error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $syncQueueTable SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error.toString(), queueId],
    );
  }

  Future<List<SalesEntry>> getUnsyncedSales() async {
    final db = await database;
    final result = await db.query(salesTable, where: 'is_synced = 0');
    return result.map((map) => SalesEntry.fromMap(map)).toList();
  }

  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final result = await db.query('expenses', where: 'is_synced = 0');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  Future<void> markSaleAsSynced(int id, String firestoreId) async {
    final db = await database;
    await db.update(
      salesTable,
      {'is_synced': 1, 'firestore_id': firestoreId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markExpenseAsSynced(int id, String firestoreId) async {
    final db = await database;
    await db.update(
      'expenses',
      {'is_synced': 1, 'firestore_id': firestoreId},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== DISPATCH LEAVES ====================

  Future<bool> hasDispatchLeave(int templateId, DateTime date, DeliverySlot slot) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T').first;
    final result = await db.query(
      dispatchLeavesTable,
      columns: ['id'],
      where: 'template_id = ? AND leave_date = ? AND delivery_slot = ?',
      whereArgs: [templateId, dateStr, slot.index],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> insertDispatchLeave(DispatchLeave leave) async {
    final db = await database;
    await db.insert(dispatchLeavesTable, leave.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> deleteDispatchLeave(int templateId, DateTime date, DeliverySlot slot) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T').first;
    await db.delete(
      dispatchLeavesTable,
      where: 'template_id = ? AND leave_date = ? AND delivery_slot = ?',
      whereArgs: [templateId, dateStr, slot.index],
    );
  }

  Future<Set<String>> getLeaveKeys(List<int> templateIds, DateTime from, DateTime to) async {
    final db = await database;
    final fromStr = from.toIso8601String().split('T').first;
    final toStr = to.toIso8601String().split('T').first;
    final placeholders = List.filled(templateIds.length, '?').join(',');
    final result = await db.rawQuery(
      'SELECT template_id, leave_date, delivery_slot FROM $dispatchLeavesTable '
      'WHERE template_id IN ($placeholders) AND leave_date >= ? AND leave_date <= ?',
      [...templateIds, fromStr, toStr],
    );
    return result.map((r) => '${r['template_id']}_${r['leave_date']}_${r['delivery_slot']}').toSet();
  }

  Future<bool> hasDispatchEntry(int templateId, DateTime date, DeliverySlot slot) async {
    final db = await database;
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end = DateTime(date.year, date.month, date.day + 1).toIso8601String();
    final result = await db.rawQuery('''
      SELECT id FROM $salesTable
      WHERE order_type = ${OrderType.everydaySupply.index}
        AND delivery_slot = ${slot.index}
        AND date >= ? AND date < ?
        AND id IN (
          SELECT id FROM $salesTable WHERE shopName = (
            SELECT shop_name FROM $supplyTemplatesTable WHERE id = ?
          )
        )
    ''', [start, end, templateId]);
    return result.isNotEmpty;
  }
}
