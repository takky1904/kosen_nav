import '../domain/task.dart';
import 'api_client.dart';

/// シンプルなタスク管理リポジトリ
class TaskRepository {
  final TaskApiClient _api = TaskApiClient();

  /// サーバーからタスク一覧を取得
  Future<List<TaskModel>> fetchTasks() => _api.fetchTasks();

  /// タスクを作成
  Future<TaskModel> createTask(TaskModel task) => _api.createTask(task);

  /// タスクを更新
  Future<TaskModel> updateTask(TaskModel task) => _api.updateTask(task);

  /// タスクを削除
  Future<void> deleteTask(String id) => _api.deleteTask(id);
}
