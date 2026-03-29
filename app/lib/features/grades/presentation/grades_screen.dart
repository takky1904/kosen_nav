import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/promotion_status_badge.dart';
import '../../../shared/widgets.dart';
import '../domain/grade_calculator.dart';
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
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
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
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (subjectList) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjectList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final s = subjectList[i];
              final score = GradeCalculator.calcFinalScore(s);
              final accentColor = _scoreAccentColor(score);

              return InkWell(
                    key: ValueKey('grade_${s.id}'),
                    onTap: () => context.go('/grades/${s.id}'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: score != null
                              ? accentColor.withAlpha(160)
                              : AppTheme.border,
                          width: score != null ? 1.4 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withAlpha(
                              score != null ? 28 : 0,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 54,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              s.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: tt.titleLarge?.copyWith(
                                fontSize: 19,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                score != null ? score.toStringAsFixed(1) : '--',
                                style: TextStyle(
                                  color: _scoreTextColor(score),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '/ 100',
                                style: tt.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
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

  Color _scoreTextColor(double? s) {
    if (s == null) return AppTheme.textSecondary;
    return _scoreAccentColor(s);
  }

  Color _scoreAccentColor(double? s) {
    if (s == null) return AppTheme.border;
    if (s >= 80) return AppTheme.neonGreen;
    if (s >= 70) return AppTheme.neonYellow;
    if (s >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }
}
