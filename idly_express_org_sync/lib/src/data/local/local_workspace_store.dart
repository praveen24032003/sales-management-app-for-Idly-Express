import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalWorkspaceStore {
  static const _databaseName = 'idly_express_org_sync_cache.db';
  static const _databaseVersion = 1;
  static const _cacheTable = 'cache_records';
  static const _queueTable = 'sync_queue';

  static final LocalWorkspaceStore instance = LocalWorkspaceStore();
  LocalWorkspaceStore();

  Database? _database;
  final Map<String, Map<String, dynamic>> _webCacheRecords = {};
  final List<Map<String, dynamic>> _webQueue = [];
  int _nextWebQueueId = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    _database = await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_cacheTable (
        entity_type TEXT NOT NULL,
        record_id TEXT NOT NULL,
        organization_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (entity_type, record_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE $_queueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        record_id TEXT NOT NULL,
        organization_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        UNIQUE (entity_type, record_id, operation)
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getCachedRecords({
    required String entityType,
    required String organizationId,
  }) async {
    if (kIsWeb) {
      final rows = _webCacheRecords.values
          .where(
            (row) => row['entity_type'] == entityType && row['organization_id'] == organizationId,
          )
          .toList()
        ..sort((left, right) => (right['updated_at'] as int).compareTo(left['updated_at'] as int));

      return rows
          .map((row) => Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map))
          .toList();
    }

    final db = await database;
    final rows = await db.query(
      _cacheTable,
      where: 'entity_type = ? AND organization_id = ?',
      whereArgs: [entityType, organizationId],
      orderBy: 'updated_at DESC',
    );

    return rows
        .map((row) => Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map))
        .toList();
  }

  Future<void> replaceCachedRecords({
    required String entityType,
    required String organizationId,
    required List<Map<String, dynamic>> records,
  }) async {
    if (kIsWeb) {
      _webCacheRecords.removeWhere(
        (_, row) => row['entity_type'] == entityType && row['organization_id'] == organizationId,
      );

      for (final record in records) {
        _webCacheRecords[_cacheKey(entityType, record['id'] as String)] = {
          'entity_type': entityType,
          'record_id': record['id'] as String,
          'organization_id': organizationId,
          'payload': jsonEncode(record),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        };
      }
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        _cacheTable,
        where: 'entity_type = ? AND organization_id = ?',
        whereArgs: [entityType, organizationId],
      );

      for (final record in records) {
        await txn.insert(_cacheTable, {
          'entity_type': entityType,
          'record_id': record['id'] as String,
          'organization_id': organizationId,
          'payload': jsonEncode(record),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<void> upsertCachedRecord({
    required String entityType,
    required String organizationId,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    if (kIsWeb) {
      _webCacheRecords[_cacheKey(entityType, recordId)] = {
        'entity_type': entityType,
        'record_id': recordId,
        'organization_id': organizationId,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      return;
    }

    final db = await database;
    await db.insert(
      _cacheTable,
      {
        'entity_type': entityType,
        'record_id': recordId,
        'organization_id': organizationId,
        'payload': jsonEncode(payload),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeCachedRecord({
    required String entityType,
    required String recordId,
  }) async {
    if (kIsWeb) {
      _webCacheRecords.remove(_cacheKey(entityType, recordId));
      return;
    }

    final db = await database;
    await db.delete(
      _cacheTable,
      where: 'entity_type = ? AND record_id = ?',
      whereArgs: [entityType, recordId],
    );
  }

  Future<void> enqueueOperation({
    required String entityType,
    required String recordId,
    required String organizationId,
    required String operation,
    Map<String, dynamic>? payload,
  }) async {
    if (kIsWeb) {
      _webQueue.removeWhere(
        (row) =>
            row['entity_type'] == entityType &&
            row['record_id'] == recordId &&
            row['operation'] == operation,
      );
      _webQueue.add({
        'id': _nextWebQueueId++,
        'entity_type': entityType,
        'record_id': recordId,
        'organization_id': organizationId,
        'operation': operation,
        'payload': payload,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
      });
      return;
    }

    final db = await database;
    await db.insert(
      _queueTable,
      {
        'entity_type': entityType,
        'record_id': recordId,
        'organization_id': organizationId,
        'operation': operation,
        'payload': payload == null ? null : jsonEncode(payload),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'retry_count': 0,
        'last_error': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getPendingQueue({String? organizationId}) async {
    if (kIsWeb) {
      final rows = _webQueue
          .where((row) => organizationId == null || row['organization_id'] == organizationId)
          .toList()
        ..sort((left, right) => (left['created_at'] as int).compareTo(right['created_at'] as int));
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }

    final db = await database;
    final rows = await db.query(
      _queueTable,
      where: organizationId == null ? null : 'organization_id = ?',
      whereArgs: organizationId == null ? null : [organizationId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map((row) => {
              ...row,
              'payload': row['payload'] == null
                  ? null
                  : Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPendingQueueForEntity({
    required String entityType,
    required String organizationId,
  }) async {
    if (kIsWeb) {
      final rows = _webQueue
          .where(
            (row) => row['entity_type'] == entityType && row['organization_id'] == organizationId,
          )
          .toList()
        ..sort((left, right) => (left['created_at'] as int).compareTo(right['created_at'] as int));
      return rows.map((row) => Map<String, dynamic>.from(row)).toList();
    }

    final db = await database;
    final rows = await db.query(
      _queueTable,
      where: 'entity_type = ? AND organization_id = ?',
      whereArgs: [entityType, organizationId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map((row) => {
              ...row,
              'payload': row['payload'] == null
                  ? null
                  : Map<String, dynamic>.from(jsonDecode(row['payload'] as String) as Map),
            })
        .toList();
  }

  Future<void> removeQueueItem(int id) async {
    if (kIsWeb) {
      _webQueue.removeWhere((row) => row['id'] == id);
      return;
    }

    final db = await database;
    await db.delete(_queueTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markQueueFailed(int id, Object error) async {
    if (kIsWeb) {
      final index = _webQueue.indexWhere((row) => row['id'] == id);
      if (index == -1) return;
      final row = Map<String, dynamic>.from(_webQueue[index]);
      row['retry_count'] = (row['retry_count'] as int) + 1;
      row['last_error'] = error.toString();
      _webQueue[index] = row;
      return;
    }

    final db = await database;
    await db.rawUpdate(
      'UPDATE $_queueTable SET retry_count = retry_count + 1, last_error = ? WHERE id = ?',
      [error.toString(), id],
    );
  }

  String _cacheKey(String entityType, String recordId) => '$entityType::$recordId';
}