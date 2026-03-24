import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task.dart';
import '../domain/teams_assignment.dart';
import '../data/task_repository.dart';

class TeamsProfilePhotoNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void setPhoto(Uint8List? bytes) => state = bytes;

  void clear() => state = null;
}

final teamsProfilePhotoProvider =
    NotifierProvider<TeamsProfilePhotoNotifier, Uint8List?>(
      TeamsProfilePhotoNotifier.new,
    );

class TaskNotifier extends AsyncNotifier<List<TaskModel>> {
  final _repository = TaskRepository();

  @override
  Future<List<TaskModel>> build() async {
    final stream = _repository.getTasksStream();
    StreamSubscription<List<TaskModel>>? subscription;

    subscription = stream.listen((tasks) {
      state = AsyncValue.data(tasks);
    });

    ref.onDispose(() async {
      await subscription?.cancel();
    });

    try {
      return await stream.first;
    } catch (_) {
      // 初期表示を止めないため、取得失敗時は空配列で描画する。
      return <TaskModel>[];
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _repository.createTask(task);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _repository.updateTask(task);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    state = await AsyncValue.guard(() async {
      final tasks = state.value ?? [];
      final task = tasks.firstWhere((t) => t.id == id);
      final updatedTask = task.copyWith(status: status);
      await _repository.updateTask(updatedTask);
      return state.value ?? <TaskModel>[];
    });
  }

  Future<void> mergeTeamsAssignments(List<TeamsAssignment> assignments) async {
    final current = state.value ?? <TaskModel>[];

    for (final assignment in assignments) {
      final exists = current.any((task) => task.id == assignment.id);
      if (exists) continue;

      await _repository.createTask(
        TaskModel(
          id: assignment.id,
          title: assignment.title,
          subjectId: null,
          type: TaskType.homework,
          priority: TaskPriority.medium,
          status: TaskStatus.todo,
          startDate: DateTime.now(),
          deadline:
              assignment.dueDate ?? DateTime.now().add(const Duration(days: 7)),
          estimatedHours: 1.0,
        ),
      );
    }
  }
}

final tasksProvider = AsyncNotifierProvider<TaskNotifier, List<TaskModel>>(
  TaskNotifier.new,
);
