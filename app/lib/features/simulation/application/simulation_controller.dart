import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../grades/application/grade_controller.dart';
import '../../grades/domain/grade_calculator.dart';
import '../../grades/domain/subject_model.dart';

enum PromotionStatus {
  passing,
  conditional,
  danger,
  failing;

  String get label {
    switch (this) {
      case PromotionStatus.passing:
        return '進級安全圏';
      case PromotionStatus.conditional:
        return '条件付き';
      case PromotionStatus.danger:
        return '要注意';
      case PromotionStatus.failing:
        return '進級危険';
    }
  }

  String get emoji {
    switch (this) {
      case PromotionStatus.passing:
        return '✅';
      case PromotionStatus.conditional:
        return '🟡';
      case PromotionStatus.danger:
        return '⚠️';
      case PromotionStatus.failing:
        return '🚨';
    }
  }
}

class SimulationState {
  const SimulationState({
    required this.weightedAverage,
    required this.overallRank,
    required this.failCount,
    required this.atRiskSubjectIds,
    required this.status,
  });

  final double? weightedAverage;
  final GradeRank? overallRank;
  final int failCount;
  final List<String> atRiskSubjectIds;
  final PromotionStatus status;
}

class SimulationController extends AsyncNotifier<SimulationState> {
  @override
  Future<SimulationState> build() async {
    final subjects = await ref.watch(gradeNotifierProvider.future);
    return _buildState(subjects);
  }

  String predictionText(SubjectModel subject) {
    final score = GradeCalculator.calcFinalScore(subject);
    if (score == null) {
      return 'データ不足のため予測できません。評価項目の点数を入力してください。';
    }
    if (score >= 80) {
      return 'このまま維持すれば高評価が見込めます。';
    }
    if (score >= 70) {
      return '安定圏ですが、次の評価で上位を狙えます。';
    }
    if (score >= 60) {
      return '合格圏です。平常点を伸ばすと安全です。';
    }
    return '現状は不可リスクが高いです。早めに対策が必要です。';
  }

  String generateAdvice(SubjectModel subject) {
    final score = GradeCalculator.calcFinalScore(subject);
    final hasInput = subject.evaluations.any(
      (evaluation) => evaluation.userScore != null,
    );
    final testAvg = GradeCalculator.calcTestAverage(subject);

    if (score == null) {
      return 'まずは1つでも評価データを入力して、到達ラインを可視化しましょう。';
    }

    if (score < 60) {
      if (!hasInput) {
        return '評価項目の入力が未完了です。提出物や試験結果を先に記録しましょう。';
      }
      return '次回テストで +10 点以上を目標に、苦手単元を優先復習しましょう。';
    }

    if (score < 70) {
      if (testAvg == null) {
        return 'テスト得点が未入力です。直近の得点を記録して弱点を特定しましょう。';
      }
      return '演習量を少し増やすと、より安全圏に入れます。';
    }

    if (score < 80) {
      return '現状は良好です。平常点を落とさない運用を継続しましょう。';
    }

    return '非常に良好です。現在の学習ペースを維持しましょう。';
  }

  SimulationState _buildState(List<SubjectModel> subjects) {
    final weightedAverage = GradeCalculator.calcWeightedAverage(subjects);
    final rank = weightedAverage != null
        ? GradeCalculator.calcAbsoluteRank(weightedAverage)
        : null;

    final atRisk = <String>[];
    for (final subject in subjects) {
      final score = GradeCalculator.calcFinalScore(subject);
      if (score != null && score < 65) {
        atRisk.add(subject.id);
      }
    }

    final fails = GradeCalculator.failCount(subjects);

    PromotionStatus status;
    if (fails >= 3) {
      status = PromotionStatus.failing;
    } else if (fails >= 1 || atRisk.length >= 3) {
      status = PromotionStatus.danger;
    } else if (atRisk.isNotEmpty) {
      status = PromotionStatus.conditional;
    } else {
      status = PromotionStatus.passing;
    }

    return SimulationState(
      weightedAverage: weightedAverage,
      overallRank: rank,
      failCount: fails,
      atRiskSubjectIds: atRisk,
      status: status,
    );
  }
}

final simulationProvider =
    AsyncNotifierProvider<SimulationController, SimulationState>(
      SimulationController.new,
    );
