import 'dart:convert';
import 'dart:io';

class CourseRule {
  CourseRule({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

class CourseDataRule {
  CourseDataRule({
    required this.kosenId,
    required this.kosenName,
    required this.aliases,
    required this.grades,
    required this.version,
  });

  final String kosenId;
  final String kosenName;
  final List<String> aliases;
  final Map<int, List<CourseRule>> grades;
  final String version;
}

class CourseDataService {
  static final Map<String, CourseDataRule> _rulesById =
      <String, CourseDataRule>{};
  static final Map<String, String> _versionsByKosenId = <String, String>{};
  static final Map<String, String> _nameOrAliasToId = <String, String>{};
  static Future<void>? _initFuture;

  Future<void> _ensureInitialized() async {
    await (_initFuture ??= _loadAllRules());
    await _reloadIfVersionChanged();
  }

  Future<List<Map<String, dynamic>>> getAvailableSchools() async {
    await _ensureInitialized();

    final schools = _rulesById.values
        .map(
          (rule) => <String, dynamic>{
            'kosenId': rule.kosenId,
            'kosenName': rule.kosenName,
          },
        )
        .toList(growable: false);

    schools.sort(
      (a, b) => (a['kosenName'] as String).compareTo(b['kosenName'] as String),
    );

    return schools;
  }

  Future<List<Map<String, dynamic>>> getDepartments(
    String kosenId,
    String grade,
  ) async {
    await _ensureInitialized();

    final normalizedKosenId = _resolveKosenId(kosenId);
    if (normalizedKosenId == null) {
      return const <Map<String, dynamic>>[];
    }

    final parsedGrade = int.tryParse(grade.trim());
    if (parsedGrade == null) {
      return const <Map<String, dynamic>>[];
    }

    final rule = _rulesById[normalizedKosenId];
    if (rule == null) {
      return const <Map<String, dynamic>>[];
    }

    final departments = rule.grades[parsedGrade] ?? const <CourseRule>[];
    return departments
        .map(
          (item) => <String, dynamic>{
            'id': item.id,
            'displayName': item.displayName,
          },
        )
        .toList(growable: false);
  }

  Future<void> _loadAllRules() async {
    _rulesById.clear();
    _versionsByKosenId.clear();
    _nameOrAliasToId.clear();

    final dir = await _resolveRulesDirectory();
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'));

    for (final file in files) {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      final rule = _parseRule(decoded);
      if (rule.kosenId.isEmpty || rule.kosenName.isEmpty) {
        continue;
      }

      _rulesById[rule.kosenId] = rule;
      _versionsByKosenId[rule.kosenId] = rule.version;
      _nameOrAliasToId[_normalize(rule.kosenId)] = rule.kosenId;
      _nameOrAliasToId[_normalize(rule.kosenName)] = rule.kosenId;
      for (final alias in rule.aliases) {
        final normalized = _normalize(alias);
        if (normalized.isNotEmpty) {
          _nameOrAliasToId[normalized] = rule.kosenId;
        }
      }
    }
  }

  Future<void> _reloadIfVersionChanged() async {
    final currentVersions = await _readCurrentVersions();
    if (_isVersionMapSame(_versionsByKosenId, currentVersions)) {
      return;
    }
    _initFuture = _loadAllRules();
    await _initFuture;
  }

  Future<Map<String, String>> _readCurrentVersions() async {
    final versions = <String, String>{};
    final dir = await _resolveRulesDirectory();
    final entities = await dir.list().toList();
    final files = entities
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.json'));

    for (final file in files) {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        continue;
      }

      final kosenId = (decoded['kosenId'] ?? '').toString().trim();
      if (kosenId.isEmpty) {
        continue;
      }

      versions[kosenId] = (decoded['version'] ?? '1.0').toString();
    }

    return versions;
  }

  bool _isVersionMapSame(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  Future<Directory> _resolveRulesDirectory() async {
    final candidates = <String>[
      '${Directory.current.path}/lib/src/config/course_data',
      '${Directory.current.path}/backend/server/lib/src/config/course_data',
    ];

    for (final path in candidates) {
      final dir = Directory(path);
      if (await dir.exists()) {
        return dir;
      }
    }

    throw const FileSystemException('course_data directory not found');
  }

  String? _resolveKosenId(String raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) {
      return null;
    }
    return _nameOrAliasToId[normalized] ?? _rulesById[raw.trim()]?.kosenId;
  }

  CourseDataRule _parseRule(Map<String, dynamic> json) {
    final kosenId = (json['kosenId'] ?? '').toString();
    final kosenName = (json['kosenName'] ?? '').toString();
    final version = (json['version'] ?? '1.0').toString();

    final aliasesRaw = json['aliases'];
    final aliases = aliasesRaw is List
        ? aliasesRaw.map((v) => v.toString()).toList(growable: false)
        : const <String>[];

    final gradesRaw = json['grades'];
    final grades = <int, List<CourseRule>>{};

    if (gradesRaw is Map<String, dynamic>) {
      for (final entry in gradesRaw.entries) {
        final grade = int.tryParse(entry.key);
        if (grade == null) {
          continue;
        }

        final rulesRaw = entry.value;
        if (rulesRaw is! List) {
          continue;
        }

        final rules = <CourseRule>[];
        for (final item in rulesRaw) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final id = (item['id'] ?? '').toString().trim();
          final displayName = (item['displayName'] ?? '').toString().trim();
          if (displayName.isEmpty) {
            continue;
          }

          rules.add(
            CourseRule(
              id: id.isEmpty ? _normalize(displayName) : id,
              displayName: displayName,
            ),
          );
        }

        if (rules.isNotEmpty) {
          grades[grade] = rules;
        }
      }
    }

    return CourseDataRule(
      kosenId: kosenId,
      kosenName: kosenName,
      aliases: aliases,
      grades: grades,
      version: version,
    );
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
  }
}
