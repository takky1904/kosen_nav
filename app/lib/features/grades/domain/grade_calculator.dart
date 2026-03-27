import 'subject_model.dart';

/// 純粋関数のみ。コントローラーやUIから切り離しテスト可能。
class GradeCalculator {
  GradeCalculator._();

  /// テスト平均点（受験済みの回のみ対象）
  static double? calcTestAverage(List<double?> scores) {
    final valid = scores.whereType<double>().toList();
    if (valid.isEmpty) return null;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  /// 最終成績スコア（テスト平均×比率 + 平常点×比率）
  /// 片方しかない場合は入力済みの値だけで正規化して返す
  static double? calcFinalScore(SubjectModel s) {
    final testAvg = calcTestAverage(s.testScores);
    final regular = s.regularScore;

    if (testAvg == null && regular == null) return null;

    if (testAvg != null && regular != null) {
      double testRatio;
      double regularRatio;

      if (s.examRatio != null) {
        final examPercent = s.examRatio!.clamp(0, 100).toDouble();
        testRatio = examPercent / 100.0;
        regularRatio = 1.0 - testRatio;
      } else {
        final total = s.testWeight + s.regularWeight;
        if (total <= 0) {
          testRatio = 0.7;
          regularRatio = 0.3;
        } else {
          testRatio = s.testWeight / total;
          regularRatio = s.regularWeight / total;
        }
      }

      return (testAvg * testRatio + regular * regularRatio).clamp(0.0, 100.0);
    }

    // 片方のみ入力済み → 入力済みのものを weight 1.0 として返す（暫定）
    if (testAvg != null) return testAvg;
    return regular;
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

  /// 絶対評価によるランク（相対評価の雛形;現在は点数のみで判定）
  /// 将来的にクラス全員のスコアリストを受け取る相対評価に差し替え可能
  static GradeRank calcAbsoluteRank(double score) {
    if (score >= 90) return GradeRank.a;
    if (score >= 75) return GradeRank.b;
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
