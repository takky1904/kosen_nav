import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';

class DepartmentsApiClient {
  DepartmentsApiClient({Dio? dio})
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

  Future<List<String>> fetchDepartments(String kosenName, int grade) async {
    try {
      final triedNames = <String>[];
      final candidates = _kosenNameCandidates(kosenName);

      for (final candidate in candidates) {
        triedNames.add(candidate);

        final response = await _dio.get<dynamic>(
          '/api/v1/departments',
          queryParameters: <String, dynamic>{
            'kosenName': candidate,
            'grade': grade,
          },
        );

        if (response.statusCode != 200) {
          continue;
        }

        final data = response.data;
        if (data is! Map<String, dynamic>) {
          continue;
        }

        final raw = data['departments'];
        if (raw is! List) {
          continue;
        }

        final departments = raw
            .map((item) => item?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();

        if (departments.isNotEmpty) {
          return departments;
        }
      }

      throw Exception(
        'Departments are empty for all school-name candidates: ${triedNames.join(', ')}',
      );
    } on DioException catch (e) {
      throw Exception('Network error while loading departments: ${e.message}');
    } on TimeoutException {
      throw Exception('Department API timeout.');
    }
  }

  List<String> _kosenNameCandidates(String input) {
    final trimmed = input.trim();
    final set = <String>{};

    if (trimmed.isEmpty) {
      return const <String>[];
    }

    set.add(trimmed);
    set.add(trimmed.replaceAll('国立', ''));
    set.add(trimmed.replaceAll('独立行政法人', ''));

    var short = trimmed;
    short = short.replaceAll('工業高等専門学校', '高専');
    short = short.replaceAll('高等専門学校', '高専');
    short = short.replaceAll('工業高専', '高専');
    set.add(short);

    final noSchoolSuffix = trimmed.replaceAll('学校', '');
    set.add(noSchoolSuffix);

    return set
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);
  }
}
