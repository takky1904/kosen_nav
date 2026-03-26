import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
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

  final kosenName = context.request.uri.queryParameters['kosenName']?.trim();
  final gradeRaw = context.request.uri.queryParameters['grade']?.trim();
  final grade = int.tryParse(gradeRaw ?? '');

  if (kosenName == null || kosenName.isEmpty || grade == null) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode(
        <String, String>{
          'error': 'Missing or invalid query parameters: kosenName, grade',
        },
      ),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  try {
    final ruleService = KosenRuleService();
    final configuredDepartments = await ruleService.getDisplayNames(
      kosenName: kosenName,
      grade: grade,
    );

    if (configuredDepartments != null && configuredDepartments.isNotEmpty) {
      return Response(
        body: jsonEncode(<String, dynamic>{
          'kosenName': kosenName,
          'grade': grade,
          'departments': configuredDepartments,
          'source': 'rule-config',
        }),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }

    final scraper = SyllabusScraper();
    final departments = await scraper.fetchDepartments(kosenName: kosenName);

    return Response(
      body: jsonEncode(<String, dynamic>{
        'kosenName': kosenName,
        'grade': grade,
        'departments': departments,
        'source': 'syllabus-fallback',
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } on SyllabusSourceUnavailableException catch (e, st) {
    print('Department API source unavailable: $e');
    print(st);
    return Response(
      statusCode: HttpStatus.badGateway,
      body: jsonEncode(<String, String>{'error': e.toString()}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e, st) {
    print('Department API error: $e');
    print(st);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(<String, String>{'error': 'Server Error: $e'}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
