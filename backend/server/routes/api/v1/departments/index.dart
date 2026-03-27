import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/services/kosen_rule_service.dart';

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

  final kosenId = context.request.uri.queryParameters['kosenId']?.trim();
  final grade = context.request.uri.queryParameters['grade']?.trim();

  if (kosenId == null || kosenId.isEmpty || grade == null || grade.isEmpty) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode(
        <String, String>{
          'error': 'Missing or invalid query parameters: kosenId, grade',
        },
      ),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  try {
    final ruleService = KosenRuleService();
    final departments = await ruleService.getDepartments(kosenId, grade);

    return Response(
      body: jsonEncode(<String, dynamic>{
        'kosenId': kosenId,
        'grade': int.tryParse(grade),
        'departments': departments,
      }),
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
