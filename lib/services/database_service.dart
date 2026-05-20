import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants.dart';
import '../models/sales_entry_model.dart';
import '../models/expense_model.dart';
import '../models/supply_template_model.dart';
import '../models/dispatch_leave_model.dart';

/// Database service for offline-first data storage
class DatabaseService {
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
      version: 7,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // For development simplicity, we'll drop and recreate for v1->v2
      await db.execute('DROP TABLE IF EXISTS $salesTable');
      await db.execute('DROP TABLE IF EXISTS $shopsTable');
      await db.execute('DROP TABLE IF EXISTS expenses');
      await db.execute('DROP TABLE IF EXISTS $supplyTemplatesTable');
      await db.execute('DROP TABLE IF EXISTS $appSettingsTable');
      await _createDB(db, newVersion);
      return;
    }
    
    if (oldVersion < 3) {
      // Add sync columns for v2->v3
      // Sales Table
      await db.execute('ALTER TABLE $salesTable ADD COLUMN firestore_id TEXT');
      await db.execute('ALTER TABLE $salesTable ADD COLUMN last_modified INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $salesTable ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
      
      // Expenses Table
      await db.execute('ALTER TABLE expenses ADD COLUMN firestore_id TEXT');
      await db.execute('ALTER TABLE expenses ADD COLUMN last_modified INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE expenses ADD COLUMN is_synced INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE $salesTable ADD COLUMN order_type INTEGER NOT NULL DEFAULT 1');
      await db.execute('ALTER TABLE $salesTable ADD COLUMN delivery_slot INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $salesTable ADD COLUMN delivery_time TEXT');
      await db.execute('ALTER TABLE $salesTable ADD COLUMN prep_lead_days INTEGER NOT NULL DEFAULT 1');
    }

    if (oldVersion < 5) {
      await db.execute('''
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
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $appSettingsTable (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion >= 5 && oldVersion < 6) {
      await db.execute("ALTER TABLE $supplyTemplatesTable ADD COLUMN active_weekdays TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7'");
      await db.execute('ALTER TABLE $supplyTemplatesTable ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE $supplyTemplatesTable ADD COLUMN end_date TEXT');
    }

    if (oldVersion < 7) {
      // Add mobile column to shops
      await db.execute('ALTER TABLE $shopsTable ADD COLUMN mobile TEXT');
      // Add customer_mobile to sales_entries
      await db.execute('ALTER TABLE $salesTable ADD COLUMN customer_mobile TEXT');
      // Add morning/evening split to supply templates
      await db.execute('ALTER TABLE $supplyTemplatesTable ADD COLUMN morning_quantity INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $supplyTemplatesTable ADD COLUMN evening_quantity INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE $supplyTemplatesTable ADD COLUMN shop_mobile TEXT');
      // Create dispatch_leaves table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $dispatchLeavesTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          leave_date TEXT NOT NULL,
          delivery_slot INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
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

  Future<bool> _hasEverydayOrderForTemplateToday(SupplyTemplate template) async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();

    final result = await db.query(
      salesTable,
      columns: ['id'],
      where: 'shopName = ? AND productType = ? AND saleType = ? AND delivery_slot = ? AND order_type = ? AND date >= ? AND date < ?',
      whereArgs: [
        template.shopName,
        template.productType.index,
        template.saleType.index,
        template.deliverySlot.index,
        OrderType.everydaySupply.index,
        start,
        end,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
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

      final entry = SalesEntry(
        date: DateTime.now(),
        shopName: template.shopName,
        orderType: OrderType.everydaySupply,
        deliverySlot: template.deliverySlot,
        deliveryTime: template.deliveryTime,
        prepLeadDays: template.prepLeadDays,
        productType: template.productType,
        saleType: template.saleType,
        ratePerUnit: template.ratePerUnit,
        quantity: template.quantity,
        costPerUnit: template.costPerUnit,
        paymentStatus: PaymentStatus.pending,
        paidAmount: 0,
        notes: 'Auto-created from recurring template',
      );

      await insertSalesEntry(entry);
      created++;
    }

    await _setSetting(settingLastTemplateGenerationDate, todayKey);
    return created;
  }

  // ==================== SALES CRUD ====================

  /// Insert a new sales entry
  Future<int> insertSalesEntry(SalesEntry entry) async {
    final db = await database;
    
    // Also save/update shop name for suggestions
    await _saveShopName(entry.shopName);
    
    return await db.insert(salesTable, entry.toMap());
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
    return await db.update(
      salesTable,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete a sales entry
  Future<int> deleteSalesEntry(int id) async {
    final db = await database;
    return await db.delete(
      salesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
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

  Future<String?> getShopMobile(String name) async {
    final db = await database;
    final result = await db.query(shopsTable, columns: ['mobile'], where: 'name = ?', whereArgs: [name], limit: 1);
    if (result.isEmpty) return null;
    return result.first['mobile'] as String?;
  }

  Future<List<Map<String, String?>>> getAllShopsWithMobile() async {
    final db = await database;
    final result = await db.query(shopsTable, columns: ['name', 'mobile'], orderBy: 'lastUsed DESC');
    return result.map((r) => {'name': r['name'] as String?, 'mobile': r['mobile'] as String?}).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentExternalCustomers() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT shopName as name, customer_mobile as mobile, MAX(date) as lastUsed
      FROM $salesTable
      WHERE order_type = ${OrderType.externalOrder.index}
        AND customer_mobile IS NOT NULL
        AND customer_mobile != ''
      GROUP BY shopName, customer_mobile
      ORDER BY lastUsed DESC
      LIMIT 30
    ''');
    return result;
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

  // ==================== EXPENSES CRUD ====================

  /// Insert expense
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  /// Delete expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
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
  }

  // ==================== SYNC HELPERS ====================

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
