import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';

class SyllabusApiClient {
  SyllabusApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          );

  final Dio _dio;

  Future<List<Map<String, dynamic>>> fetchSyllabusSubjects({
    required String kosenId,
    required int grade,
    required String courseId,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/v1/syllabus',
        queryParameters: <String, dynamic>{
          'kosenId': kosenId,
          'grade': grade,
          'courseId': courseId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Syllabus API returned ${response.statusCode}');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected syllabus API response format.');
      }

      final raw = data['subjects'];
      if (raw is! List) {
        throw Exception('Subject list is missing in API response.');
      }

      return raw
          .whereType<Map<String, dynamic>>()
          .map((subject) => Map<String, dynamic>.from(subject))
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception('Network error while loading syllabus: ${e.message}');
    } on TimeoutException {
      throw Exception('Syllabus API timeout.');
    }
  }
}
