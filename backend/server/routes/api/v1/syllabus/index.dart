import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/database.dart';
import 'package:server/src/services/kosen_rule_service.dart';
import 'package:server/src/services/syllabus_scraper.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
      body: jsonEncode(<String, String>{'error': 'Method Not Allowed'}),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        'allow': 'GET',
      },
    );
  }

  final query = context.request.uri.queryParameters;
  final kosenName = query['kosenName']?.trim();
  final gradeRaw = query['grade']?.trim();
  final courseId = query['courseId']?.trim();
  final forceRefresh = (query['refresh'] ?? '').toLowerCase() == 'true';
  final grade = int.tryParse(gradeRaw ?? '');

  if (kosenName == null ||
      kosenName.isEmpty ||
      grade == null ||
      courseId == null ||
      courseId.isEmpty) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode(
        <String, String>{
          'error':
              'Missing or invalid query parameters. Required: kosenName, grade, courseId.',
        },
      ),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  try {
    if (!forceRefresh) {
      List<Map<String, dynamic>>? cached;
      try {
        cached = await DB.instance.getCachedSyllabus(
          kosenName: kosenName,
          grade: grade,
          courseId: courseId,
        );
      } catch (e, st) {
        print('Syllabus cache read failed: $e');
        print(st);
      }

      // 旧モック由来キャッシュ（余分なキーを含む）を返さない。
      final isLegacyMockPayload = cached != null &&
          cached.isNotEmpty &&
          (cached.first.containsKey('kosenName') ||
              cached.first.containsKey('courseId') ||
              cached.first.containsKey('grade'));

      if (cached != null && !isLegacyMockPayload) {
        return Response(
          body: jsonEncode(cached),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    }

    final ruleService = KosenRuleService();
    final scrapeTargets = await ruleService.getScrapeTargets(
      kosenName: kosenName,
      grade: grade,
      displayName: courseId,
    );

    final scraper = SyllabusScraper();
    final data = await scraper.fetchSyllabus(
      kosenName: kosenName,
      grade: grade,
      courseId: courseId,
      scrapeTargets: scrapeTargets,
    );

    try {
      await DB.instance.upsertSyllabusCache(
        kosenName: kosenName,
        grade: grade,
        courseId: courseId,
        payload: data,
      );
    } catch (e, st) {
      print('Syllabus cache write failed: $e');
      print(st);
    }

    return Response(
      body: jsonEncode(data),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } on SyllabusSourceUnavailableException catch (e, st) {
    print('Syllabus source unavailable: $e');
    print(st);
    return Response(
      statusCode: HttpStatus.badGateway,
      body: jsonEncode(<String, String>{'error': e.toString()}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e, st) {
    print('Syllabus API error: $e');
    print(st);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(<String, String>{'error': 'Server Error: $e'}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
