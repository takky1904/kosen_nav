import 'dart:async';

import 'package:sqflite/sqflite.dart';

import '../../../data/local/local_database.dart';
import '../../../data/local/sync_status.dart';
import '../domain/task.dart';

/// Local-first タスク管理リポジトリ
class TaskRepository {
  final StreamController<List<TaskModel>> _tasksController =
      StreamController<List<TaskModel>>.broadcast();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _emitTasks();
  }

  Stream<List<TaskModel>> getTasksStream() async* {
    await _ensureInitialized();
    yield await fetchTasks();
    yield* _tasksController.stream;
  }

  /// ローカルDBから論理削除されていないタスクを取得
  Future<List<TaskModel>> fetchTasks() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'tasks',
      where: 'sync_status != ?',
      whereArgs: <Object>[SyncStatus.pendingDelete],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapTaskRowToModel).toList();
  }

  /// タスクをローカル保存 (未同期の新規作成)
  Future<TaskModel> createTask(TaskModel task) async {
    final db = await LocalDatabase.instance;
    await db.insert(
      'tasks',
      _mapTaskModelToRow(
        task,
        remoteId: null,
        syncStatus: SyncStatus.pendingInsert,
        updatedAt: DateTime.now(),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitTasks();
    return task;
  }

  /// タスク更新をローカルに反映し同期状態を pending_update へ遷移
  Future<TaskModel> updateTask(TaskModel task) async {
    final db = await LocalDatabase.instance;
    final existing = await db.query(
      'tasks',
      columns: <String>['sync_status', 'remote_id'],
      where: 'id = ?',
      whereArgs: <Object>[task.id],
      limit: 1,
    );

    final currentSyncStatus = existing.isEmpty
        ? null
        : existing.first['sync_status']?.toString();
    final currentRemoteId = existing.isEmpty
        ? null
        : existing.first['remote_id']?.toString();
    final nextSyncStatus = currentSyncStatus == SyncStatus.pendingInsert
        ? SyncStatus.pendingInsert
        : SyncStatus.pendingUpdate;

    await db.update(
      'tasks',
      _mapTaskModelToRow(
        task,
        remoteId: currentRemoteId,
        syncStatus: nextSyncStatus,
        updatedAt: DateTime.now(),
      ),
      where: 'id = ?',
      whereArgs: <Object>[task.id],
    );
    await _emitTasks();
    return task;
  }

  /// タスクを論理削除 (pending_delete)
  Future<void> deleteTask(String id) async {
    final db = await LocalDatabase.instance;
    final existing = await db.query(
      'tasks',
      columns: <String>['sync_status'],
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (existing.isEmpty) return;

    final currentSyncStatus = existing.first['sync_status']?.toString();

    if (currentSyncStatus == SyncStatus.pendingInsert) {
      // まだサーバー未送信のレコードは物理削除でよい。
      await db.delete('tasks', where: 'id = ?', whereArgs: <Object>[id]);
    } else {
      await db.update(
        'tasks',
        <String, Object>{
          'sync_status': SyncStatus.pendingDelete,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }

    await _emitTasks();
  }

  Future<void> _emitTasks() async {
    final tasks = await fetchTasks();
    if (!_tasksController.isClosed) {
      _tasksController.add(tasks);
    }
  }

  Map<String, Object?> _mapTaskModelToRow(
    TaskModel task, {
    required String? remoteId,
    required String syncStatus,
    required DateTime updatedAt,
  }) {
    return <String, Object?>{
      'id': task.id,
      'remote_id': remoteId,
      'title': task.title,
      'subject_id': task.subjectId,
      'type': task.type.name,
      'priority': task.priority.name,
      'status': task.status.name,
      'start_date': task.startDate.toIso8601String(),
      'deadline': task.deadline.toIso8601String(),
      'estimated_hours': task.estimatedHours,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  TaskModel _mapTaskRowToModel(Map<String, Object?> row) {
    return TaskModel(
      id: row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      subjectId: row['subject_id']?.toString(),
      type: TaskType.values.firstWhere(
        (type) => type.name == row['type'],
        orElse: () => TaskType.homework,
      ),
      priority: TaskPriority.values.firstWhere(
        (priority) => priority.name == row['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (status) => status.name == row['status'],
        orElse: () => TaskStatus.todo,
      ),
      startDate:
          DateTime.tryParse(row['start_date']?.toString() ?? '') ??
          DateTime.now(),
      deadline:
          DateTime.tryParse(row['deadline']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 1)),
      estimatedHours: (row['estimated_hours'] is num)
          ? (row['estimated_hours'] as num).toDouble()
          : double.tryParse(row['estimated_hours']?.toString() ?? '1.0') ?? 1.0,
    );
  }
}
