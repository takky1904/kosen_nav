import 'package:sqflite/sqflite.dart';

import '../../domain/models/user.dart';
import 'local_database.dart';

class UserRepository {
  static const String _table = 'users';
  static const String _currentUserId = 'local_user';

  Future<User> getCurrentUser() async {
    final db = await LocalDatabase.instance;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: <Object>[_currentUserId],
      limit: 1,
    );

    if (rows.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(_table, <String, Object?>{
        'id': _currentUserId,
        'kosen_name': null,
        'grade': null,
        'course_id': null,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return User.empty();
    }

    return _mapRowToUser(rows.first);
  }

  Future<User> updateUserAffiliation(
    String kosenName,
    int grade,
    String courseId,
  ) async {
    final db = await LocalDatabase.instance;

    await db.insert(_table, <String, Object?>{
      'id': _currentUserId,
      'kosen_name': kosenName,
      'grade': grade,
      'course_id': courseId,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    return User(
      id: _currentUserId,
      kosenName: kosenName,
      grade: grade,
      courseId: courseId,
    );
  }

  User _mapRowToUser(Map<String, Object?> row) {
    return User(
      id: row['id']?.toString() ?? _currentUserId,
      kosenName: row['kosen_name']?.toString(),
      grade: row['grade'] == null ? null : (row['grade'] as num?)?.toInt(),
      courseId: row['course_id']?.toString(),
    );
  }
}
