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
  final Map<String, List<_SyllabusBlock>> _blocksByKosenId =
      <String, List<_SyllabusBlock>>{};
  final Map<String, String> _versionByKosenId = <String, String>{};

  /// Returns subjects matched by profile conditions.
  ///
  /// If no matching master-data block exists, this returns an empty list.
  Future<List<dynamic>> getSubjects(
    String kosenId,
    String grade,
    String courseId,
  ) async {
    // Always reload to avoid serving stale JSON after master-data edits.
    await _loadAllData();

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
    _versionByKosenId.clear();

    final dir = await _resolveSyllabusDataDirectory();
    final entities = await dir.list(recursive: true).toList();
    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'));

    for (final file in files) {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);

      final relativePath = _toRelativePath(file.path, dir.path);
      final normalizedRelativePath = relativePath.replaceAll('\\', '/');
      final segments = normalizedRelativePath.split('/');

      // New layout: syllabus_data/{kosenId}/{grade}/{courseId}.json
      if (segments.length == 3) {
        final kosenId = _normalize(segments[0]);
        final gradeFromPath = segments[1].trim();
        final courseIdFromPath = _basenameWithoutExtension(segments[2]).trim();

        final parsedBlock = _parseCourseFile(
          decoded,
          gradeFromPath,
          courseIdFromPath,
        );
        if (parsedBlock == null || kosenId.isEmpty) {
          continue;
        }

        final blocks = _blocksByKosenId.putIfAbsent(
          kosenId,
          () => <_SyllabusBlock>[],
        );
        blocks.add(parsedBlock.block);

        if (_versionByKosenId[kosenId] == null ||
            _versionByKosenId[kosenId]!.isEmpty) {
          _versionByKosenId[kosenId] = parsedBlock.version;
        }
        continue;
      }

      final parsed = _parseSyllabusFile(decoded);
      if (parsed == null) {
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

      final blocks = _blocksByKosenId.putIfAbsent(kosenId, () => <_SyllabusBlock>[]);
      for (final item in parsed.items) {
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

      _versionByKosenId[kosenId] = parsed.version;
    }
  }

  _ParsedCourseFile? _parseCourseFile(
    dynamic decoded,
    String gradeFromPath,
    String courseIdFromPath,
  ) {
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final version = (decoded['version'] ?? '1.0').toString();
    final grade = (decoded['grade'] ?? gradeFromPath).toString().trim();
    final courseId =
        (decoded['courseId'] ?? courseIdFromPath).toString().trim();
    final subjectsRaw = decoded['subjects'];
    if (grade.isEmpty || courseId.isEmpty || subjectsRaw is! List) {
      return null;
    }

    final subjects = subjectsRaw
        .whereType<Map<String, dynamic>>()
        .map(Map<String, dynamic>.from)
        .toList(growable: false);

    return _ParsedCourseFile(
      version: version,
      block: _SyllabusBlock(
        grade: grade,
        courseId: courseId,
        subjects: subjects,
      ),
    );
  }

  _ParsedSyllabusFile? _parseSyllabusFile(dynamic decoded) {
    // Legacy format: top-level JSON list.
    if (decoded is List) {
      return _ParsedSyllabusFile(version: '1.0', items: decoded);
    }

    // Versioned format: top-level JSON object.
    if (decoded is Map<String, dynamic>) {
      final version = (decoded['version'] ?? '1.0').toString();
      final rawItems = decoded['data'];
      if (rawItems is List) {
        return _ParsedSyllabusFile(version: version, items: rawItems);
      }
    }

    return null;
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

  String _toRelativePath(String filePath, String rootPath) {
    if (filePath.startsWith(rootPath)) {
      final cut = filePath.substring(rootPath.length);
      if (cut.startsWith('\\') || cut.startsWith('/')) {
        return cut.substring(1);
      }
      return cut;
    }
    return filePath;
  }

  String _basenameWithoutExtension(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.json')) {
      return fileName.substring(0, fileName.length - 5);
    }
    return fileName;
  }
}

class _ParsedSyllabusFile {
  const _ParsedSyllabusFile({required this.version, required this.items});

  final String version;
  final List<dynamic> items;
}

class _ParsedCourseFile {
  const _ParsedCourseFile({required this.version, required this.block});

  final String version;
  final _SyllabusBlock block;
}
