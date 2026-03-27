import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../data/local/local_database.dart';
import '../../../data/local/sync_status.dart';
import '../domain/evaluation.dart';
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
    return rows.map(_mapCourseRowToModel).toList(growable: false);
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
        if (id == null || id.isEmpty) continue;

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
        final name = item['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;

        final id = item['subjectId']?.toString().trim();
        final credits = _toInt(item['credits']) ?? 2;

        final periodic = _parsePeriodicTestsFromSyllabus(item);
        final variableComponents = _parseVariableComponentsFromSyllabus(
          item,
          periodicRatio: periodic.ratio,
        );

        final course = SubjectModel(
          id: (id != null && id.isNotEmpty) ? id : 'syllabus_${now}_$i',
          name: name,
          units: credits,
          periodicTests: periodic,
          variableComponents: variableComponents,
          teacher: item['teacher']?.toString(),
        );

        await txn.insert(
          'courses',
          _mapSubjectModelToRow(
            course,
            remoteId: null,
            syncStatus: SyncStatus.pendingInsert,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
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
    final periodicJson = jsonEncode(subject.periodicTests.toJson());
    final variableJson = jsonEncode(
      subject.variableComponents
          .map((component) => component.toJson())
          .toList(growable: false),
    );
    final legacyEvaluations = jsonEncode(subject.toJson()['evaluations']);

    return <String, Object?>{
      'id': subject.id,
      'remote_id': remoteId,
      'name': subject.name,
      'credits': subject.credits,
      'units': subject.units,
      'teacher': subject.teacher,
      'exam_ratio': subject.examRatio,
      'test_scores_json': jsonEncode(subject.periodicTests.scores),
      'regular_score': subject.regularScore,
      'test_weight': subject.testWeight,
      'evaluations_json': legacyEvaluations,
      'periodic_tests_json': periodicJson,
      'variable_components_json': variableJson,
      'sync_status': syncStatus,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  SubjectModel _mapCourseRowToModel(Map<String, Object?> row) {
    return SubjectModel.fromJson(<String, dynamic>{
      'id': row['id']?.toString() ?? '',
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

  PeriodicTests _parsePeriodicTestsFromSyllabus(Map<String, dynamic> item) {
    final evaluations = _extractEvaluations(item['evaluations']);
    for (final evaluation in evaluations) {
      final id = (evaluation['id'] ?? '').toString().trim().toLowerCase();
      if (id == 'exam') {
        final ratio = _toInt(evaluation['ratio']) ?? 0;
        return PeriodicTests(
          ratio: ratio.clamp(0, 100),
          count: 4,
          scores: const <double?>[],
        ).normalized();
      }
    }

    if (item['periodicTests'] is Map<String, dynamic>) {
      return PeriodicTests.fromJson(
        item['periodicTests'] as Map<String, dynamic>,
      ).normalized();
    }

    return const PeriodicTests(
      ratio: 0,
      count: 4,
      scores: <double?>[],
    ).normalized();
  }

  List<Evaluation> _parseVariableComponentsFromSyllabus(
    Map<String, dynamic> item, {
    required int periodicRatio,
  }) {
    final evaluations = _extractEvaluations(item['evaluations']);
    if (evaluations.isNotEmpty) {
      final variable = <Evaluation>[];
      for (final raw in evaluations) {
        final parsed = Evaluation.fromJson(raw);
        final id = parsed.id.trim().toLowerCase();
        if (id != 'exam' && parsed.id.isNotEmpty && parsed.name.isNotEmpty) {
          variable.add(parsed.copyWith(userScore: null));
        }
      }

      if (variable.isNotEmpty) {
        return variable;
      }
    }

    final remaining = (100 - periodicRatio).clamp(0, 100);
    if (remaining == 0) {
      return const <Evaluation>[];
    }

    return <Evaluation>[
      Evaluation(id: 'normal', name: '平常点', ratio: remaining),
    ];
  }

  List<Map<String, dynamic>> _extractEvaluations(dynamic rawEvaluations) {
    if (rawEvaluations is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawEvaluations
        .whereType<Map>()
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList(growable: false);
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
