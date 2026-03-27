import 'dart:convert';
import 'dart:io';

class _SyllabusBlock {
  const _SyllabusBlock({
    required this.grade,
    required this.courseId,
    required this.subjects,
  });

  final String grade;
  final String courseId;
  final List<Map<String, dynamic>> subjects;
}

/// Loads static syllabus master data JSON files and resolves subjects by
/// `kosenId`, `grade`, and `courseId`.
class SyllabusDataService {
  static final Map<String, List<_SyllabusBlock>> _blocksByKosenId =
      <String, List<_SyllabusBlock>>{};
  static Future<void>? _initFuture;

  Future<void> _ensureInitialized() {
    return _initFuture ??= _loadAllData();
  }

  /// Returns subjects matched by profile conditions.
  ///
  /// If no matching master-data block exists, this returns an empty list.
  Future<List<dynamic>> getSubjects(
    String kosenId,
    String grade,
    String courseId,
  ) async {
    await _ensureInitialized();

    final normalizedKosenId = _normalize(kosenId);
    final normalizedGrade = grade.trim();
    final normalizedCourseId = _normalize(courseId);

    final blocks = _blocksByKosenId[normalizedKosenId];
    if (blocks == null) {
      return const <dynamic>[];
    }

    for (final block in blocks) {
      if (block.grade == normalizedGrade &&
          _normalize(block.courseId) == normalizedCourseId) {
        return block.subjects;
      }
    }

    return const <dynamic>[];
  }

  Future<void> _loadAllData() async {
    _blocksByKosenId.clear();

    final dir = await _resolveSyllabusDataDirectory();
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'));

    for (final file in files) {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        continue;
      }

      final fileName = file.uri.pathSegments.isEmpty
          ? file.path
          : file.uri.pathSegments.last;
      final kosenId = _normalize(
        fileName.toLowerCase().replaceAll('.json', ''),
      );
      if (kosenId.isEmpty) {
        continue;
      }

      final blocks = <_SyllabusBlock>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final grade = (item['grade'] ?? '').toString().trim();
        final courseId = (item['courseId'] ?? '').toString().trim();

        final subjectsRaw = item['subjects'];
        if (grade.isEmpty || courseId.isEmpty || subjectsRaw is! List) {
          continue;
        }

        final subjects = subjectsRaw
            .whereType<Map<String, dynamic>>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false);

        blocks.add(
          _SyllabusBlock(
            grade: grade,
            courseId: courseId,
            subjects: subjects,
          ),
        );
      }

      _blocksByKosenId[kosenId] = blocks;
    }
  }

  Future<Directory> _resolveSyllabusDataDirectory() async {
    final candidates = <String>[
      '${Directory.current.path}/lib/src/config/syllabus_data',
      '${Directory.current.path}/backend/server/lib/src/config/syllabus_data',
    ];

    for (final path in candidates) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        return dir;
      }
    }

    throw const FileSystemException('syllabus_data directory not found');
  }

  String _normalize(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
  }
}
