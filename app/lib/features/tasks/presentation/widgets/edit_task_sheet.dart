import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../grades/application/grade_controller.dart';
import '../../domain/task.dart';
import '../../application/task_controller.dart';

class EditTaskSheet extends ConsumerStatefulWidget {
  final TaskModel? task;
  const EditTaskSheet({super.key, this.task});

  @override
  ConsumerState<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends ConsumerState<EditTaskSheet> {
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
      _estimatedHours = widget.task!.estimatedHours.clamp(0.0, 20.0);
    }
    _durationController.text = _estimatedHours.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(gradeNotifierProvider);
    final tt = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomPadding),
      decoration: const BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.task == null ? 'CREATE TASK' : 'EDIT TASK',
                  style: tt.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                if (widget.task != null)
                  IconButton(
                    onPressed: _delete,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.neonRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.neonRed,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Basic Info Section
            _buildSectionCard(
              context,
              title: 'BASIC INFO',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: AppTheme.inputDecoration('TASK TITLE').copyWith(
                      prefixIcon: const Icon(
                        Icons.edit_note_rounded,
                        color: AppTheme.neonGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  subjects.when(
                    data: (subjectList) => _buildSubjectDropdown(subjectList),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => const Text('Error loading subjects'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Detail Settings Section
            _buildSectionCard(
              context,
              title: 'DETAILS',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('STATUS'),
                  const SizedBox(height: 12),
                  _buildStatusSelector(),
                  const SizedBox(height: 20),
                  _buildLabel('PRIORITY'),
                  const SizedBox(height: 12),
                  _buildPrioritySelector(),
                  const SizedBox(height: 20),
                  _buildLabel('TYPE'),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Time & Period Section
            _buildSectionCard(
              context,
              title: 'TIME & PERIOD',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('START DATE'),
                      _buildLabel('DEADLINE'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimePickerTile(
                          context,
                          date: _selectedStartDate,
                          onTap: () => _pickDateTime(context, isStart: true),
                          color: AppTheme.neonGreen,
                          icon: Icons.calendar_today_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimePickerTile(
                          context,
                          date: _selectedDeadline,
                          onTap: () => _pickDateTime(context, isStart: false),
                          color: AppTheme.neonOrange,
                          icon: Icons.flag_rounded,
                          showTime: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('ESTIMATED DURATION'),
                      Text(
                        '${_estimatedHours.toStringAsFixed(1)}h',
                        style: const TextStyle(
                          color: AppTheme.neonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.neonGreen,
                      inactiveTrackColor: AppTheme.border.withOpacity(0.2),
                      thumbColor: AppTheme.neonGreen,
                      overlayColor: AppTheme.neonGreen.withOpacity(0.2),
                      valueIndicatorColor: AppTheme.neonGreen,
                      valueIndicatorTextStyle: const TextStyle(
                        color: AppTheme.bgDeep,
                        fontWeight: FontWeight.bold,
                      ),
                      trackHeight: 6,
                      showValueIndicator: ShowValueIndicator.onDrag,
                    ),
                    child: Slider(
                      value: _estimatedHours,
                      min: 0.0,
                      max: 20.0,
                      divisions: 40,
                      label: '${_estimatedHours.toStringAsFixed(1)}h',
                      onChanged: (val) {
                        setState(() {
                          _estimatedHours = val;
                          _durationController.text = val.toStringAsFixed(1);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonGreen.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: AppTheme.bgDeep,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: AppTheme.bgDeep)
                      : Text(
                          widget.task == null
                              ? 'CREATE NEW TASK'
                              : 'UPDATE TASK',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textSecondary.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSubjectDropdown(List<dynamic> subjectList) {
    return DropdownButtonFormField<String>(
      initialValue: subjectList.any((s) => s.id == _selectedSubjectId)
          ? _selectedSubjectId
          : null,
      dropdownColor: AppTheme.bgCard,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('なし', style: TextStyle(color: AppTheme.textSecondary)),
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
      decoration: AppTheme.inputDecoration('SUBJECT').copyWith(
        prefixIcon: const Icon(Icons.book_outlined, color: AppTheme.neonGreen),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskStatus.values.map((s) {
          final isSelected = _selectedStatus == s;
          final color = isSelected
              ? _getStatusColor(s)
              : AppTheme.textSecondary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppTheme.border.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(s), size: 16, color: color),
                    const SizedBox(width: 8),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: TaskPriority.values.map((p) {
        final isSelected = _selectedPriority == p;
        final color = _getPriorityColor(p);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: p == TaskPriority.urgent ? 0 : 8),
            child: InkWell(
              onTap: () => setState(() => _selectedPriority = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : AppTheme.border.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    p.label,
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskType.values.map((t) {
          final isSelected = _selectedType == t;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(t.label),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedType = t),
              backgroundColor: Colors.transparent,
              selectedColor: AppTheme.neonGreen.withOpacity(0.2),
              checkmarkColor: AppTheme.neonGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.neonGreen : AppTheme.textSecondary,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.neonGreen
                      : AppTheme.border.withOpacity(0.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateTimePickerTile(
    BuildContext context, {
    required DateTime date,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
    bool showTime = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              DateFormat(showTime ? 'MM/dd HH:mm' : 'MM/dd').format(date),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _pickDateTime(
    BuildContext context, {
    required bool isStart,
  }) async {
    if (isStart) {
      // When picking start date, prevent choosing a date after the current deadline
      final lastAllowed = DateTime(
        _selectedDeadline.year,
        _selectedDeadline.month,
        _selectedDeadline.day,
      );
      final initialDate = _selectedStartDate.isAfter(lastAllowed)
          ? lastAllowed
          : _selectedStartDate;
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2025),
        lastDate: lastAllowed,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonGreen,
              onPrimary: AppTheme.bgDeep,
              surface: AppTheme.bgCard,
            ),
          ),
          child: child!,
        ),
      );
      if (date != null) {
        setState(
          () => _selectedStartDate = DateTime(date.year, date.month, date.day),
        );
      }
    } else {
      // When picking deadline, prevent choosing a date before the current start date
      final firstAllowed = DateTime(
        _selectedStartDate.year,
        _selectedStartDate.month,
        _selectedStartDate.day,
      );
      final initialDate = _selectedDeadline.isBefore(firstAllowed)
          ? firstAllowed
          : _selectedDeadline;
      final date = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstAllowed,
        lastDate: DateTime(2030),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonGreen,
              onPrimary: AppTheme.bgDeep,
              surface: AppTheme.bgCard,
            ),
          ),
          child: child!,
        ),
      );
      if (date != null) {
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
    final normalizedStartDate = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
    );
    // Validate start <= deadline
    if (normalizedStartDate.isAfter(_selectedDeadline)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start date must be on or before the deadline'),
          backgroundColor: AppTheme.neonRed,
        ),
      );
      return;
    }

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
        final updatedTask = widget.task!.copyWith(
          title: _titleController.text.trim(),
          subjectId: _selectedSubjectId,
          type: _selectedType,
          priority: _selectedPriority,
          status: _selectedStatus,
          startDate: normalizedStartDate,
          deadline: _selectedDeadline,
          estimatedHours: _estimatedHours,
        );
        await ref.read(tasksProvider.notifier).updateTask(updatedTask);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
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
            content: Text('Failed: $e'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    }
  }
}
