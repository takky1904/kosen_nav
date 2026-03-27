import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../data/local/local_database.dart';
import '../../../data/local/sync_status.dart';
import '../domain/subject_model.dart';

class CourseRepository {
  final StreamController<List<SubjectModel>> _coursesController =
      StreamController<List<SubjectModel>>.broadcast();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    await _emitCourses();
  }

  Stream<List<SubjectModel>> getCoursesStream() async* {
    await _ensureInitialized();
    yield await fetchCourses();
    yield* _coursesController.stream;
  }

  Future<List<SubjectModel>> fetchCourses() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      'courses',
      where: 'sync_status != ?',
      whereArgs: <Object>[SyncStatus.pendingDelete],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_mapCourseRowToModel).toList();
  }

  Future<SubjectModel> createCourse(SubjectModel subject) async {
    final db = await LocalDatabase.instance;
    await db.insert(
      'courses',
      _mapSubjectModelToRow(
        subject,
        remoteId: null,
        syncStatus: SyncStatus.pendingInsert,
        updatedAt: DateTime.now(),
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _emitCourses();
    return subject;
  }

  Future<SubjectModel> updateCourse(SubjectModel subject) async {
    final db = await LocalDatabase.instance;
    final existing = await db.query(
      'courses',
      columns: <String>['sync_status', 'remote_id'],
      where: 'id = ?',
      whereArgs: <Object>[subject.id],
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
      'courses',
      _mapSubjectModelToRow(
        subject,
        remoteId: currentRemoteId,
        syncStatus: nextSyncStatus,
        updatedAt: DateTime.now(),
      ),
      where: 'id = ?',
      whereArgs: <Object>[subject.id],
    );
    await _emitCourses();
    return subject;
  }

  Future<void> deleteCourse(String id) async {
    final db = await LocalDatabase.instance;
    final existing = await db.query(
      'courses',
      columns: <String>['sync_status'],
      where: 'id = ?',
      whereArgs: <Object>[id],
      limit: 1,
    );
    if (existing.isEmpty) return;

    final currentSyncStatus = existing.first['sync_status']?.toString();

    if (currentSyncStatus == SyncStatus.pendingInsert) {
      await db.delete('courses', where: 'id = ?', whereArgs: <Object>[id]);
    } else {
      await db.update(
        'courses',
        <String, Object>{
          'sync_status': SyncStatus.pendingDelete,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object>[id],
      );
    }

    await _emitCourses();
  }

  Future<void> replaceCoursesFromSyllabus(
    List<Map<String, dynamic>> subjects,
  ) async {
    final db = await LocalDatabase.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'courses',
        columns: <String>['id', 'sync_status'],
      );

      for (final row in existingRows) {
        final id = row['id']?.toString();
        if (id == null || id.isEmpty) {
          continue;
        }

        final syncStatus = row['sync_status']?.toString() ?? SyncStatus.synced;
        if (syncStatus == SyncStatus.pendingInsert) {
          await txn.delete('courses', where: 'id = ?', whereArgs: <Object>[id]);
          continue;
        }

        await txn.update(
          'courses',
          <String, Object>{
            'sync_status': SyncStatus.pendingDelete,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: <Object>[id],
        );
      }

      for (var i = 0; i < subjects.length; i++) {
        final item = subjects[i];
        final subjectId = item['subjectId']?.toString().trim();
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) {
          continue;
        }

        final credits = _toInt(item['credits']) ?? 2;
        final examRatio = _toInt(item['examRatio']);
        final safeExamRatio = examRatio?.clamp(0, 100);
        final testWeight = (safeExamRatio?.toDouble() ?? 70.0) / 100.0;

        await txn.insert('courses', <String, Object?>{
          'id': (subjectId != null && subjectId.isNotEmpty)
              ? subjectId
              : 'syllabus_${now}_$i',
          'remote_id': null,
          'name': name,
          'credits': credits,
          'units': credits,
          'teacher': item['teacher']?.toString(),
          'exam_ratio': safeExamRatio?.toInt(),
          'test_scores_json': jsonEncode(const <double?>[
            null,
            null,
            null,
            null,
          ]),
          'regular_score': null,
          'test_weight': testWeight,
          'sync_status': SyncStatus.pendingInsert,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });

    await _emitCourses();
  }

  Future<void> _emitCourses() async {
    final courses = await fetchCourses();
    if (!_coursesController.isClosed) {
      _coursesController.add(courses);
    }
  }

  Map<String, Object?> _mapSubjectModelToRow(
    SubjectModel subject, {
    required String? remoteId,
    required String syncStatus,
    required DateTime updatedAt,
  }) {
    return <String, Object?>{
      'id': subject.id,
      'remote_id': remoteId,
      'name': subject.name,
      'credits': subject.credits,
      'units': subject.units,
      'teacher': subject.teacher,
      'exam_ratio': subject.examRatio,
      'test_scores_json': jsonEncode(subject.testScores),
      'regular_score': subject.regularScore,
      'test_weight': subject.testWeight,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  SubjectModel _mapCourseRowToModel(Map<String, Object?> row) {
    final rawScores = row['test_scores_json']?.toString();
    List<double?> scores;
    try {
      final decoded = (jsonDecode(rawScores ?? '[]') as List<dynamic>);
      scores = decoded
          .map((value) => value == null ? null : (value as num).toDouble())
          .toList();
    } catch (_) {
      scores = <double?>[null, null, null, null];
    }

    return SubjectModel(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      units: (row['credits'] is num)
          ? (row['credits'] as num).toInt()
          : ((row['units'] is num)
                ? (row['units'] as num).toInt()
                : int.tryParse(row['credits']?.toString() ?? '') ??
                      int.tryParse(row['units']?.toString() ?? '2') ??
                      2),
      testScores: scores,
      regularScore: row['regular_score'] == null
          ? null
          : (row['regular_score'] as num).toDouble(),
      testWeight: (row['test_weight'] is num)
          ? (row['test_weight'] as num).toDouble()
          : double.tryParse(row['test_weight']?.toString() ?? '0.7') ?? 0.7,
      teacher: row['teacher']?.toString(),
      examRatio: row['exam_ratio'] is num
          ? (row['exam_ratio'] as num).toInt()
          : int.tryParse(row['exam_ratio']?.toString() ?? ''),
    );
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
