import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants.dart';
import '../models/sales_entry_model.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Sales entries table
    await db.execute('''
      CREATE TABLE $salesTable (
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
        notes TEXT
      )
    ''');

    // Shops table for auto-suggestions
    await db.execute('''
      CREATE TABLE $shopsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        lastUsed TEXT NOT NULL
      )
    ''');
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

  /// Save shop name for auto-suggestions
  Future<void> _saveShopName(String name) async {
    final db = await database;
    await db.insert(
      shopsTable,
      {'name': name, 'lastUsed': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
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

        final entry = SalesEntry(
          date: DateTime.parse(parts[0]),
          shopName: parts[1],
          productType: ProductType.values.firstWhere(
            (p) => p.displayName == parts[2],
            orElse: () => ProductType.idly,
          ),
          saleType: SaleType.values.firstWhere(
            (s) => s.displayName == parts[3],
            orElse: () => SaleType.retail,
          ),
          ratePerUnit: double.parse(parts[4]),
          quantity: int.parse(parts[5]),
          costPerUnit: double.parse(parts[6]),
          notes: parts.length > 10 ? parts[10] : null,
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
  }
}
