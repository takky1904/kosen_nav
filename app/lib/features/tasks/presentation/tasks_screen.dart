import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../application/task_controller.dart';
import '../data/teams_auth_service.dart';
import '../domain/task.dart';
import '../domain/teams_assignment.dart';
import 'package:intl/intl.dart';

import 'widgets/task_ai_mentor.dart';
import 'widgets/backlog_gantt_chart.dart';
import 'widgets/edit_task_sheet.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final profilePhotoBytes = ref.watch(teamsProfilePhotoProvider);
    final tt = Theme.of(context).textTheme;

    return tasksAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.neonGreen),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
        ),
      ),
      data: (tasks) {
        final todoTasks = tasks
            .where((t) => t.status == TaskStatus.todo)
            .toList();
        final doingTasks = tasks
            .where((t) => t.status == TaskStatus.doing)
            .toList();
        final doneTasks = tasks
            .where((t) => t.status == TaskStatus.done)
            .toList();

        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                leading: const MenuToggleButton(),
                title: Text('タスク', style: tt.headlineLarge),
                backgroundColor: AppTheme.bgDeep,
                actions: [
                  TextButton.icon(
                    onPressed: () => _syncWithTeams(context, ref),
                    icon: const Icon(
                      Icons.sync,
                      size: 16,
                      color: AppTheme.neonBlue,
                    ),
                    label: const Text(
                      'Teamsと同期',
                      style: TextStyle(color: AppTheme.neonBlue, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppTheme.neonGreen,
                    ),
                    onPressed: () => context.push('/tasks/gantt'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.bgCard,
                      backgroundImage: profilePhotoBytes != null
                          ? MemoryImage(profilePhotoBytes)
                          : null,
                      child: profilePhotoBytes == null
                          ? const Icon(
                              Icons.person,
                              size: 18,
                              color: AppTheme.textSecondary,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ガントチャート',
                            style: tt.labelLarge?.copyWith(
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/tasks/gantt'),
                            child: const Text(
                              '詳細を見る',
                              style: TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/tasks/gantt'),
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.border.withOpacity(0.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              IgnorePointer(
                                child: BacklogGanttChart(
                                  key: const ValueKey('gantt_preview'),
                                  tasks: tasks,
                                  isPreview: true,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        AppTheme.bgCard.withOpacity(0),
                                        AppTheme.bgCard,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverToBoxAdapter(child: TaskAiMentor(tasks: tasks)),
              ),

              if (doingTasks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _StatusHeader(status: TaskStatus.doing),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: doingTasks[index],
                      ).animate().fadeIn().slideX(),
                      childCount: doingTasks.length,
                    ),
                  ),
                ),
              ],

              if (todoTasks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _StatusHeader(status: TaskStatus.todo),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: todoTasks[index],
                      ).animate().fadeIn().slideX(),
                      childCount: todoTasks.length,
                    ),
                  ),
                ),
              ],

              if (doneTasks.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: _StatusHeader(status: TaskStatus.done),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _TaskCard(
                        task: doneTasks[index],
                      ).animate().fadeIn().slideX(),
                      childCount: doneTasks.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTaskDialog(context, ref),
            backgroundColor: AppTheme.neonGreen,
            child: const Icon(Icons.add, color: AppTheme.bgDeep),
          ),
        );
      },
    );
  }

  void _showAddTaskDialog(
    BuildContext context,
    WidgetRef ref, {
    TaskModel? task,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTaskSheet(task: task),
    );
  }

  Future<void> _syncWithTeams(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final authService = TeamsAuthService();
      final token = await authService.signInAndGetAccessToken();
      if (token.isEmpty) {
        throw Exception('アクセストークンが空です。');
      }

      final Uint8List? photo = await authService.fetchProfilePhotoBytes(token);
      ref.read(teamsProfilePhotoProvider.notifier).setPhoto(photo);

      // 取得処理は次段階。既存タスクを壊さない安全なマージ経路のみ先に用意する。
      await ref
          .read(tasksProvider.notifier)
          .mergeTeamsAssignments(const <TeamsAssignment>[]);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            photo == null
                ? 'Teamsログインに成功しました（プロフィール画像は未設定です）。'
                : 'Teamsログインに成功しました。',
          ),
        ),
      );
    } catch (e) {
      ref.read(teamsProfilePhotoProvider.notifier).clear();
      messenger.showSnackBar(SnackBar(content: Text('Teams同期の開始に失敗しました: $e')));
    }
  }
}

