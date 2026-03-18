import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/task.dart';

class TaskAiMentor extends StatelessWidget {
  final List<TaskModel> tasks;

  const TaskAiMentor({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final advice = _generateAdvice();
    if (advice == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neonRed.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonRed.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt, color: AppTheme.neonRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI MENTOR WARNING',
                  style: TextStyle(
                    color: AppTheme.neonRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _generateAdvice() {
    final now = DateTime.now();
    final pendingTasks = tasks.where((t) => t.status != TaskStatus.done).toList();
    
    if (pendingTasks.isEmpty) return null;

    // 緊急のタスクがあるか
    final urgentTasks = pendingTasks.where((t) => t.priority == TaskPriority.urgent).toList();
    if (urgentTasks.isNotEmpty) {
      final t = urgentTasks.first;
      return '「${t.title}」の締切が迫っています！最優先で取り掛かりましょう。';
    }

    // 締切と見積もり時間の計算
    for (final t in pendingTasks) {
      final remaining = t.deadline.difference(now).inHours;
      if (remaining > 0 && remaining < t.estimatedHours * 2) {
        return '「${t.title}」は${t.estimatedHours}時間かかると予想されます。今のうちに少しでも進めておいた方が良さそうです。';
      }
    }

    return '順調です。計画通りに進めましょう。';
  }
}
