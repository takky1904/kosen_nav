import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/task.dart';

class TaskApiClient {
  final Dio _dio;

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';

    // 【重要】Android実機の場合は、PCのIPアドレスを直接書く！
    // 10.0.2.2 はエミュレーター用なので、実機では繋がりません。
    return 'http://192.168.1.5:8080'; // 手順1で調べたIPに書き換え
  }

  TaskApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 3),
            ),
          );

  /// サーバーの /tasks からタスク一覧を取得する
  Future<List<TaskModel>> fetchTasks() async {
    try {
      final response = await _dio.get('/tasks');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Androidシミュレーターから localhost に繋ぐ場合の注意点:
      // http://localhost:8080 ではなく http://10.0.2.2:8080 を使用してください。
      // 実機の場合は、PCのIPアドレス（例: http://192.168.x.x:8080）を指定する必要があります。
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// サーバーに新しいタスクを保存する
  Future<TaskModel> createTask(TaskModel task) async {
    try {
      final response = await _dio.post(
        '/tasks',
        data: task.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return TaskModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during task creation: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during task creation: $e');
    }
  }

  /// サーバー上のタスクを更新する
  Future<TaskModel> updateTask(TaskModel task) async {
    try {
      final response = await _dio.put(
        '/tasks/${task.id}',
        data: task.toJson(),
      );

      if (response.statusCode == 200) {
        return TaskModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during task update: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during task update: $e');
    }
  }

  /// サーバーからタスクを削除する
  Future<void> deleteTask(String id) async {
    try {
      final response = await _dio.delete('/tasks/$id');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during task deletion: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during task deletion: $e');
    }
  }
}