class _StatusHeader extends StatelessWidget {
  final TaskStatus status;
  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            status.label.toUpperCase(),
            style: tt.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withAlpha(50), thickness: 1)),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case TaskStatus.todo:
        return AppTheme.neonRed;
      case TaskStatus.doing:
        return AppTheme.neonBlue;
      case TaskStatus.done:
        return AppTheme.neonGreen;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.doing:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
    }
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () =>
          const TasksScreen()._showAddTaskDialog(context, ref, task: task),
      child: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final color = _getPriorityColor(task.priority);

    return Dismissible(
      key: Key(task.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.neonGreen.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: AppTheme.neonGreen),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.neonRed.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: AppTheme.neonRed),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          ref
              .read(tasksProvider.notifier)
              .updateStatus(task.id, TaskStatus.done);
        } else {
          ref.read(tasksProvider.notifier).deleteTask(task.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                (task.status != TaskStatus.done &&
                    task.priority == TaskPriority.urgent)
                ? AppTheme.neonRed
                : AppTheme.border.withAlpha(
                    task.status == TaskStatus.done ? 50 : 255,
                  ),
            width:
                (task.status != TaskStatus.done &&
                    task.priority == TaskPriority.urgent)
                ? 2
                : 1,
          ),
          boxShadow:
              (task.status != TaskStatus.done &&
                  task.priority == TaskPriority.urgent)
              ? [
                  BoxShadow(
                    color: AppTheme.neonRed.withAlpha(40),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withAlpha(100)),
                  ),
                  child: Text(task.type.label, style: TextStyle(color: color)),
                ),
                const Spacer(),
                PopupMenuButton<TaskStatus>(
                  onSelected: (status) => ref
                      .read(tasksProvider.notifier)
                      .updateStatus(task.id, status),
                  color: AppTheme.bgCard,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  itemBuilder: (context) => TaskStatus.values
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(s),
                                size: 16,
                                color: _getStatusColor(s),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.label,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(task.status).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(task.status),
                          size: 14,
                          color: _getStatusColor(task.status),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          task.status.label.toUpperCase(),
                          style: tt.bodySmall?.copyWith(
                            color: _getStatusColor(task.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: _getStatusColor(task.status).withAlpha(180),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: tt.titleMedium?.copyWith(
                height: 1.3,
                decoration: task.status == TaskStatus.done
                    ? TextDecoration.lineThrough
                    : null,
                color: task.status == TaskStatus.done
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${task.estimatedHours.toStringAsFixed(1)}h',
                  style: tt.bodySmall?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 12),
                Text(
                  '${DateFormat('MM/dd').format(task.startDate)} - ${DateFormat('MM/dd').format(task.deadline)}',
                  style: tt.bodySmall?.copyWith(
                    color:
                        _isOverdue(task.deadline) &&
                            task.status != TaskStatus.done
                        ? AppTheme.neonRed
                        : AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                _PriorityBadge(
                  priority: task.priority,
                  isDone: task.status == TaskStatus.done,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return AppTheme.textSecondary;
      case TaskPriority.medium:
        return AppTheme.neonGreen;
      case TaskPriority.high:
        return AppTheme.neonOrange;
      case TaskPriority.urgent:
        return AppTheme.neonRed;
    }
  }

  bool _isOverdue(DateTime deadline) => deadline.isBefore(DateTime.now());

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.doing:
        return Icons.play_circle_outline;
      case TaskStatus.done:
        return Icons.check_circle_outline;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return AppTheme.neonRed;
      case TaskStatus.doing:
        return AppTheme.neonBlue;
      case TaskStatus.done:
        return AppTheme.neonGreen;
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool isDone;
  const _PriorityBadge({required this.priority, this.isDone = false});

  @override
  Widget build(BuildContext context) {
    var color = _getColor();
    if (isDone) {
      color = AppTheme.textSecondary.withAlpha(150);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getColor() {
    switch (priority) {
      case TaskPriority.low:
        return AppTheme.textSecondary;
      case TaskPriority.medium:
        return AppTheme.neonGreen;
      case TaskPriority.high:
        return AppTheme.neonOrange;
      case TaskPriority.urgent:
        return AppTheme.neonRed;
    }
  }
}
