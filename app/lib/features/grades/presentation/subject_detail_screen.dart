import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/subject_model.dart';
import '../domain/grade_calculator.dart';
import '../application/grade_controller.dart';
import '../../simulation/application/simulation_controller.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;
  const SubjectDetailScreen({required this.subjectId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(gradeNotifierProvider);
    final simAsync = ref.watch(simulationProvider);

    return subjectsAsync.when(
      data: (subjects) {
        final subject = subjects.firstWhere(
          (s) => s.id == subjectId,
          orElse: () => subjects.isNotEmpty
              ? subjects.first
              : SubjectModel.create(name: 'Unknown', units: 0),
        );

        return simAsync.when(
          data: (sim) {
            final simulator = ref.read(simulationProvider.notifier);
            final score = GradeCalculator.calcFinalScore(subject);
            final testAvg = GradeCalculator.calcTestAverage(subject.testScores);
            final prediction = simulator.predictionText(subject);
            final advice = simulator.generateAdvice(subject);
            final isAtRisk = sim.atRiskSubjectIds.contains(subject.id);
            final tt = Theme.of(context).textTheme;

            final Color predColor = _predictionColor(score);

            return Scaffold(
              backgroundColor: AppTheme.bgDeep,
              appBar: AppBar(
                title: Text(subject.name, style: tt.headlineLarge),
                leading: const BackButton(),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── AI 予測バナー ────────────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: predColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: predColor.withAlpha(180),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: predColor.withAlpha(50),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: predColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              prediction,
                              style: TextStyle(
                                color: predColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Score Summary ────────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: '予測最終成績',
                            value: score != null
                                ? '${score.toStringAsFixed(1)}点'
                                : '--',
                            color: _scoreColor(score),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: 'テスト平均',
                            value: testAvg != null
                                ? '${testAvg.toStringAsFixed(1)}点'
                                : '--',
                            color: _scoreColor(testAvg),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            label: '平常点',
                            value: subject.regularScore != null
                                ? '${subject.regularScore!.toStringAsFixed(0)}点'
                                : '--',
                            color: _scoreColor(subject.regularScore),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Test Score Input ─────────────────────────────────────────────
                    Text('テスト点数 (4回)', style: tt.headlineMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(4, (i) {
                        final val = subject.testScores.length > i
                            ? subject.testScores[i]
                            : null;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: i < 3 ? 8.0 : 0),
                            child: _TestScoreField(
                              index: i,
                              initialValue: val,
                              onChanged: (v) => ref
                                  .read(gradeNotifierProvider.notifier)
                                  .updateTestScore(subjectId, i, v),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),

                    // ── Regular Score Input ──────────────────────────────────────────
                    Text('平常点', style: tt.headlineMedium),
                    const SizedBox(height: 8),
                    _ScoreSliderField(
                      label: '平常点',
                      value: subject.regularScore ?? 0,
                      onChanged: (v) => ref
                          .read(gradeNotifierProvider.notifier)
                          .updateRegularScore(subjectId, v),
                    ),
                    const SizedBox(height: 20),

                    // ── Weight Settings ──────────────────────────────────────────────
                    Text('テスト比率', style: tt.headlineMedium),
                    const SizedBox(height: 8),
                    if (subject.examRatio != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'シラバス比率を使用中: テスト ${subject.examRatio}% / 平常点 ${100 - subject.examRatio!.clamp(0, 100)}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WeightSlider(
                                  initialWeight: subject.testWeight,
                                  onChanged: (v) => ref
                                      .read(gradeNotifierProvider.notifier)
                                      .updateWeights(subjectId, v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // ── AI Advice ────────────────────────────────────────────────────
                    if (isAtRisk || (score != null && score < 75)) ...[
                      Text('🤖 AIアドバイス', style: tt.headlineMedium),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          advice,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            height: 1.7,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ],
                ),
              ),
            );
          },
          loading: () => const Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(child: Text('Error: $err')),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _predictionColor(double? score) {
    if (score == null) return AppTheme.textSecondary;
    if (score >= 80) return AppTheme.neonGreen;
    if (score >= 70) return AppTheme.neonGreen.withAlpha(200);
    if (score >= 60) return AppTheme.neonYellow;
    if (score >= 50) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  Color _scoreColor(double? score) {
    if (score == null) return AppTheme.textSecondary;
    if (score >= 80) return AppTheme.neonGreen;
    if (score >= 70) return AppTheme.neonYellow;
    if (score >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }
}

// ── Metric Card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Test Score Field ──────────────────────────────────────────────────────────

class _TestScoreField extends StatefulWidget {
  final int index;
  final double? initialValue;
  final ValueChanged<double?> onChanged;

  const _TestScoreField({
    required this.index,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_TestScoreField> createState() => _TestScoreFieldState();
}

class _TestScoreFieldState extends State<_TestScoreField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue != null
          ? widget.initialValue!.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        labelText: '第${widget.index + 1}回',
        suffixText: '点',
      ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        widget.onChanged(parsed?.clamp(0.0, 100.0));
      },
    );
  }
}

// ── Score Slider Field ────────────────────────────────────────────────────────

class _ScoreSliderField extends StatefulWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _ScoreSliderField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ScoreSliderField> createState() => _ScoreSliderFieldState();
}

class _ScoreSliderFieldState extends State<_ScoreSliderField> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  void didUpdateWidget(_ScoreSliderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _current = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            _current.toStringAsFixed(0),
            style: const TextStyle(
              color: AppTheme.neonGreen,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Slider(
            value: _current,
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: (v) => setState(() => _current = v),
            onChangeEnd: widget.onChanged,
          ),
        ),
        const Text('100', style: TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _WeightSlider extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onChanged;

  const _WeightSlider({required this.initialWeight, required this.onChanged});

  @override
  State<_WeightSlider> createState() => _WeightSliderState();
}

class _WeightSliderState extends State<_WeightSlider> {
  late double _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialWeight;
  }

  @override
  void didUpdateWidget(_WeightSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialWeight != widget.initialWeight) {
      if (!mounted) return;
      setState(() {
        _current = widget.initialWeight;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'テスト: ${(_current * 100).toStringAsFixed(0)}%  '
          '平常点: ${((1.0 - _current) * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _current.clamp(0.0, 1.0),
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (v) => setState(() => _current = v),
          onChangeEnd: widget.onChanged,
        ),
      ],
    );
  }
}
