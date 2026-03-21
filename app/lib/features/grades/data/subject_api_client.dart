import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/subject_model.dart';

class SubjectApiClient {
  final Dio _dio;

  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8080';
    // 【重要】Android実機の場合は、PCのIPアドレスに書き換えが必要
    return 'http://192.168.1.5:8080';
  }

  SubjectApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: _baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  Future<List<SubjectModel>> fetchSubjects() async {
    try {
      final response = await _dio
          .get('/subjects')
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => SubjectModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load subjects: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Network timeout while loading subjects.');
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<SubjectModel> createSubject(SubjectModel subject) async {
    try {
      final response = await _dio.post('/subjects', data: subject.toJson());
      if (response.statusCode == 201 || response.statusCode == 200) {
        return SubjectModel.fromJson(response.data);
      } else {
        throw Exception('Failed to create subject: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during subject creation: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during subject creation: $e');
    }
  }

  Future<SubjectModel> updateSubject(SubjectModel subject) async {
    try {
      final response = await _dio.put(
        '/subjects/${subject.id}',
        data: subject.toJson(),
      );
      if (response.statusCode == 200) {
        return SubjectModel.fromJson(response.data);
      } else {
        throw Exception('Failed to update subject: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during subject update: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during subject update: $e');
    }
  }

  Future<void> deleteSubject(String id) async {
    try {
      final response = await _dio.delete('/subjects/$id');
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete subject: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error during subject deletion: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error during subject deletion: $e');
    }
  }
}
