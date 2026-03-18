import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:intl/intl.dart';
import '../../domain/task.dart';
import '../../../../core/theme/app_theme.dart';

class BacklogGanttChart extends StatefulWidget {
  final List<TaskModel> tasks;
  final bool isPreview;
  const BacklogGanttChart({
    required this.tasks,
    this.isPreview = false,
    super.key,
  });

  @override
  State<BacklogGanttChart> createState() => _BacklogGanttChartState();
}

class _BacklogGanttChartState extends State<BacklogGanttChart> {
  late LinkedScrollControllerGroup _horizontalControllers;
  late ScrollController _headerController;
  late TransformationController _gridTransformationController;
  
  final double _dayWidth = 40.0;
  final double _rowHeight = 60.0;
  final double _bottomPadding = 100.0;
  
  late DateTime _chartStartDate;
  late int _totalDays;

  @override
  void initState() {
    super.initState();
    _horizontalControllers = LinkedScrollControllerGroup();
    _headerController = _horizontalControllers.addAndGet();
    _gridTransformationController = TransformationController();
    
    // InteractiveViewerの移動をヘッダーに同期
    _gridTransformationController.addListener(() {
      final x = -_gridTransformationController.value.storage[12];
      _headerController.jumpTo(x);
    });

    _updateChartRange();
  }

