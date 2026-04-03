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

  /// 最終成績スコア（ratio合計で正規化された100点満点スコア）
  ///
  /// Ultimate Normalization Engine:
  /// 計算ロジック:
  /// 1. 定期試験の平均を算出: testAvg = Σ(test scores) / count
  /// 2. 正規化前の実得点に変換: testActual = testAvg * (maxScore / 100)
  /// 3. 各コンポーネントも正規化前の実得点に変換
  /// 4. 最終成績 = Σ ( (実得点 / maxScore) * (ratio / totalRatioSum) * 100 )
  ///
  /// 例: ベーシックサイエンス・ラボ (totalRatioSum=100)
  ///   物理試験：25/30 * (15/100) * 100 = 12.5点
  ///   物理レポ：60/70 * (35/100) * 100 = 30.0点
  ///   化学レポ：90/100 * (50/100) * 100 = 45.0点
  ///   合計 = 87.5点
  static double? calcFinalScore(SubjectModel s) {
    final hasAnyInput =
        s.periodicTests.scores.any((score) => score != null) ||
        s.variableComponents.any((component) => component.userScore != null);
    if (!hasAnyInput) {
      return null;
    }

    final totalRatioSum = s.totalRatioSum;
    if (totalRatioSum == 0) {
      return null; // 無効: ratioの合計が0
    }

    double finalScore = 0.0;

    // ステップ1-2: 定期試験の処理
    final testAvg = calcTestAverage(s);
    if (testAvg != null) {
      // 0-100スケールから実得点に変換
      final testActual = testAvg * (s.periodicTests.maxScore / 100.0);
      // 正規化パターン: (実得点 / maxScore) * (ratio / totalRatioSum) * 100
      final testNormalized =
          (testActual / s.periodicTests.maxScore) *
          (s.periodicTests.ratio / totalRatioSum) *
          100.0;
      finalScore += testNormalized;
    }

    // ステップ3: 可変コンポーネントの処理
    for (final component in s.variableComponents) {
      final score = component.userScore;
      if (score != null) {
        // 0-100スケールから実得点に変換
        final componentActual = score * (component.maxScore / 100.0);
        // 正規化パターン
        final componentNormalized =
            (componentActual / component.maxScore) *
            (component.ratio / totalRatioSum) *
            100.0;
        finalScore += componentNormalized;
      }
    }

    return finalScore.clamp(0.0, 100.0);
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
