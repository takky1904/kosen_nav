import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'sync_status.dart';

class LocalDatabase {
  LocalDatabase._();

  static const String _dbName = 'kosenar.db';
  static const int _dbVersion = 7;

  static Database? _instance;

  static Future<Database> get instance async {
    if (_instance != null) return _instance!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _instance = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _instance!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        remote_id TEXT,
        title TEXT NOT NULL,
        subject_id TEXT,
        type TEXT NOT NULL,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        start_date TEXT NOT NULL,
        deadline TEXT NOT NULL,
        estimated_hours REAL NOT NULL,
        sync_status TEXT NOT NULL DEFAULT '${SyncStatus.synced}',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        remote_id TEXT,
        name TEXT NOT NULL,
        credits INTEGER NOT NULL,
        units INTEGER NOT NULL,
        teacher TEXT,
        exam_ratio INTEGER,
        test_scores_json TEXT NOT NULL,
        evaluations_json TEXT NOT NULL DEFAULT '[]',
        periodic_tests_json TEXT NOT NULL DEFAULT '{"ratio":0,"count":4,"scores":[null,null,null,null]}',
        variable_components_json TEXT NOT NULL DEFAULT '[]',
        regular_score REAL,
        test_weight REAL NOT NULL,
        sync_status TEXT NOT NULL DEFAULT '${SyncStatus.synced}',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_tasks_sync_status ON tasks(sync_status)',
    );
    await db.execute(
      'CREATE INDEX idx_courses_sync_status ON courses(sync_status)',
    );

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        kosen_name TEXT,
        grade INTEGER,
        course_id TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateTableForSyncColumns(db, 'tasks');
      await _migrateTableForSyncColumns(db, 'courses');

      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_tasks_sync_status ON tasks(sync_status)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_courses_sync_status ON courses(sync_status)',
      );
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          kosen_name TEXT,
          grade INTEGER,
          course_id TEXT,
          updated_at INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      if (!await _columnExists(db, 'courses', 'credits')) {
        await db.execute('ALTER TABLE courses ADD COLUMN credits INTEGER');
        await db.execute(
          'UPDATE courses SET credits = units WHERE credits IS NULL',
        );
      }

      if (!await _columnExists(db, 'courses', 'teacher')) {
        await db.execute('ALTER TABLE courses ADD COLUMN teacher TEXT');
      }

      if (!await _columnExists(db, 'courses', 'exam_ratio')) {
        await db.execute('ALTER TABLE courses ADD COLUMN exam_ratio INTEGER');
      }
    }

    if (oldVersion < 5) {
      // Cleanup: remove courses imported by the legacy syllabus sync flow.
      await db.delete(
        'courses',
        where:
            'exam_ratio IS NOT NULL OR (teacher IS NOT NULL AND TRIM(teacher) != "")',
      );
    }

    if (oldVersion < 6) {
      if (!await _columnExists(db, 'courses', 'evaluations_json')) {
        await db.execute(
          "ALTER TABLE courses ADD COLUMN evaluations_json TEXT NOT NULL DEFAULT '[]'",
        );
      }
    }

    if (oldVersion < 7) {
      if (!await _columnExists(db, 'courses', 'periodic_tests_json')) {
        await db.execute(
          "ALTER TABLE courses ADD COLUMN periodic_tests_json TEXT NOT NULL DEFAULT '{\"ratio\":0,\"count\":4,\"scores\":[null,null,null,null]}'",
        );
      }

      if (!await _columnExists(db, 'courses', 'variable_components_json')) {
        await db.execute(
          "ALTER TABLE courses ADD COLUMN variable_components_json TEXT NOT NULL DEFAULT '[]'",
        );
      }
    }
  }

  static Future<void> _migrateTableForSyncColumns(
    Database db,
    String table,
  ) async {
    if (!await _columnExists(db, table, 'remote_id')) {
      await db.execute('ALTER TABLE $table ADD COLUMN remote_id TEXT');
    }

    if (!await _columnExists(db, table, 'sync_status')) {
      await db.execute(
        "ALTER TABLE $table ADD COLUMN sync_status TEXT NOT NULL DEFAULT '${SyncStatus.synced}'",
      );
    }

    if (!await _columnExists(db, table, 'updated_at')) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
      );
    }

    await db.update(table, <String, Object>{
      'sync_status': SyncStatus.synced,
    }, where: 'sync_status IS NULL OR sync_status = ""');
  }

  static Future<bool> _columnExists(
    Database db,
    String table,
    String column,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return rows.any((row) => row['name'] == column);
  }
}
