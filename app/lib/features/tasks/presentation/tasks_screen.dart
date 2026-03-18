import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets.dart';
import '../application/task_controller.dart';
import '../domain/task.dart';
import 'package:intl/intl.dart';

import '../presentation/widgets/task_ai_mentor.dart';
import './widgets/backlog_gantt_chart.dart';
import '../../grades/application/grade_controller.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

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
        final todoTasks = tasks.where((t) => t.status == TaskStatus.todo).toList();
        final doingTasks = tasks.where((t) => t.status == TaskStatus.doing).toList();
        final doneTasks = tasks.where((t) => t.status == TaskStatus.done).toList();

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
              IconButton(
                icon: const Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.neonGreen,
                ),
                onPressed: () => context.push('/tasks/gantt'),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(child: TaskAiMentor(tasks: tasks)),
          ),

          if (doingTasks.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: _StatusHeader(status: TaskStatus.doing),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  void _showAddTaskDialog(BuildContext context, WidgetRef ref, {TaskModel? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTaskSheet(task: task),
    );
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

class _AddTaskSheet extends ConsumerStatefulWidget {
  final TaskModel? task;
  const _AddTaskSheet({this.task});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final _titleController = TextEditingController();
  String? _selectedSubjectId;
  TaskType _selectedType = TaskType.homework;
  TaskPriority _selectedPriority = TaskPriority.medium;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedDeadline = DateTime.now().add(const Duration(days: 1));
  double _estimatedHours = 1.0;
  final _durationController = TextEditingController();
  TaskStatus _selectedStatus = TaskStatus.todo;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _selectedSubjectId = widget.task!.subjectId;
      _selectedType = widget.task!.type;
      _selectedPriority = widget.task!.priority;
      _selectedStartDate = widget.task!.startDate;
      _selectedDeadline = widget.task!.deadline;
      _selectedStatus = widget.task!.status;
      // Slider の範囲 (0.0-20.0) に収まるようにクランプする
      _estimatedHours = widget.task!.estimatedHours.clamp(0.0, 20.0);
    }
    _durationController.text = _estimatedHours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(gradeNotifierProvider);
    final tt = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.neonGreen, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task == null ? 'CREATE NEW TASK' : 'EDIT TASK',
                  style: tt.headlineSmall?.copyWith(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.task != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.neonRed),
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'TITLE',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.neonGreen),
                ),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('SUBJECT (OPTIONAL)'),
            subjects.when(
              data: (subjectList) => DropdownButtonFormField<String>(
                value: subjectList.any((s) => s.id == _selectedSubjectId)
                    ? _selectedSubjectId
                    : null,
                dropdownColor: AppTheme.bgCard,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text(
                      'なし',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  ...subjectList.map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(
                        s.name,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                decoration: const InputDecoration(
                  enabledBorder: InputBorder.none,
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (err, stack) => Text(
                'Failed to load subjects',
                style: TextStyle(color: AppTheme.neonRed, fontSize: 10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('TYPE'),
                      DropdownButtonFormField<TaskType>(
                        initialValue: _selectedType,
                        dropdownColor: AppTheme.bgCard,
                        items: TaskType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.label,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedType = val!),
                        decoration: const InputDecoration(
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('PRIORITY'),
                      DropdownButtonFormField<TaskPriority>(
                        initialValue: _selectedPriority,
                        dropdownColor: AppTheme.bgCard,
                        items: TaskPriority.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.label,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedPriority = val!),
                        decoration: const InputDecoration(
                          enabledBorder: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('START DATE'),
                      InkWell(
                        onTap: () => _pickDateTime(context, isStart: true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: AppTheme.neonGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MM/dd').format(_selectedStartDate),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('DEADLINE'),
                      InkWell(
                        onTap: () => _pickDateTime(context, isStart: false),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flag,
                                size: 16,
                                color: AppTheme.neonOrange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat(
                                  'MM/dd HH:mm',
                                ).format(_selectedDeadline),
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionLabel('STATUS'),
            DropdownButtonFormField<TaskStatus>(
              initialValue: _selectedStatus,
              dropdownColor: AppTheme.bgCard,
              items: TaskStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.label,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val!),
              decoration: const InputDecoration(enabledBorder: InputBorder.none),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSectionLabel(
                    'ESTIMATED HOURS: ${_estimatedHours.toStringAsFixed(1)}h',
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 30,
                  child: TextField(
                    controller: _durationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.border)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
                    ),
                    onChanged: (val) {
                      final h = double.tryParse(val);
                      if (h != null) {
                        setState(() => _estimatedHours = h.clamp(0.0, 20.0));
                      }
                    },
                  ),
                ),
              ],
            ),
            Slider(
              value: _estimatedHours.clamp(0.0, 20.0),
              min: 0.0,
              max: 20.0,
              divisions: 40,
              activeColor: AppTheme.neonGreen,
              inactiveColor: AppTheme.border,
              onChanged: (val) {
                setState(() {
                  _estimatedHours = val;
                  _durationController.text = val.toStringAsFixed(1);
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: AppTheme.bgDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.bgDeep,
                        ),
                      )
                    : Text(
                        widget.task == null ? 'CREATE TASK' : 'UPDATE TASK',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.textSecondary.withAlpha(150),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Future<void> _pickDateTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    final initialDate = isStart ? _selectedStartDate : _selectedDeadline;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      if (isStart) {
        setState(() {
          _selectedStartDate = DateTime(date.year, date.month, date.day);
        });
      } else {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDeadline),
        );
        if (time != null) {
          setState(() {
            _selectedDeadline = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    
    // Ensure startDate is at 00:00:00
    final normalizedStartDate = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
    );

    setState(() => _isSubmitting = true);

    try {
      if (widget.task == null) {
        final task = TaskModel.create(
          title: _titleController.text.trim(),
          subjectId: _selectedSubjectId,
          type: _selectedType,
          priority: _selectedPriority,
          startDate: normalizedStartDate,
          deadline: _selectedDeadline,
          estimatedHours: _estimatedHours,
        );
        await ref.read(tasksProvider.notifier).addTask(task);
      } else {
        final duration = double.tryParse(_durationController.text) ?? _estimatedHours;
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          subjectId: _selectedSubjectId,
          type: _selectedType,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: normalizedStartDate,
          deadline: _selectedDeadline,
          estimatedHours: duration,
        );
        await ref.read(tasksProvider.notifier).updateTask(updatedTask);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save task: $e'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(tasksProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete task: $e'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    }
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => const TasksScreen()._showAddTaskDialog(context, ref, task: task),
      child: _buildBody(context, ref),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final color = _getPriorityColor(task.priority);
    final deadlineStr = DateFormat('MM/dd HH:mm').format(task.deadline);

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
            color: task.priority == TaskPriority.urgent
                ? AppTheme.neonRed
                : AppTheme.border,
            width: task.priority == TaskPriority.urgent ? 2 : 1,
          ),
          boxShadow: task.priority == TaskPriority.urgent
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
                  child: Text(
                    task.type.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(task.status).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(task.status),
                          size: 12,
                          color: _getStatusColor(task.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.status == TaskStatus.done 
                              ? 'DONE' 
                              : '${DateFormat('MM/dd').format(task.startDate)} - $deadlineStr',
                          style: tt.bodySmall?.copyWith(
                            color: task.status == TaskStatus.done
                                ? AppTheme.neonGreen
                                : (_isOverdue(task.deadline)
                                      ? AppTheme.neonRed
                                      : AppTheme.textSecondary),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: tt.titleMedium?.copyWith(
                decoration: task.status == TaskStatus.done
                    ? TextDecoration.lineThrough
                    : null,
                color: task.status == TaskStatus.done
                    ? AppTheme.textSecondary
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text('${task.estimatedHours}h', style: tt.bodySmall),
                const Spacer(),
                _PriorityBadge(priority: task.priority),
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
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
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
