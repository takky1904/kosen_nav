import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/user.dart';
import 'local_database.dart';

class UserRepository {
  static const String _table = 'users';
  static const String _currentUserId = 'local_user';
  static const String _prefsKosenName = 'user_kosen_name';
  static const String _prefsGrade = 'user_grade';
  static const String _prefsCourseId = 'user_course_id';

  Future<User> getCurrentUser() async {
    final prefsUser = await _readUserFromPrefs();

    try {
      final db = await LocalDatabase.instance;
      final rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: <Object>[_currentUserId],
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final dbUser = _mapRowToUser(rows.first);
        if (_hasAffiliation(dbUser)) {
          return dbUser;
        }
      }

      if (prefsUser != null && _hasAffiliation(prefsUser)) {
        await _upsertDbUser(prefsUser);
        return prefsUser;
      }

      await db.insert(_table, <String, Object?>{
        'id': _currentUserId,
        'kosen_name': null,
        'grade': null,
        'course_id': null,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return User.empty();
    } catch (_) {
      return prefsUser ?? User.empty();
    }
  }

  Future<User> updateUserAffiliation(
    String kosenId,
    int grade,
    String courseId,
  ) async {
    final user = User(
      id: _currentUserId,
      kosenName: kosenId,
      grade: grade,
      courseId: courseId,
    );

    await _writeUserToPrefs(user);

    try {
      await _upsertDbUser(user);
    } catch (_) {
      // SharedPreferences fallback is already persisted.
    }

    return user;
  }

  Future<void> _upsertDbUser(User user) async {
    final db = await LocalDatabase.instance;
    await db.insert(_table, <String, Object?>{
      'id': _currentUserId,
      'kosen_name': user.kosenName,
      'grade': user.grade,
      'course_id': user.courseId,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _writeUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKosenName, user.kosenName ?? '');
    if (user.grade == null) {
      await prefs.remove(_prefsGrade);
    } else {
      await prefs.setInt(_prefsGrade, user.grade!);
    }
    await prefs.setString(_prefsCourseId, user.courseId ?? '');
  }

  Future<User?> _readUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final kosenName = prefs.getString(_prefsKosenName);
    final grade = prefs.getInt(_prefsGrade);
    final courseId = prefs.getString(_prefsCourseId);

    final user = User(
      id: _currentUserId,
      kosenName: (kosenName == null || kosenName.isEmpty) ? null : kosenName,
      grade: grade,
      courseId: (courseId == null || courseId.isEmpty) ? null : courseId,
    );

    if (_hasAffiliation(user)) {
      return user;
    }
    return null;
  }

  bool _hasAffiliation(User user) {
    return (user.kosenName?.isNotEmpty ?? false) &&
        user.grade != null &&
        (user.courseId?.isNotEmpty ?? false);
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
