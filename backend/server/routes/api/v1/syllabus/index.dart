import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

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
    return Response(
      // TODO(tatsu): Return static syllabus master-data from JSON.
      body: jsonEncode(const <Map<String, dynamic>>[]),
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
