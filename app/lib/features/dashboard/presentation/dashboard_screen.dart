import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/promotion_status_badge.dart';
import '../../../shared/widgets.dart';
import '../../../features/grades/domain/grade_calculator.dart';
import '../../../features/grades/domain/subject_model.dart';
import '../../../features/grades/application/grade_controller.dart';
import '../../../features/simulation/application/simulation_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(gradeNotifierProvider);
    final sim = ref.watch(simulationProvider);
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: CustomScrollView(
        slivers: [
          // ── AppBar ────────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            leading: const MenuToggleButton(),
            title: Text('KOSEN NAV', style: AppTheme.logoStyle),
            backgroundColor: AppTheme.bgDeep,
            actions: const [SizedBox(width: 16)],
          ),

          sim.when(
            data: (simData) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── GPA Card ────────────────────────────────────────────────
                  _GpaCard(sim: simData)
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 24),

                  // ── Promotion Status Badge ──
                  PromotionStatusBadge(
                        status: simData.status,
                        failCount: simData.failCount,
                        isLarge: true,
                      )
                      .animate()
                      .fade(duration: 400.ms, delay: 100.ms)
                      .slideY(
                        begin: 0.2,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 450.ms,
                      ),
                  const SizedBox(height: 32),

                  // ── Section header ──────────────────────────────────────────
                  Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('履修科目', style: tt.headlineMedium),
                          TextButton.icon(
                            onPressed: () => context.go('/grades'),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('すべて見る'),
                          ),
                        ],
                      )
                      .animate()
                      .fade(duration: 400.ms)
                      .slideY(
                        begin: 0.3,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 400.ms,
                      ),
                  const SizedBox(height: 12),

                  // ── Subject Summary Cards ────────────────────────────────────
                  ...subjects.when(
                    data: (subjectList) => subjectList.map((s) {
                      final score = GradeCalculator.calcFinalScore(s);
                      final isAtRisk = simData.atRiskSubjectIds.contains(s.id);
                      return Padding(
                            key: ValueKey('dash_${s.id}'),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _SubjectSummaryCard(
                              name: s.name,
                              units: s.units,
                              score: score,
                              isAtRisk: isAtRisk,
                              onTap: () => context.go('/grades/${s.id}'),
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
                    }).toList(),
                    loading: () => [
                      const Center(child: CircularProgressIndicator()),
                    ],
                    error: (err, stack) => [Center(child: Text('Error: $err'))],
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }
}

// ── GPA Card ─────────────────────────────────────────────────────────────────

class _GpaCard extends StatelessWidget {
  final SimulationState sim;
  const _GpaCard({required this.sim});

  @override
  Widget build(BuildContext context) {
    final avg = sim.weightedAverage;
    final rank = sim.overallRank;
    final rankColor = rank != null ? _rankColor(rank) : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score circle
          _ScoreCircle(
            score: avg,
            color: avg != null ? _scoreColor(avg) : AppTheme.textSecondary,
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('加重平均', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      avg != null ? avg.toStringAsFixed(1) : '--',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(width: 4),
                    Text('点', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                if (rank != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: rankColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: rankColor.withAlpha(150)),
                    ),
                    child: Text(
                      'RANK ${rank.label} — ${rank.description}',
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('不可科目', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${sim.failCount}',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: sim.failCount > 0
                      ? AppTheme.neonRed
                      : AppTheme.neonGreen,
                ),
              ),
              Text('科目', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Color _rankColor(GradeRank r) {
    switch (r) {
      case GradeRank.a:
        return AppTheme.neonGreen;
      case GradeRank.b:
        return AppTheme.neonGreen.withAlpha(200);
      case GradeRank.c:
        return AppTheme.neonYellow;
      case GradeRank.d:
        return AppTheme.neonRed;
    }
  }

  Color _scoreColor(double avg) {
    if (avg >= 80) return AppTheme.neonGreen;
    if (avg >= 70) return AppTheme.neonYellow;
    if (avg >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }
}

class _ScoreCircle extends StatelessWidget {
  final double? score;
  final Color color;
  const _ScoreCircle({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score != null ? score! / 100 : 0,
            strokeWidth: 5,
            color: color,
            backgroundColor: AppTheme.border,
          ),
          Text(
            score != null ? score!.toStringAsFixed(0) : '--',
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

// ── Subject Summary Card ──────────────────────────────────────────────────────

class _SubjectSummaryCard extends StatelessWidget {
  final String name;
  final int units;
  final double? score;
  final bool isAtRisk;
  final VoidCallback onTap;

  const _SubjectSummaryCard({
    required this.name,
    required this.units,
    required this.score,
    required this.isAtRisk,
    required this.onTap,
  });

  Color get _scoreColor {
    if (score == null) return AppTheme.textSecondary;
    if (score! >= 80) return AppTheme.neonGreen;
    if (score! >= 70) return AppTheme.neonYellow;
    if (score! >= 60) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isAtRisk ? AppTheme.neonRed.withAlpha(180) : AppTheme.border,
            width: isAtRisk ? 1.5 : 1,
          ),
          boxShadow: isAtRisk
              ? [
                  BoxShadow(
                    color: AppTheme.neonRed.withAlpha(40),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // 不可アイコン
            if (isAtRisk)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.warning_rounded,
                  color: AppTheme.neonRed,
                  size: 18,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 15,
                      color: isAtRisk ? AppTheme.neonRed : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '$units 単位',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            // Score bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  score != null ? '${score!.toStringAsFixed(1)}点' : '--',
                  style: TextStyle(
                    color: _scoreColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 80,
                  height: 4,
                  child: score != null
                      ? LinearProgressIndicator(
                          value: score! / 100,
                          color: _scoreColor,
                          backgroundColor: AppTheme.border,
                          borderRadius: BorderRadius.circular(2),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
