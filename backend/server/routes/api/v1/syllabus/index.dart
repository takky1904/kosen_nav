import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/services/syllabus_data_service.dart';

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
  final courseId = context.request.uri.queryParameters['courseId']?.trim();

  if (kosenId == null ||
      kosenId.isEmpty ||
      grade == null ||
      grade.isEmpty ||
      courseId == null ||
      courseId.isEmpty) {
    return Response(
      statusCode: HttpStatus.badRequest,
      body: jsonEncode(
        <String, String>{
          'error':
              'Missing or invalid query parameters: kosenId, grade, courseId',
        },
      ),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  try {
    final service = SyllabusDataService();
    final subjects = await service.getSubjects(kosenId, grade, courseId);

    return Response(
      body: jsonEncode(<String, dynamic>{
        'kosenId': kosenId,
        'grade': grade,
        'courseId': courseId,
        'subjects': subjects,
      }),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e, st) {
    stderr
      ..writeln('Syllabus API error: $e')
      ..writeln(st);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(<String, String>{'error': 'Server Error: $e'}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
