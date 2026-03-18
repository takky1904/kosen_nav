import 'package:postgres/postgres.dart';

class DB {
  DB._();
  static final instance = DB._();

  Connection? _connection;
  bool _isInitialized = false;

  Future<Connection> get connection async {
    if (_connection != null && !_connection!.isOpen) {
      _connection = null;
    }

    _connection ??= await Connection.open(
      Endpoint(
        host: 'localhost', // Dockerで動かしているDBの住所
        database: 'kosen_nav',
        username: 'user',
        password: 'password',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    if (_isInitialized) return _connection!;

    // 接続が確立した直後にテーブルと必要カラムを保証する
    try {
      final conn = _connection!;
      
      // テーブルの作成（存在しない場合）
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS tasks (
          id SERIAL PRIMARY KEY,
          title TEXT NOT NULL,
          subject_id TEXT,
          type TEXT,
          priority TEXT,
          deadline TEXT,
          status TEXT,
          start_date TEXT,
          duration DOUBLE PRECISION
        );
      ''');

      // カラムの追加（既存テーブルへの対応）
      await conn.execute('ALTER TABLE tasks ADD COLUMN IF NOT EXISTS subject_id TEXT;');
      await conn.execute('ALTER TABLE tasks ADD COLUMN IF NOT EXISTS type TEXT;');
      await conn.execute('ALTER TABLE tasks ADD COLUMN IF NOT EXISTS start_date TEXT;');
      await conn.execute('ALTER TABLE tasks ADD COLUMN IF NOT EXISTS duration DOUBLE PRECISION DEFAULT 1.0;');

      // duration カラムの型が integer の場合は double precision に変更する
      // (Postgres 15+ では ALTER COLUMN TYPE が柔軟)
      try {
        await conn.execute('ALTER TABLE tasks ALTER COLUMN duration TYPE DOUBLE PRECISION;');
      } catch (e) {
        print('Note: Could not alter duration column type (might already be DOUBLE PRECISION): $e');
      }

      // 旧カラム subject から subject_id への移行
      try {
        // subject カラムが存在するかチェック
        final columns = await conn.execute(
          "SELECT column_name FROM information_schema.columns WHERE table_name='tasks' AND column_name='subject'",
        );
        if (columns.isNotEmpty) {
          await conn.execute('UPDATE tasks SET subject_id = subject WHERE subject_id IS NULL AND subject IS NOT NULL;');
          // メモ: 本番環境では不用意に DROP しないほうが安全だが、今回は移行中なのでそのままでもOK
        }
      } catch (e) {
        print('Note: Migration from subject to subject_id skipped or failed: $e');
      }

      // status のデフォルト値を英語の enum 名に変更 (古いデータ対策)
      await conn.execute("ALTER TABLE tasks ALTER COLUMN status SET DEFAULT 'todo';");

      // subjects テーブルの作成
      await conn.execute('''
        CREATE TABLE IF NOT EXISTS subjects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          units INTEGER DEFAULT 2,
          test_scores TEXT, -- JSON string of List<double?>
          regular_score DOUBLE PRECISION,
          test_weight DOUBLE PRECISION DEFAULT 0.7,
          regular_weight DOUBLE PRECISION DEFAULT 0.3,
          teacher TEXT,
          color TEXT,
          grade INTEGER
        );
      ''');
      _isInitialized = true;
    } catch (e, st) {
      print('Error ensuring table schemas: $e');
      print(st);
      rethrow;
    }
    return _connection!;
  }

  // ── Tasks ──────────────────────────────────────────

  // タスク一覧を取得する
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final conn = await connection;
      final result = await conn.execute('SELECT * FROM tasks ORDER BY id DESC');
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e, st) {
      print('getTasks error: $e');
      print(st);
      rethrow;
    }
  }

  // 新しいタスクを保存する
  Future<int> insertTask(Map<String, dynamic> data) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named(
            'INSERT INTO tasks (title, subject_id, type, priority, deadline, status, start_date, duration) VALUES (@title, @subject_id, @type, @priority, @deadline, @status, @start_date, @duration) RETURNING id',),
        parameters: {
          'title': data['title'],
          'subject_id': data['subject_id'], // Pass null if null
          'type': data['type'] ?? 'homework',
          'priority': data['priority'] ?? 'medium',
          'deadline': data['deadline'] ?? '',
          'status': data['status'] ?? 'todo',
          'start_date': data['start_date'] ?? '',
          'duration': data['duration'],
        },
      );
      return result.first[0]! as int;
    } catch (e, st) {
      print('insertTask error: $e');
      print(st);
      rethrow;
    }
  }

  // 指定 ID のタスクを更新する
  Future<int> updateTask(int id, Map<String, dynamic> data) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named(
            'UPDATE tasks SET title = @title, subject_id = @subject_id, type = @type, priority = @priority, deadline = @deadline, status = @status, start_date = @start_date, duration = @duration WHERE id = @id RETURNING id',),
        parameters: {
          'id': id,
          'title': data['title'],
          'subject_id': data['subject_id'], // Pass null if null
          'type': data['type'] ?? 'homework',
          'priority': data['priority'] ?? 'medium',
          'deadline': data['deadline'] ?? '',
          'status': data['status'] ?? 'todo',
          'start_date': data['start_date'] ?? '',
          'duration': data['duration'],
        },
      );
      if (result.isEmpty) {
        throw Exception('No task found with id: $id');
      }
      return result.first[0]! as int;
    } catch (e, st) {
      print('updateTask error: $e');
      print(st);
      rethrow;
    }
  }

  // 指定 ID のタスクを削除する
  Future<void> deleteTask(int id) async {
    try {
      final conn = await connection;
      await conn.execute(
        Sql.named('DELETE FROM tasks WHERE id = @id'),
        parameters: {'id': id},
      );
    } catch (e, st) {
      print('deleteTask error: $e');
      print(st);
      rethrow;
    }
  }

  // ── Subjects ───────────────────────────────────────

  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final conn = await connection;
      final result = await conn.execute('SELECT * FROM subjects ORDER BY id');
      return result.map((row) => row.toColumnMap()).toList();
    } catch (e, st) {
      print('getSubjects error: $e');
      print(st);
      rethrow;
    }
  }

  Future<void> insertSubject(Map<String, dynamic> data) async {
    try {
      final conn = await connection;
      await conn.execute(
        Sql.named(
          'INSERT INTO subjects (id, name, units, test_scores, regular_score, test_weight, regular_weight, teacher, color, grade) '
          'VALUES (@id, @name, @units, @test_scores, @regular_score, @test_weight, @regular_weight, @teacher, @color, @grade)',
        ),
        parameters: {
          'id': data['id'],
          'name': data['name'],
          'units': data['units'],
          'test_scores': data['test_scores'],
          'regular_score': data['regular_score'],
          'test_weight': data['test_weight'],
          'regular_weight': data['regular_weight'],
          'teacher': data['teacher'],
          'color': data['color'],
          'grade': data['grade'],
        },
      );
    } catch (e, st) {
      print('insertSubject error: $e');
      print(st);
      rethrow;
    }
  }

  Future<void> updateSubject(String id, Map<String, dynamic> data) async {
    try {
      final conn = await connection;
      await conn.execute(
        Sql.named(
          'UPDATE subjects SET name = @name, units = @units, test_scores = @test_scores, regular_score = @regular_score, '
          'test_weight = @test_weight, regular_weight = @regular_weight, teacher = @teacher, color = @color, grade = @grade '
          'WHERE id = @id',
        ),
        parameters: {
          'id': id,
          'name': data['name'],
          'units': data['units'],
          'test_scores': data['test_scores'],
          'regular_score': data['regular_score'],
          'test_weight': data['test_weight'],
          'regular_weight': data['regular_weight'],
          'teacher': data['teacher'],
          'color': data['color'],
          'grade': data['grade'],
        },
      );
    } catch (e, st) {
      print('updateSubject error: $e');
      print(st);
      rethrow;
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      final conn = await connection;
      await conn.execute(
        Sql.named('DELETE FROM subjects WHERE id = @id'),
        parameters: {'id': id},
      );
    } catch (e, st) {
      print('deleteSubject error: $e');
      print(st);
      rethrow;
    }
  }
}
