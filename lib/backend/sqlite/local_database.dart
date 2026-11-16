import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Top-level accessor for the local SQLite database.
LocalDatabase get localDb => LocalDatabase.instance;

class LocalDatabase {
  LocalDatabase._();
  static final LocalDatabase instance = LocalDatabase._();

  static const String dbName = 'broadcast_automator.db';
  Database? _db;

  final StreamController<String> _tableChangeController =
      StreamController<String>.broadcast();

  Stream<String> get onTableChange => _tableChangeController.stream;

  Future<void> init() async {
    await database;
    await cleanupOrphanedCampaigns();
  }

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        try {
          await db.execute('PRAGMA foreign_keys = ON;');
        } catch (_) {}
        try {
          // PRAGMA journal_mode returns a result row, so rawQuery must be used instead of execute
          await db.rawQuery('PRAGMA journal_mode = WAL;');
        } catch (_) {}
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onOpen: (db) async {
        await _createTables(db);
        await _migrateColumns(db);
        await _cleanupOrphaned(db);
      },
    );
  }

  static Future<void> _migrateColumns(Database db) async {
    try {
      await db.execute('ALTER TABLE campaigns ADD COLUMN custom_columns TEXT;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE contacts ADD COLUMN extra_fields TEXT;');
    } catch (_) {}
  }

  static Future<void> _cleanupOrphaned(Database db) async {
    try {
      await db.delete(
        'campaigns',
        where:
            "status = 'Ready' AND id NOT IN (SELECT DISTINCT campaign_id FROM contacts WHERE campaign_id IS NOT NULL)",
      );
    } catch (_) {}
  }

  Future<void> cleanupOrphanedCampaigns() async {
    try {
      final db = await database;
      await _cleanupOrphaned(db);
      notifyTableChanged('campaigns');
    } catch (e) {
      print('Error cleaning up orphaned campaigns: $e');
    }
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS campaigns (
        id TEXT PRIMARY KEY,
        device_id TEXT,
        name TEXT NOT NULL DEFAULT '',
        contact_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        status TEXT,
        message_body TEXT,
        delay_seconds INTEGER,
        randomize_delay INTEGER DEFAULT 1,
        skip_invalid INTEGER DEFAULT 1,
        auto_retry INTEGER DEFAULT 0,
        current_index INTEGER DEFAULT 0,
        custom_columns TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contacts (
        id TEXT PRIMARY KEY,
        campaign_id TEXT,
        name TEXT,
        phone TEXT,
        status TEXT,
        extra_fields TEXT,
        FOREIGN KEY (campaign_id) REFERENCES campaigns (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_contacts_campaign_id ON contacts (campaign_id);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS attachments (
        id TEXT PRIMARY KEY,
        campaign_id TEXT,
        source_url TEXT,
        type TEXT,
        FOREIGN KEY (campaign_id) REFERENCES campaigns (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_attachments_campaign_id ON attachments (campaign_id);');
  }

  void notifyTableChanged(String table) {
    if (!_tableChangeController.isClosed) {
      _tableChangeController.add(table);
    }
  }

  void notifyAll() {
    notifyTableChanged('campaigns');
    notifyTableChanged('contacts');
    notifyTableChanged('attachments');
  }

  // ---------------------------------------------------------------------------
  // CRUD Operations
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    if (copy['id'] == null || copy['id'].toString().isEmpty) {
      copy['id'] = const Uuid().v4();
    }
    // Normalize booleans to integers (1 / 0) for SQLite storage
    for (final key in copy.keys) {
      final value = copy[key];
      if (value is bool) {
        copy[key] = value ? 1 : 0;
      }
    }
    return copy;
  }

  Map<String, dynamic> _denormalizeRow(
      String table, Map<String, dynamic> data) {
    final copy = Map<String, dynamic>.from(data);
    if (table == 'campaigns') {
      if (copy.containsKey('randomize_delay')) {
        copy['randomize_delay'] = copy['randomize_delay'] == 1 ||
            copy['randomize_delay'] == true;
      }
      if (copy.containsKey('skip_invalid')) {
        copy['skip_invalid'] =
            copy['skip_invalid'] == 1 || copy['skip_invalid'] == true;
      }
      if (copy.containsKey('auto_retry')) {
        copy['auto_retry'] =
            copy['auto_retry'] == 1 || copy['auto_retry'] == true;
      }
    }
    return copy;
  }

  Future<List<Map<String, dynamic>>> insert(String table, dynamic data) async {
    final db = await database;
    if (data is Map<String, dynamic>) {
      final row = _normalizeRow(data);
      await db.insert(table, row,
          conflictAlgorithm: ConflictAlgorithm.replace);
      notifyTableChanged(table);
      return [_denormalizeRow(table, row)];
    } else if (data is List) {
      final batch = db.batch();
      final insertedRows = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final row = _normalizeRow(item);
          batch.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
          insertedRows.add(_denormalizeRow(table, row));
        }
      }
      await batch.commit(noResult: true);
      notifyTableChanged(table);
      return insertedRows;
    }
    return [];
  }

  Future<int> update(
    String table,
    Map<String, dynamic> data, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    final row = Map<String, dynamic>.from(data);
    for (final key in row.keys) {
      final value = row[key];
      if (value is bool) {
        row[key] = value ? 1 : 0;
      }
    }
    final count =
        await db.update(table, row, where: where, whereArgs: whereArgs);
    notifyTableChanged(table);
    return count;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    final count = await db.delete(table, where: where, whereArgs: whereArgs);
    notifyTableChanged(table);
    return count;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await database;
      final rows = await db.query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );
      return rows.map((r) => _denormalizeRow(table, r)).toList();
    } catch (e) {
      print('LocalDatabase query error on $table: $e');
      return [];
    }
  }

  Future<int> queryCount(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    try {
      final db = await database;
      final sql =
          'SELECT COUNT(*) FROM $table${where != null && where.isNotEmpty ? ' WHERE $where' : ''}';
      final count =
          Sqflite.firstIntValue(await db.rawQuery(sql, whereArgs)) ?? 0;
      return count;
    } catch (e) {
      print('LocalDatabase queryCount error on $table: $e');
      return 0;
    }
  }

  // ---------------------------------------------------------------------------
  // Reactive Streams
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> streamQuery(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async* {
    List<Map<String, dynamic>> initialRows = [];
    try {
      initialRows = await query(
        table,
        where: where,
        whereArgs: whereArgs,
        orderBy: orderBy,
        limit: limit,
      );
    } catch (e) {
      print('LocalDatabase streamQuery initial fetch error: $e');
    }
    yield initialRows;

    await for (final changedTable in onTableChange) {
      if (changedTable == table) {
        List<Map<String, dynamic>> updatedRows = [];
        try {
          updatedRows = await query(
            table,
            where: where,
            whereArgs: whereArgs,
            orderBy: orderBy,
            limit: limit,
          );
        } catch (e) {
          print('LocalDatabase streamQuery update fetch error: $e');
        }
        yield updatedRows;
      }
    }
  }

  Stream<Map<String, dynamic>?> streamDocument(
      String table, String id) async* {
    Map<String, dynamic>? initialDoc;
    try {
      final initial = await query(table, where: 'id = ?', whereArgs: [id]);
      if (initial.isNotEmpty) initialDoc = initial.first;
    } catch (e) {
      print('LocalDatabase streamDocument initial fetch error: $e');
    }
    yield initialDoc;

    await for (final changedTable in onTableChange) {
      if (changedTable == table) {
        Map<String, dynamic>? updatedDoc;
        try {
          final rows = await query(table, where: 'id = ?', whereArgs: [id]);
          if (rows.isNotEmpty) updatedDoc = rows.first;
        } catch (e) {
          print('LocalDatabase streamDocument update fetch error: $e');
        }
        yield updatedDoc;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Fluent Query Facade (drop-in replacement for supabase.from(table))
  // ---------------------------------------------------------------------------

  LocalTableQuery from(String table) => LocalTableQuery(this, table);
}

class LocalTableQuery {
  final LocalDatabase db;
  final String tableName;

  LocalTableQuery(this.db, this.tableName);

  LocalInsertBuilder insert(dynamic data) =>
      LocalInsertBuilder(db, tableName, data);

  LocalUpdateBuilder update(Map<String, dynamic> data) =>
      LocalUpdateBuilder(db, tableName, data);

  LocalDeleteBuilder delete() => LocalDeleteBuilder(db, tableName);

  LocalSelectBuilder select([String columns = '*']) =>
      LocalSelectBuilder(db, tableName);
}

class LocalInsertBuilder implements Future<List<Map<String, dynamic>>> {
  final LocalDatabase db;
  final String tableName;
  final dynamic data;
  late final Future<List<Map<String, dynamic>>> _future;

  LocalInsertBuilder(this.db, this.tableName, this.data) {
    _future = db.insert(tableName, data);
  }

  LocalSelectBuilder select([String columns = '*']) =>
      LocalSelectBuilder(db, tableName, future: _future);

  Future<Map<String, dynamic>> single() async {
    final list = await _future;
    return list.isNotEmpty ? list.first : <String, dynamic>{};
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _future.asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(
          FutureOr<R> Function(List<Map<String, dynamic>> value) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
          {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
          FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}

class LocalUpdateBuilder {
  final LocalDatabase db;
  final String tableName;
  final Map<String, dynamic> data;

  LocalUpdateBuilder(this.db, this.tableName, this.data);

  Future<int> eq(String field, Object? value) async {
    return await db.update(
      tableName,
      data,
      where: '$field = ?',
      whereArgs: [value],
    );
  }
}

class LocalDeleteBuilder {
  final LocalDatabase db;
  final String tableName;

  LocalDeleteBuilder(this.db, this.tableName);

  Future<int> eq(String field, Object? value) async {
    return await db.delete(
      tableName,
      where: '$field = ?',
      whereArgs: [value],
    );
  }
}

class LocalSelectBuilder implements Future<List<Map<String, dynamic>>> {
  final LocalDatabase db;
  final String tableName;
  late final Future<List<Map<String, dynamic>>> _future;

  LocalSelectBuilder(this.db, this.tableName,
      {Future<List<Map<String, dynamic>>>? future}) {
    _future = future ?? db.query(tableName);
  }

  Future<Map<String, dynamic>> single() async {
    final list = await _future;
    return list.isNotEmpty ? list.first : <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> eq(String field, Object? value) async {
    return await db.query(
      tableName,
      where: '$field = ?',
      whereArgs: [value],
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> asStream() => _future.asStream();

  @override
  Future<List<Map<String, dynamic>>> catchError(Function onError,
          {bool Function(Object error)? test}) =>
      _future.catchError(onError, test: test);

  @override
  Future<R> then<R>(
          FutureOr<R> Function(List<Map<String, dynamic>> value) onValue,
          {Function? onError}) =>
      _future.then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> timeout(Duration timeLimit,
          {FutureOr<List<Map<String, dynamic>>> Function()? onTimeout}) =>
      _future.timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
          FutureOr<void> Function() action) =>
      _future.whenComplete(action);
}
