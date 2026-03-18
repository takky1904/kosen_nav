import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:server/src/database.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  // URLの末尾にあるID（例: /tasks/1）を数値として受け取る
  final taskId = int.tryParse(id);
  if (taskId == null) {
    return Response(statusCode: HttpStatus.badRequest, body: 'Invalid ID');
  }

  switch (context.request.method) {
    case HttpMethod.put: // 更新の処理
      try {
        final payload = await context.request.json() as Map<String, dynamic>;
        print('PUT /tasks/$taskId json(): $payload');
        await DB.instance.updateTask(taskId, payload);
        return Response.json(body: {...payload, 'id': taskId});
      } on FormatException catch (e) {
        return Response(
          statusCode: HttpStatus.badRequest,
          body: 'Invalid JSON: ${e.message}',
        );
      } catch (e) {
        print('PUT /tasks/$taskId error: $e');
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Server Error: $e',
        );
      }

    case HttpMethod.delete: // 削除の処理
      try {
        await DB.instance.deleteTask(taskId);
        return Response(statusCode: HttpStatus.noContent);
      } catch (e) {
        print('DELETE /tasks/$taskId error: $e');
        return Response(
          statusCode: HttpStatus.internalServerError,
          body: 'Server Error: $e',
        );
      }

    default:
      return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}
