import 'package:uuid/uuid.dart';

enum TaskType {
  report,
  test,
  homework,
  prep,
  review;

  String get label {
    switch (this) {
      case TaskType.report:
        return 'レポート';
      case TaskType.test:
        return 'テスト勉強';
      case TaskType.homework:
        return '課題';
      case TaskType.prep:
        return '予習';
      case TaskType.review:
        return '復習';
    }
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get label {
    switch (this) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '緊急';
    }
  }
}

enum TaskStatus {
  todo,
  doing,
  done;

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return '未着手';
      case TaskStatus.doing:
        return '進行中';
      case TaskStatus.done:
        return '完了';
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String? subjectId; // 関連する科目ID
  final TaskType type;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime startDate;
  final DateTime deadline;
  final double estimatedHours;

  const TaskModel({
    required this.id,
    required this.title,
    this.subjectId,
    required this.type,
    required this.priority,
    required this.status,
    required this.startDate,
    required this.deadline,
    required this.estimatedHours,
  });

  factory TaskModel.create({
    required String title,
    String? subjectId,
    required TaskType type,
    TaskPriority priority = TaskPriority.medium,
    DateTime? startDate,
    required DateTime deadline,
    double estimatedHours = 1.0,
  }) {
    return TaskModel(
      id: const Uuid().v4(),
      title: title,
      subjectId: subjectId,
      type: type,
      priority: priority,
      status: TaskStatus.todo,
      startDate: startDate ?? DateTime.now(),
      deadline: deadline,
      estimatedHours: estimatedHours,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null || value is! String || value.isEmpty) return DateTime.now();
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subjectId: (json['subject_id']?.toString().isNotEmpty == true)
          ? json['subject_id'].toString()
          : (json['subjectId']?.toString().isNotEmpty == true
              ? json['subjectId'].toString()
              : null),
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.homework,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      startDate: json['start_date'] != null 
          ? parseDate(json['start_date'])
          : parseDate(json['startDate']),
      deadline: parseDate(json['deadline']),
      estimatedHours: parseDouble(json['duration'] ?? json['estimatedHours']),
    );
  }

  TaskModel copyWith({
    String? title,
    String? subjectId,
    TaskType? type,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? startDate,
    DateTime? deadline,
    double? estimatedHours,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      estimatedHours: estimatedHours ?? this.estimatedHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject_id': subjectId,
      'type': type.name,
      'priority': priority.name,
      'status': status.name,
      'start_date': startDate.toIso8601String(),
      'deadline': deadline.toIso8601String(),
      'duration': estimatedHours,
    };
  }
}
