import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/subject_model.dart';
import '../data/subject_api_client.dart';

/// 科目リスト全体を管理するNotifier
class GradeNotifier extends AsyncNotifier<List<SubjectModel>> {
  final _apiClient = SubjectApiClient();

  @override
  Future<List<SubjectModel>> build() async {
    try {
      return await _apiClient.fetchSubjects();
    } catch (_) {
      // 初期表示を止めないため、取得失敗時は空配列で描画する。
      return <SubjectModel>[];
    }
  }

  // ── CRUD ──────────────────────────────────────────

  Future<void> addSubject(SubjectModel subject) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _apiClient.createSubject(subject);
      return _apiClient.fetchSubjects();
    });
  }

  Future<void> updateSubject(SubjectModel subject) async {
    state = await AsyncValue.guard(() async {
      await _apiClient.updateSubject(subject);
      return _apiClient.fetchSubjects();
    });
  }

  Future<void> removeSubject(String id) async {
    state = await AsyncValue.guard(() async {
      await _apiClient.deleteSubject(id);
      return _apiClient.fetchSubjects();
    });
  }

  // ── Score Updates ──────────────────────────────────

  Future<void> updateTestScore(
    String subjectId,
    int index,
    double? score,
  ) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.withTestScore(index, score);
    await updateSubject(updatedSubject);
  }

  Future<void> updateRegularScore(String subjectId, double? score) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.copyWith(regularScore: score);
    await updateSubject(updatedSubject);
  }

  Future<void> updateWeights(String subjectId, double testWeight) async {
    final subjects = state.value ?? [];
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    final updatedSubject = subject.copyWith(
      testWeight: (testWeight * 10).roundToDouble() / 10.0,
    );
    await updateSubject(updatedSubject);
  }
}

final gradeNotifierProvider =
    AsyncNotifierProvider<GradeNotifier, List<SubjectModel>>(GradeNotifier.new);
