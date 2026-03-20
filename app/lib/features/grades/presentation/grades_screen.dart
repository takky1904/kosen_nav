import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/promotion_status_badge.dart';
import '../../../shared/widgets.dart';
import '../domain/grade_calculator.dart';
import '../domain/subject_model.dart';
import '../application/grade_controller.dart';
import '../../simulation/application/simulation_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GradesScreen extends ConsumerWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(gradeNotifierProvider);
    final sim = ref.watch(simulationProvider);
    final tt = Theme.of(context).textTheme;

    return sim.when(
      data: (simData) => Scaffold(
        backgroundColor: AppTheme.bgDeep,
        appBar: AppBar(
          leading: const MenuToggleButton(),
          title: Text('履修科目', style: tt.headlineLarge),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PromotionStatusBadge(
                status: simData.status,
                failCount: simData.failCount,
                compact: true,
              ),
            ),
          ],
        ),
        body: subjects.when(
          data: (subjectList) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjectList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final s = subjectList[i];
              final score = GradeCalculator.calcFinalScore(s);
              final testAvg = GradeCalculator.calcTestAverage(s.testScores);
              final isAtRisk = simData.atRiskSubjectIds.contains(s.id);
              final isFailing = score != null && score < 60;

              return InkWell(
                    key: ValueKey('grade_${s.id}'),
                    onTap: () => context.go('/grades/${s.id}'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFailing
                              ? AppTheme.neonRed.withAlpha(200)
                              : isAtRisk
                              ? AppTheme.neonOrange.withAlpha(180)
                              : AppTheme.border,
                          width: isFailing || isAtRisk ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 単位バッジ
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Center(
                              child: Text(
                                '${s.units}',
                                style: const TextStyle(
                                  color: AppTheme.neonGreen,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: tt.titleLarge?.copyWith(
                                    fontSize: 15,
                                    color: isFailing
                                        ? AppTheme.neonRed
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: _InfoChip(
                                        label: 'テスト',
                                        value: testAvg != null
                                            ? '${testAvg.toStringAsFixed(1)}点'
                                            : '--',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: _InfoChip(
                                        label: '平常点',
                                        value: s.regularScore != null
                                            ? '${s.regularScore!.toStringAsFixed(0)}点'
                                            : '--',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Final Score
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                score != null ? score.toStringAsFixed(1) : '--',
                                style: TextStyle(
                                  color: _scoreColor(score),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: tt.bodyMedium?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    duration: 500.ms,
                  );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddSubjectDialog(context, ref),
          backgroundColor: AppTheme.neonGreen,
          foregroundColor: AppTheme.bgDeep,
          icon: const Icon(Icons.add),
          label: const Text(
            '科目追加',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
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

  Color _scoreColor(double? s) {
    if (s == null) return AppTheme.textSecondary;
    if (s >= 80) return AppTheme.neonGreen;
    if (s >= 70) return AppTheme.neonYellow;
    if (s >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    int units = 2;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text('科目追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '科目名'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('単位数: '),
                  DropdownButton<int>(
                    value: units,
                    dropdownColor: AppTheme.bgCard,
                    items: [1, 2, 3, 4, 5]
                        .map(
                          (u) =>
                              DropdownMenuItem(value: u, child: Text('$u 単位')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => units = v ?? 2),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  ref
                      .read(gradeNotifierProvider.notifier)
                      .addSubject(
                        SubjectModel.create(
                          name: nameCtrl.text.trim(),
                          units: units,
                        ),
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
