import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task.dart';
import '../domain/teams_assignment.dart';
import '../data/api_client.dart';

class TaskNotifier extends AsyncNotifier<List<TaskModel>> {
  final _apiClient = TaskApiClient();

  @override
  Future<List<TaskModel>> build() async {
    try {
      return await _apiClient.fetchTasks();
    } catch (_) {
      // 初期表示を止めないため、取得失敗時は空配列で描画する。
      return <TaskModel>[];
    }
  }

  Future<void> addTask(TaskModel task) async {
    state = await AsyncValue.guard(() async {
      await _apiClient.createTask(task);
      ref.invalidateSelf();
      return future;
    });
  }

  Future<void> updateTask(TaskModel task) async {
    state = await AsyncValue.guard(() async {
      await _apiClient.updateTask(task);
      ref.invalidateSelf();
      return future;
    });
  }

  Future<void> deleteTask(String id) async {
    state = await AsyncValue.guard(() async {
      await _apiClient.deleteTask(id);
      ref.invalidateSelf();
      return future;
    });
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    state = await AsyncValue.guard(() async {
      final tasks = state.value ?? [];
      final task = tasks.firstWhere((t) => t.id == id);
      final updatedTask = task.copyWith(status: status);
      await _apiClient.updateTask(updatedTask);
      ref.invalidateSelf();
      return future;
    });
  }

  Future<void> mergeTeamsAssignments(List<TeamsAssignment> assignments) async {
    final current = state.value ?? <TaskModel>[];
    final merged = List<TaskModel>.from(current);

    for (final assignment in assignments) {
      final exists = merged.any((task) => task.id == assignment.id);
      if (exists) continue;

      merged.add(
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

    state = AsyncValue.data(merged);
  }
}

final tasksProvider = AsyncNotifierProvider<TaskNotifier, List<TaskModel>>(
  TaskNotifier.new,
);
