import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/services/course_data_service.dart';

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

  try {
    final service = CourseDataService();
    final schools = await service.getAvailableSchools();

    return Response(
      body: jsonEncode(<String, dynamic>{'schools': schools}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  } catch (e, st) {
    print('Schools API error: $e');
    print(st);
    return Response(
      statusCode: HttpStatus.internalServerError,
      body: jsonEncode(<String, String>{'error': 'Server Error: $e'}),
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
