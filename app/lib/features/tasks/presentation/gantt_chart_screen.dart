import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../application/task_controller.dart';
import '../domain/task.dart';
import 'widgets/backlog_gantt_chart.dart';

class GanttChartScreen extends ConsumerWidget {
  const GanttChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final tt = Theme.of(context).textTheme;

    return tasksAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
      data: (tasks) {
        // 開始日順にソート (ガントチャート用)
        final displayTasks = List<TaskModel>.from(tasks)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          appBar: AppBar(
            title: Text('GANTT CHART', style: tt.headlineLarge),
            backgroundColor: AppTheme.bgDeep,
          ),
          body: displayTasks.isEmpty
              ? const Center(
                  child: Text(
                    'タスクはありません', 
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : BacklogGanttChart(tasks: displayTasks),
        );
      },
    );
  }
}
