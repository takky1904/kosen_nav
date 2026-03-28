import 'subject_model.dart';

/// 純粋関数のみ。コントローラーやUIから切り離しテスト可能。
class GradeCalculator {
  GradeCalculator._();

  static double? calcEvaluationAverage(SubjectModel subject) {
    final valid = <double?>[
      ...subject.periodicTests.scores,
      ...subject.variableComponents.map((component) => component.userScore),
    ].whereType<double>().toList(growable: false);
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  /// 互換用: 「テスト」または「試験」に該当する項目の平均値。
  static double? calcTestAverage(SubjectModel subject) {
    final candidates = subject.periodicTests.scores.whereType<double>().toList(
      growable: false,
    );
    if (candidates.isEmpty) return null;
    return candidates.reduce((a, b) => a + b) / candidates.length;
  }

  /// 最終成績スコア（Σ userScore * ratio/100）
  static double? calcFinalScore(SubjectModel s) {
    final hasAnyInput =
        s.periodicTests.scores.any((score) => score != null) ||
        s.variableComponents.any((component) => component.userScore != null);
    if (!hasAnyInput) {
      return null;
    }

    final testAvg = calcTestAverage(s);
    final weightedTest =
        (testAvg ?? 0) * (s.periodicTests.ratio.clamp(0, 100) / 100.0);

    double weightedVariable = 0;
    for (final component in s.variableComponents) {
      final score = (component.userScore ?? 0).clamp(0.0, 100.0);
      final ratio = component.ratio.clamp(0, 100) / 100.0;
      weightedVariable += score * ratio;
    }

    return (weightedTest + weightedVariable).clamp(0.0, 100.0);
  }

  /// 履修全科目の加重平均スコア（点数 × 単位数 / 総単位数）
  static double? calcWeightedAverage(List<SubjectModel> subjects) {
    double totalWeighted = 0;
    int totalUnits = 0;

    for (final s in subjects) {
      final score = calcFinalScore(s);
      if (score != null) {
        totalWeighted += score * s.units;
        totalUnits += s.units;
      }
    }
    if (totalUnits == 0) return null;
    return totalWeighted / totalUnits;
  }

  /// 絶対評価によるランク（点数レンジで判定）
  /// 優: 80以上 / 良: 70以上 / 可: 60以上 / 不可: 60未満
  static GradeRank calcAbsoluteRank(double score) {
    if (score >= 80) return GradeRank.a;
    if (score >= 70) return GradeRank.b;
    if (score >= 60) return GradeRank.c;
    return GradeRank.d;
  }

  /// 相対評価ランク（クラス全員のスコアを受け取る）
  /// 上位20%→A, 次30%→B, 次30%→C, 残り→D
  static GradeRank calcRelativeRank(double score, List<double> allScores) {
    if (allScores.isEmpty) return calcAbsoluteRank(score);
    final sorted = List<double>.from(allScores)..sort((a, b) => b.compareTo(a));
    final rank = sorted.indexWhere((s) => s <= score) / sorted.length;
    if (rank < 0.20) return GradeRank.a;
    if (rank < 0.50) return GradeRank.b;
    if (rank < 0.80) return GradeRank.c;
    return GradeRank.d;
  }

  /// 不可判定 (59点以下)
  static bool isFailing(double? score) => score != null && score < 60;

  /// 不可科目数
  static int failCount(List<SubjectModel> subjects) {
    return subjects.where((s) => isFailing(calcFinalScore(s))).length;
  }
}
