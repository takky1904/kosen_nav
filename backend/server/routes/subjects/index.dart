import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    try {
      final subjects = await DB.instance.getSubjects();
      return Response(
        body: jsonEncode(subjects),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e) {
      return Response(
        statusCode: 500,
        body: jsonEncode({'error': 'Server Error: $e'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  }

  if (method == HttpMethod.post) {
    try {
      final bodyString = await context.request.body();
      final data = jsonDecode(bodyString) as Map<String, dynamic>;
      await DB.instance.insertSubject(data);
      return Response(
        statusCode: 201,
        body: jsonEncode(data),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } on FormatException catch (e) {
      return Response(
        statusCode: 400,
        body: jsonEncode({'error': 'Invalid JSON: ${e.message}'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    } catch (e) {
      return Response(
        statusCode: 500,
        body: jsonEncode({'error': 'Server Error: $e'}),
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
  }

  return Response(
    statusCode: 405,
    body: jsonEncode({'error': 'Method Not Allowed'}),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'allow': 'GET, POST',
    },
  );
}