  @override
  void didUpdateWidget(BacklogGanttChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != oldWidget.tasks) {
      _updateChartRange();
    }
  }

  void _updateChartRange() {
    if (widget.tasks.isEmpty) {
      final now = DateTime.now();
      _chartStartDate = DateTime(now.year, now.month, 1);
      _totalDays = 31;
      return;
    }

    DateTime minDate = widget.tasks.first.startDate;
    DateTime maxDate = widget.tasks.first.deadline;

    for (var task in widget.tasks) {
      if (task.startDate.isBefore(minDate)) minDate = task.startDate;
      if (task.deadline.isAfter(maxDate)) maxDate = task.deadline;
    }

    // 前後にバッファを持たせる（1週間程度）
    _chartStartDate = DateTime(minDate.year, minDate.month, minDate.day).subtract(const Duration(days: 7));
    final chartEndDate = DateTime(maxDate.year, maxDate.month, maxDate.day).add(const Duration(days: 7));
    _totalDays = chartEndDate.difference(_chartStartDate).inDays + 1;
  }

  @override
  void dispose() {
    _headerController.dispose();
    _gridTransformationController.dispose();
    super.dispose();
  }

  String _getMonthLabel() {
    final startFormat = DateFormat('yyyy年MM月');
    
    final startLabel = startFormat.format(_chartStartDate);
    final endLabel = startFormat.format(_chartStartDate.add(Duration(days: _totalDays - 1)));
    
    if (startLabel == endLabel) {
      return startLabel;
    } else {
      return '$startLabel - ${DateFormat('MM月').format(_chartStartDate.add(Duration(days: _totalDays - 1)))}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // タスクを階段状に配置するためにソート（開始日順）
    final sortedTasks = List<TaskModel>.from(widget.tasks)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = _totalDays * _dayWidth;
        // 画面の高さいっぱいに広げる
        final gridHeight = ((sortedTasks.length * _rowHeight) + _bottomPadding)
            .clamp(constraints.maxHeight, double.infinity);

        return Column(
          children: [
            // ── 年月ヘッダー ──────────────────────────────────────────────────
            if (!widget.isPreview)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.centerLeft,
                child: Text(
                  _getMonthLabel(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // ── 日付軸（内部的には横スクロール、InteractiveViewerと同期） ──────────
            SizedBox(
              height: 40,
              child: SingleChildScrollView(
                key: const ValueKey('gantt_header_scroll'),
                controller: _headerController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(), // InteractiveViewer側で制御
                child: Row(
                  children: List.generate(_totalDays, (index) {
                    final date = _chartStartDate.add(Duration(days: index));
                    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                    final isFirstDayOfMonth = date.day == 1;

                    return Container(
                      width: _dayWidth,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isWeekend ? Colors.white.withAlpha(25) : null,
                        border: Border(
                          right: BorderSide(color: AppTheme.border.withAlpha(128)),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isFirstDayOfMonth && _totalDays > 31)
                            Text(
                              '${date.month}/',
                              style: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isFirstDayOfMonth ? AppTheme.neonGreen : AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: isFirstDayOfMonth ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            const Divider(height: 1, color: AppTheme.border),
            
            // ── メイングリッド（2Dスクロール） ──────────────────────────────────
            Expanded(
              child: InteractiveViewer(
                transformationController: _gridTransformationController,
                constrained: false,
                scaleEnabled: false, // 拡大縮小は無効化、パン移動のみ
                minScale: 1.0,
                maxScale: 1.0,
                child: SizedBox(
                  height: gridHeight,
                  width: gridWidth,
                  child: Stack(
                    children: [
                      // 背景のグリッド（垂直線・水平線）
                      Stack(
                        children: [
                          // 垂直線（日にちの境界）
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Row(
                              children: List.generate(_totalDays, (index) {
                                final date = _chartStartDate.add(Duration(days: index));
                                final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                                return Container(
                                  width: _dayWidth,
                                  decoration: BoxDecoration(
                                    color: isWeekend ? Colors.white.withAlpha(20) : null,
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withAlpha(45),
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          // 水平線（タスクごとの境界＋余白）
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Column(
                              children: List.generate(
                                (gridHeight / _rowHeight).floor(),
                                (index) => Container(
                                  height: _rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppTheme.border.withAlpha(80),
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // タスクバー
                      ...Iterable.generate(sortedTasks.length).map((i) {
                        final task = sortedTasks[i];
                        
                        // 日付のみを取り出して計算（時刻によるズレを防ぐ）
                        final startMidnight = DateTime(task.startDate.year, task.startDate.month, task.startDate.day);
                        final endMidnight = DateTime(task.deadline.year, task.deadline.month, task.deadline.day);
                        final chartStartMidnight = DateTime(_chartStartDate.year, _chartStartDate.month, _chartStartDate.day);

                        final startOffset = startMidnight.difference(chartStartMidnight).inDays * _dayWidth;
                        final durationDays = endMidnight.difference(startMidnight).inDays + 1;
                        final width = (durationDays * _dayWidth).clamp(_dayWidth / 2, double.infinity);

                        return Positioned(
                          top: i * _rowHeight + 15,
                          left: startOffset,
                          child: _GanttTaskBar(
                            task: task,
                            width: width,
                            height: 30,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GanttTaskBar extends StatelessWidget {
  final TaskModel task;
  final double width;
  final double height;

  const _GanttTaskBar({
    required this.task,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getTaskColor();
    final isDone = task.status == TaskStatus.done;
    final isDoing = task.status == TaskStatus.doing;
    
    // 背景の帯を透過させないように不透明にする
    const opacity = 1.0;

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((opacity * 255).toInt()),
        borderRadius: BorderRadius.circular(height / 2),
        border: isDoing ? Border.all(color: Colors.white.withAlpha(128), width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(76),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStatusIcon(task.status),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isDoing ? FontWeight.bold : FontWeight.normal,
                overflow: TextOverflow.ellipsis,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(TaskStatus status) {
    IconData iconData;
    Color iconColor;
    switch (status) {
      case TaskStatus.todo:
        iconData = Icons.access_time_rounded;
        iconColor = Colors.redAccent;
        break;
      case TaskStatus.doing:
        iconData = Icons.play_arrow_rounded;
        iconColor = Colors.blueAccent;
        break;
      case TaskStatus.done:
        iconData = Icons.check_rounded;
        iconColor = Colors.greenAccent;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 10, color: iconColor),
    );
  }

  Color _getTaskColor() {
    switch (task.status) {
      case TaskStatus.todo: return Colors.redAccent;
      case TaskStatus.doing: return Colors.blueAccent;
      case TaskStatus.done: return Colors.greenAccent;
    }
  }
}
