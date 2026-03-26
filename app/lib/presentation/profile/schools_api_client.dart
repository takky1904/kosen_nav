import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';

class SchoolsApiClient {
  SchoolsApiClient({Dio? dio})
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

  Future<List<String>> fetchSchools() async {
    try {
      final response = await _dio.get<dynamic>('/api/v1/schools');

      if (response.statusCode != 200) {
        throw Exception('School API returned ${response.statusCode}');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected school API response format.');
      }

      final raw = data['schools'];
      if (raw is! List) {
        throw Exception('School list is missing in API response.');
      }

      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false);
    } on DioException catch (e) {
      throw Exception('Network error while loading schools: ${e.message}');
    } on TimeoutException {
      throw Exception('School API timeout.');
    }
  }
}
