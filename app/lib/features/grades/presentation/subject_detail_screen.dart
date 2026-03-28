import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../simulation/application/simulation_controller.dart';
import '../application/grade_controller.dart';
import '../domain/evaluation.dart';
import '../domain/grade_calculator.dart';
import '../domain/subject_model.dart';

class SubjectDetailScreen extends ConsumerWidget {
  static const int _fixedPeriodicCount = 4;

  const SubjectDetailScreen({required this.subjectId, super.key});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(gradeNotifierProvider);
    final simAsync = ref.watch(simulationProvider);

    return subjectsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: (subjects) {
        final subject = subjects.firstWhere(
          (s) => s.id == subjectId,
          orElse: () => subjects.isNotEmpty
              ? subjects.first
              : SubjectModel.create(name: 'Unknown', units: 0),
        );

        return simAsync.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (sim) {
            final simulator = ref.read(simulationProvider.notifier);
            final score = GradeCalculator.calcFinalScore(subject);
            final testAvg = GradeCalculator.calcTestAverage(subject);
            final periodic = subject.periodicTests
                .copyWith(count: _fixedPeriodicCount)
                .normalized();
            final stageRank = score != null
                ? GradeCalculator.calcAbsoluteRank(score)
                : null;
            final stageEvaluation =
                stageRank?.description.split(' ').first ?? '--';

            final prediction = simulator.predictionText(subject);
            final advice = simulator.generateAdvice(subject);
            final isAtRisk = sim.atRiskSubjectIds.contains(subject.id);
            final tt = Theme.of(context).textTheme;

            return Scaffold(
              backgroundColor: AppTheme.bgDeep,
              appBar: AppBar(
                title: Text(subject.name, style: tt.headlineLarge),
                leading: const BackButton(),
              ),
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PredictionBanner(prediction: prediction, score: score),
                      const SizedBox(height: 20),
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
                              label: '定期試験平均',
                              value: testAvg != null
                                  ? '${testAvg.toStringAsFixed(1)}点'
                                  : '--',
                              color: _scoreColor(testAvg),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: '段階評価',
                              value: stageEvaluation,
                              color: _rankColor(stageRank),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        '定期試験 (${periodic.ratio}%)',
                        style: tt.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(_fixedPeriodicCount, (index) {
                          final scoreAt = periodic.scores[index];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == _fixedPeriodicCount - 1 ? 0 : 8,
                              ),
                              child: _PeriodicTestField(
                                label: '第${index + 1}回',
                                initialValue: scoreAt,
                                onChanged: (value) {
                                  ref
                                      .read(gradeNotifierProvider.notifier)
                                      .updatePeriodicTestScore(
                                        subject.id,
                                        index,
                                        value,
                                      );
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),

                      Text('平常点・その他', style: tt.headlineMedium),
                      const SizedBox(height: 10),

                      if (subject.variableComponents.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Text(
                            '評価項目がありません。シラバスマスタを確認してください。',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),

                      ...subject.variableComponents.map(
                        (component) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                            decoration: BoxDecoration(
                              color: AppTheme.bgCard,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: _VariableComponentInputCard(
                              component: component,
                              onChanged: (value) {
                                ref
                                    .read(gradeNotifierProvider.notifier)
                                    .updateVariableComponentScore(
                                      subject.id,
                                      component.id,
                                      value,
                                    );
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      if (isAtRisk || (score != null && score < 75)) ...[
                        Text('AIアドバイス', style: tt.headlineMedium),
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
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      _EvaluationRatioBar(
                        periodicRatio: periodic.ratio,
                        components: subject.variableComponents,
                      ),
                      const SizedBox(height: 12),
                      _SubjectMetaCard(
                        units: subject.units,
                        teacher: subject.teacher,
                      ),
                    ],
                  ),
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

  static Color _scoreColor(double? score) {
    if (score == null) return AppTheme.textSecondary;
    if (score >= 80) return AppTheme.neonGreen;
    if (score >= 70) return AppTheme.neonYellow;
    if (score >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  static Color _rankColor(GradeRank? rank) {
    switch (rank) {
      case GradeRank.a:
        return AppTheme.neonGreen;
      case GradeRank.b:
        return AppTheme.neonYellow;
      case GradeRank.c:
        return AppTheme.neonOrange;
      case GradeRank.d:
        return AppTheme.neonRed;
      case null:
        return AppTheme.textSecondary;
    }
  }
}

class _PredictionBanner extends StatelessWidget {
  const _PredictionBanner({required this.prediction, required this.score});

  final String prediction;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final color = SubjectDetailScreen._scoreColor(score);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(180), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              prediction,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

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

class _PeriodicTestField extends StatefulWidget {
  const _PeriodicTestField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  final String label;
  final double? initialValue;
  final ValueChanged<double?> onChanged;

  @override
  State<_PeriodicTestField> createState() => _PeriodicTestFieldState();
}

class _PeriodicTestFieldState extends State<_PeriodicTestField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _PeriodicTestField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enableInteractiveSelection: false,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(labelText: widget.label, suffixText: '点'),
      onChanged: (value) {
        final parsed = double.tryParse(value);
        widget.onChanged(parsed?.clamp(0.0, 100.0));
      },
    );
  }
}

class _VariableComponentInputCard extends StatefulWidget {
  const _VariableComponentInputCard({
    required this.component,
    required this.onChanged,
  });

  final Evaluation component;
  final ValueChanged<double?> onChanged;

  @override
  State<_VariableComponentInputCard> createState() =>
      _VariableComponentInputCardState();
}

class _VariableComponentInputCardState
    extends State<_VariableComponentInputCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _scoreFocusNode = FocusNode();

  void _moveCursorToEnd() {
    final end = _controller.text.length;
    _controller.selection = TextSelection.collapsed(offset: end);
  }

  void _onScoreFocusChanged() {
    if (_scoreFocusNode.hasFocus) {
      _moveCursorToEnd();
      return;
    }

    if (_controller.text.trim().isEmpty) {
      _controller.text = '0';
      _moveCursorToEnd();
      widget.onChanged(0);
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _scoreFocusNode.addListener(_onScoreFocusChanged);
    _controller.text = widget.component.userScore?.toStringAsFixed(0) ?? '';
  }

  @override
  void didUpdateWidget(covariant _VariableComponentInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.component.userScore != widget.component.userScore) {
      if (_scoreFocusNode.hasFocus) return;
      _controller.text = widget.component.userScore?.toStringAsFixed(0) ?? '';
      _moveCursorToEnd();
    }
  }

  @override
  void dispose() {
    _scoreFocusNode
      ..removeListener(_onScoreFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = (widget.component.userScore ?? 0).clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.component.name,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 86,
              child: TextField(
                controller: _controller,
                focusNode: _scoreFocusNode,
                enableInteractiveSelection: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  labelText: '点数',
                  suffixText: '点',
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                ),
                onTap: _moveCursorToEnd,
                onChanged: (value) {
                  if (_controller.selection.baseOffset !=
                      _controller.text.length) {
                    _moveCursorToEnd();
                  }

                  if (value.trim().isEmpty) {
                    setState(() {});
                    return;
                  }

                  final parsed = double.tryParse(value);
                  if (parsed == null) return;

                  final clamped = parsed.clamp(0.0, 100.0);
                  widget.onChanged(clamped);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ComponentSliderBar(
                value: sliderValue,
                onPreviewChanged: (value) {
                  if (_scoreFocusNode.hasFocus) return;
                  _controller.text = value.toStringAsFixed(0);
                  _moveCursorToEnd();
                },
                onChangeEnd: (value) {
                  widget.onChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EvaluationRatioBar extends StatelessWidget {
  const _EvaluationRatioBar({
    required this.periodicRatio,
    required this.components,
  });

  final int periodicRatio;
  final List<Evaluation> components;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final segments = _segments();
    final total = segments.fold<int>(0, (sum, s) => sum + s.ratio);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('評価割合', style: theme.headlineMedium),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 16,
              child: Row(
                children: segments
                    .where((segment) => segment.ratio > 0)
                    .map(
                      (segment) => Expanded(
                        flex: segment.ratio,
                        child: Container(color: segment.color),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: segments
                .where((segment) => segment.ratio > 0)
                .map(
                  (segment) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: segment.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${segment.label} (${segment.ratio}%)',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(growable: false),
          ),
          if (total != 100) ...[
            const SizedBox(height: 8),
            Text(
              '合計: $total% (100%でない場合は入力比率を見直してください)',
              style: const TextStyle(color: AppTheme.neonOrange, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  List<_RatioSegment> _segments() {
    const palette = <Color>[
      Color(0xFFE74C3C),
      Color(0xFF2E86DE),
      Color(0xFF16A085),
      Color(0xFFF39C12),
      Color(0xFF8E44AD),
      Color(0xFF2D3436),
      Color(0xFFE17055),
    ];

    final segments = <_RatioSegment>[];
    if (periodicRatio > 0) {
      segments.add(
        _RatioSegment(
          label: '定期試験',
          ratio: periodicRatio.clamp(0, 100),
          color: palette.first,
        ),
      );
    }

    for (var i = 0; i < components.length; i++) {
      final component = components[i];
      final ratio = component.ratio.clamp(0, 100);
      segments.add(
        _RatioSegment(
          label: component.name,
          ratio: ratio,
          color: palette[(i + 1) % palette.length],
        ),
      );
    }
    return segments;
  }
}

class _SubjectMetaCard extends StatelessWidget {
  const _SubjectMetaCard({required this.units, required this.teacher});

  final int units;
  final String? teacher;

  @override
  Widget build(BuildContext context) {
    final safeTeacher = (teacher == null || teacher!.trim().isEmpty)
        ? '未設定'
        : teacher!.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetaInfoTile(label: '単位数', value: '$units単位'),
          ),
          Container(width: 1, height: 44, color: AppTheme.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: _MetaInfoTile(label: '担当教員', value: safeTeacher),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaInfoTile extends StatelessWidget {
  const _MetaInfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _RatioSegment {
  const _RatioSegment({
    required this.label,
    required this.ratio,
    required this.color,
  });

  final String label;
  final int ratio;
  final Color color;
}

class _ComponentSliderBar extends StatefulWidget {
  const _ComponentSliderBar({
    required this.value,
    required this.onPreviewChanged,
    required this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onPreviewChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  State<_ComponentSliderBar> createState() => _ComponentSliderBarState();
}

class _ComponentSliderBarState extends State<_ComponentSliderBar> {
  late double _dragValue;

  @override
  void initState() {
    super.initState();
    _dragValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _ComponentSliderBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _dragValue = widget.value;
    }
  }

  void _handleDrag(double localX, double maxWidth) {
    final ratio = (localX / maxWidth).clamp(0.0, 1.0);
    final newValue = (ratio * 100).clamp(0.0, 100.0);
    setState(() {
      _dragValue = newValue;
    });
    widget.onPreviewChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2E86DE);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const thumbSize = 20.0;
                  final trackWidth = constraints.maxWidth;
                  final normalized = (_dragValue / 100).clamp(0.0, 1.0);
                  final thumbX = (trackWidth - thumbSize) * normalized;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      _handleDrag(details.localPosition.dx, trackWidth);
                    },
                    onTapUp: (_) {
                      widget.onChangeEnd(_dragValue);
                    },
                    onHorizontalDragStart: (details) {
                      _handleDrag(details.localPosition.dx, trackWidth);
                    },
                    onHorizontalDragUpdate: (details) {
                      _handleDrag(details.localPosition.dx, trackWidth);
                    },
                    onHorizontalDragEnd: (_) {
                      widget.onChangeEnd(_dragValue);
                    },
                    child: SizedBox(
                      height: 30,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: color.withAlpha(100),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            child: Container(
                              width: trackWidth * normalized,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          Positioned(
                            left: thumbX,
                            child: Container(
                              width: thumbSize,
                              height: thumbSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: color, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _dragValue.toStringAsFixed(0),
              style: const TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
