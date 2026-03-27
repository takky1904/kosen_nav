import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/subject_model.dart';
import '../data/course_repository.dart';

/// 科目リスト全体を管理するNotifier
class GradeNotifier extends AsyncNotifier<List<SubjectModel>> {
  final _repository = CourseRepository();

  @override
  Future<List<SubjectModel>> build() async {
    final stream = _repository.getCoursesStream();
    StreamSubscription<List<SubjectModel>>? subscription;

    subscription = stream.listen((subjects) {
      state = AsyncValue.data(subjects);
    });

    ref.onDispose(() async {
      await subscription?.cancel();
    });

    try {
      return await stream.first;
    } catch (_) {
      // 初期表示を止めないため、取得失敗時は空配列で描画する。
      return <SubjectModel>[];
    }
  }

  // ── CRUD ──────────────────────────────────────────

  Future<void> addSubject(SubjectModel subject) async {
    try {
      await _repository.createCourse(subject);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSubject(SubjectModel subject) async {
    try {
      await _repository.updateCourse(subject);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeSubject(String id) async {
    try {
      await _repository.deleteCourse(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ── Score Updates ──────────────────────────────────

  Future<void> updatePeriodicTestScore(
    String subjectId,
    int index,
    double? score,
  ) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.withPeriodicTestScore(index, score);
    await updateSubject(updatedSubject);
  }

  Future<void> updateVariableComponentScore(
    String subjectId,
    String componentId,
    double? score,
  ) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.withVariableComponentScore(
      componentId,
      score,
    );
    await updateSubject(updatedSubject);
  }

  Future<void> addVariableComponent(
    String subjectId, {
    required String name,
    required int ratio,
  }) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.addVariableComponent(
      name: name,
      ratio: ratio,
    );
    await updateSubject(updatedSubject);
  }

  Future<void> removeVariableComponent(
    String subjectId,
    String componentId,
  ) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.removeVariableComponent(componentId);
    await updateSubject(updatedSubject);
  }
}

final gradeNotifierProvider =
    AsyncNotifierProvider<GradeNotifier, List<SubjectModel>>(GradeNotifier.new);
