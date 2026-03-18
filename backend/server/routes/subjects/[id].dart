import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  switch (context.request.method) {
    case HttpMethod.put:
      try {
        final payload = await context.request.json() as Map<String, dynamic>;
        await DB.instance.updateSubject(id, payload);
        return Response.json(body: {...payload, 'id': id});
      } on FormatException catch (e) {
        return Response(
          statusCode: HttpStatus.badRequest,
          body: 'Invalid JSON: ${e.message}',
        );
      } catch (e) {
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Server Error: $e',
        );
      }

    case HttpMethod.delete:
      try {
        await DB.instance.deleteSubject(id);
        return Response(statusCode: HttpStatus.noContent);
      } catch (e) {
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Server Error: $e',
        );
      }

    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}
