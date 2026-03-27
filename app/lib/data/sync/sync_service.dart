import 'dart:convert';

import '../../features/grades/data/subject_api_client.dart';
import '../../features/grades/domain/subject_model.dart';
import '../../features/tasks/data/api_client.dart';
import '../../features/tasks/domain/task.dart';
import '../local/local_database.dart';
import '../local/sync_status.dart';

class SyncService {
  SyncService({
    TaskApiClient? taskApiClient,
    SubjectApiClient? subjectApiClient,
  }) : _taskApi = taskApiClient ?? TaskApiClient(),
       _subjectApi = subjectApiClient ?? SubjectApiClient();

  final TaskApiClient _taskApi;
  final SubjectApiClient _subjectApi;

  Future<void> pushLocalChanges() async {
    final db = await LocalDatabase.instance;

    await _pushTaskChanges(db);
    await _pushCourseChanges(db);
  }

  Future<void> fetchRemoteChanges() async {
    final db = await LocalDatabase.instance;

    await _fetchRemoteTasks(db);
    await _fetchRemoteCourses(db);
  }

  Future<void> _pushTaskChanges(dynamic db) async {
    final pendingRows = await db.query(
      'tasks',
      where: 'sync_status LIKE ?',
      whereArgs: <Object>['pending_%'],
      orderBy: 'updated_at ASC',
    );

    for (final row in pendingRows) {
      final localId = row['id']?.toString();
      if (localId == null || localId.isEmpty) continue;

      final syncState = row['sync_status']?.toString() ?? '';
      final remoteId = row['remote_id']?.toString();

      try {
        if (syncState == SyncStatus.pendingInsert) {
          final model = _taskFromRow(row);
          final created = await _taskApi.createTask(model);
          await db.update(
            'tasks',
            <String, Object?>{
              'remote_id': created.id,
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        if (syncState == SyncStatus.pendingUpdate) {
          final targetId = (remoteId != null && remoteId.isNotEmpty)
              ? remoteId
              : localId;
          final model = _taskFromRow(row, idOverride: targetId);
          await _taskApi.updateTask(model);
          await db.update(
            'tasks',
            <String, Object>{
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        if (syncState == SyncStatus.pendingDelete) {
          final targetId = (remoteId != null && remoteId.isNotEmpty)
              ? remoteId
              : localId;
          await _taskApi.deleteTask(targetId);
          await db.delete(
            'tasks',
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
        }
      } catch (_) {
        // 同期失敗時は状態を維持し、次回同期で再試行する。
      }
    }
  }

  Future<void> _pushCourseChanges(dynamic db) async {
    final pendingRows = await db.query(
      'courses',
      where: 'sync_status LIKE ?',
      whereArgs: <Object>['pending_%'],
      orderBy: 'updated_at ASC',
    );

    for (final row in pendingRows) {
      final localId = row['id']?.toString();
      if (localId == null || localId.isEmpty) continue;

      final syncState = row['sync_status']?.toString() ?? '';

      try {
        if (syncState == SyncStatus.pendingInsert) {
          final model = _subjectFromRow(row);
          final created = await _subjectApi.createSubject(model);
          await db.update(
            'courses',
            <String, Object?>{
              'remote_id': created.id,
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        if (syncState == SyncStatus.pendingUpdate) {
          final remoteId = row['remote_id']?.toString();
          final targetId = (remoteId != null && remoteId.isNotEmpty)
              ? remoteId
              : localId;
          final model = _subjectFromRow(row, idOverride: targetId);
          await _subjectApi.updateSubject(model);
          await db.update(
            'courses',
            <String, Object>{
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        if (syncState == SyncStatus.pendingDelete) {
          final remoteId = row['remote_id']?.toString();
          final targetId = (remoteId != null && remoteId.isNotEmpty)
              ? remoteId
              : localId;
          await _subjectApi.deleteSubject(targetId);
          await db.delete(
            'courses',
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
        }
      } catch (_) {
        // 同期失敗時は状態を維持し、次回同期で再試行する。
      }
    }
  }

  Future<void> _fetchRemoteTasks(dynamic db) async {
    try {
      final remoteTasks = await _taskApi.fetchTasks();
      for (final remote in remoteTasks) {
        final remoteId = remote.id;
        final localRows = await db.query(
          'tasks',
          where: 'remote_id = ? OR id = ?',
          whereArgs: <Object>[remoteId, remoteId],
          limit: 1,
        );

        if (localRows.isNotEmpty) {
          final local = localRows.first;
          final localSync =
              local['sync_status']?.toString() ?? SyncStatus.synced;
          if (localSync.startsWith('pending_')) {
            continue;
          }

          final localId = local['id']?.toString() ?? remoteId;
          await db.update(
            'tasks',
            <String, Object?>{
              'remote_id': remoteId,
              'title': remote.title,
              'subject_id': remote.subjectId,
              'type': remote.type.name,
              'priority': remote.priority.name,
              'status': remote.status.name,
              'start_date': remote.startDate.toIso8601String(),
              'deadline': remote.deadline.toIso8601String(),
              'estimated_hours': remote.estimatedHours,
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        await db.insert('tasks', <String, Object?>{
          'id': remoteId,
          'remote_id': remoteId,
          'title': remote.title,
          'subject_id': remote.subjectId,
          'type': remote.type.name,
          'priority': remote.priority.name,
          'status': remote.status.name,
          'start_date': remote.startDate.toIso8601String(),
          'deadline': remote.deadline.toIso8601String(),
          'estimated_hours': remote.estimatedHours,
          'sync_status': SyncStatus.synced,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (_) {
      // 取得失敗は無視し、次回オンライン時に再試行する。
    }
  }

  Future<void> _fetchRemoteCourses(dynamic db) async {
    try {
      final remoteSubjects = await _subjectApi.fetchSubjects();
      for (final remote in remoteSubjects) {
        final remoteId = remote.id;
        final localRows = await db.query(
          'courses',
          where: 'remote_id = ? OR id = ?',
          whereArgs: <Object>[remoteId, remoteId],
          limit: 1,
        );

        if (localRows.isNotEmpty) {
          final local = localRows.first;
          final localSync =
              local['sync_status']?.toString() ?? SyncStatus.synced;
          if (localSync.startsWith('pending_')) {
            continue;
          }

          final localId = local['id']?.toString() ?? remoteId;
          await db.update(
            'courses',
            <String, Object?>{
              'remote_id': remoteId,
              'name': remote.name,
              'credits': remote.credits,
              'units': remote.units,
              'teacher': remote.teacher,
              'exam_ratio': remote.examRatio,
              'test_scores_json': jsonEncode(remote.testScores),
              'evaluations_json': jsonEncode(
                remote.evaluations
                    .map((evaluation) => evaluation.toJson())
                    .toList(growable: false),
              ),
              'periodic_tests_json': jsonEncode(remote.periodicTests.toJson()),
              'variable_components_json': jsonEncode(
                remote.variableComponents
                    .map((component) => component.toJson())
                    .toList(growable: false),
              ),
              'regular_score': remote.regularScore,
              'test_weight': remote.testWeight,
              'sync_status': SyncStatus.synced,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: <Object>[localId],
          );
          continue;
        }

        await db.insert('courses', <String, Object?>{
          'id': remoteId,
          'remote_id': remoteId,
          'name': remote.name,
          'credits': remote.credits,
          'units': remote.units,
          'teacher': remote.teacher,
          'exam_ratio': remote.examRatio,
          'test_scores_json': jsonEncode(remote.testScores),
          'evaluations_json': jsonEncode(
            remote.evaluations
                .map((evaluation) => evaluation.toJson())
                .toList(growable: false),
          ),
          'periodic_tests_json': jsonEncode(remote.periodicTests.toJson()),
          'variable_components_json': jsonEncode(
            remote.variableComponents
                .map((component) => component.toJson())
                .toList(growable: false),
          ),
          'regular_score': remote.regularScore,
          'test_weight': remote.testWeight,
          'sync_status': SyncStatus.synced,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (_) {
      // 取得失敗は無視し、次回オンライン時に再試行する。
    }
  }

  TaskModel _taskFromRow(Map<String, Object?> row, {String? idOverride}) {
    return TaskModel(
      id: idOverride ?? row['id']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      subjectId: row['subject_id']?.toString(),
      type: TaskType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => TaskType.homework,
      ),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == row['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == row['status'],
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

  SubjectModel _subjectFromRow(Map<String, Object?> row, {String? idOverride}) {
    return SubjectModel.fromJson(<String, dynamic>{
      'id': idOverride ?? row['id']?.toString() ?? '',
      'name': row['name']?.toString() ?? '',
      'credits': row['credits'],
      'units': row['units'],
      'teacher': row['teacher']?.toString(),
      'exam_ratio': row['exam_ratio'],
      'test_scores': row['test_scores_json']?.toString(),
      'regular_score': row['regular_score'],
      'test_weight': row['test_weight'],
      'evaluations_json': row['evaluations_json']?.toString(),
      'periodic_tests_json': row['periodic_tests_json']?.toString(),
      'variable_components_json': row['variable_components_json']?.toString(),
    });
  }
}
