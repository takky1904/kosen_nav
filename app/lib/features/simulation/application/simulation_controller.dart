import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../grades/domain/subject_model.dart';
import '../../grades/domain/grade_calculator.dart';
import '../../grades/application/grade_controller.dart';

// ── Promotion Status ───────────────────────────────────────────────────────

enum PromotionStatus {
  passing,    // 進級 (不可0個)
  conditional, // 仮進級 (不可1〜2個)
  danger,     // 留年危機 (不可3個)
  failing,    // 留年 (不可4個以上)
}

extension PromotionStatusExt on PromotionStatus {
  String get label {
    switch (this) {
      case PromotionStatus.passing:    return '進級';
      case PromotionStatus.conditional:return '仮進級';
      case PromotionStatus.danger:     return '留年危機';
      case PromotionStatus.failing:    return '留年';
    }
  }

  String get emoji {
    switch (this) {
      case PromotionStatus.passing:    return '✅';
      case PromotionStatus.conditional:return '⚠️';
      case PromotionStatus.danger:     return '🚨';
      case PromotionStatus.failing:    return '💀';
    }
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class SimulationState {
  final PromotionStatus status;
  final int failCount;
  final double? weightedAverage;
  final GradeRank? overallRank;
  final List<String> atRiskSubjectIds; // 危機科目ID一覧

  const SimulationState({
    required this.status,
    required this.failCount,
    this.weightedAverage,
    this.overallRank,
    this.atRiskSubjectIds = const [],
  });
}

// ── Notifier ───────────────────────────────────────────────────────────────

class PromotionSimulatorNotifier extends AsyncNotifier<SimulationState> {
  @override
  Future<SimulationState> build() async {
    final subjectsAsync = ref.watch(gradeNotifierProvider);
    return subjectsAsync.when(
      data: (subjects) => _compute(subjects),
      loading: () => _initialState(),
      error: (err, st) => _initialState(),
    );
  }

  static SimulationState _initialState() => const SimulationState(
        status: PromotionStatus.passing,
        failCount: 0,
      );

  SimulationState _compute(List<SubjectModel> subjects) {
    final count = GradeCalculator.failCount(subjects);
    final status = _statusFromCount(count);
    final avg = GradeCalculator.calcWeightedAverage(subjects);

    // 不可または危険域(60〜65点)の科目を収集
    final atRisk = subjects
        .where((s) {
          final score = GradeCalculator.calcFinalScore(s);
          return score == null || score < 65;
        })
        .map((s) => s.id)
        .toList();

    return SimulationState(
      status: status,
      failCount: count,
      weightedAverage: avg,
      overallRank: avg != null ? GradeCalculator.calcAbsoluteRank(avg) : null,
      atRiskSubjectIds: atRisk,
    );
  }

  static PromotionStatus _statusFromCount(int count) {
    if (count == 0) return PromotionStatus.passing;
    if (count <= 2) return PromotionStatus.conditional;
    if (count == 3) return PromotionStatus.danger;
    return PromotionStatus.failing;
  }

  // ── AI Mentoring ──────────────────────────────────────────────────────────

  /// 科目に対するAIスモールステップアドバイスを生成
  String generateAdvice(SubjectModel subject) {
    final score = GradeCalculator.calcFinalScore(subject);
    final testAvg = GradeCalculator.calcTestAverage(subject.testScores);
    final unanswered = subject.testScores.where((s) => s == null).length;

    if (score == null) {
      return '📋 まず成績を入力してください。現状を把握することが第一歩です。';
    }

    if (score >= 85) {
      return '🎯 現状維持で優評定です！引き続き高水準を保ちましょう。';
    }

    if (score >= 70) {
      return '📈 良い調子です。次のテストで+5点を目標に過去問を3年分解きましょう。';
    }

    if (score >= 60) {
      final tips = <String>[
        '⚡ 危険域です。以下のステップで挽回を目指しましょう：',
        '  1. ${subject.name}の教科書 第1〜3章を再読（2日）',
        '  2. 過去問を入手し出題傾向を分析（1日）',
        '  3. 演習問題を最低20問解く（3日）',
        '  4. 先生のオフィスアワーを活用して質問する',
      ];
      if (subject.regularScore != null && subject.regularScore! < 70) {
        tips.add('  5. ⚠️ 平常点も低め。提出物・出席を改善する');
      }
      return tips.join('\n');
    }

    // 不可域
    final steps = <String>[
      '🚨 【至急】不可リスク高。今すぐ行動してください：',
      '  1. 担任の${subject.teacher ?? "先生"}へ面談申請（今日中）',
      '  2. ${subject.name}の最重要単元を特定（シラバス確認）',
      '  3. 友人・先輩からノートを借りて穴埋め',
      '  4. 残りテスト($unanswered回)で最低70点を目標に設定',
      '  5. 毎日30分以上この科目に充てるスケジュールを組む',
    ];

    if (testAvg != null && testAvg < 50) {
      steps.add('  ❗ テスト平均が${testAvg.toStringAsFixed(1)}点。基礎からやり直しが必要です。');
    }

    return steps.join('\n');
  }

  /// 予測テキスト (科目ページ表示用)
  String predictionText(SubjectModel subject) {
    final score = GradeCalculator.calcFinalScore(subject);
    if (score == null) return '❓ データ不足のため予測不可';

    if (score >= 90) return '🌟 このままなら「優」確定圏内です！';
    if (score >= 80) return '✅ このままなら「良」が見込めます';
    if (score >= 70) return '📊 このままなら「可」〜「良」の境界線です';
    if (score >= 60) return '⚠️ このままだと「可」ギリギリです。要注意！';
    if (score >= 50) return '🔴 このままだと「不可」の可能性があります！';
    return '💀 このままだと確実に「不可」です。今すぐ対策を！';
  }
}

final simulationProvider =
    AsyncNotifierProvider<PromotionSimulatorNotifier, SimulationState>(
  PromotionSimulatorNotifier.new,
);
