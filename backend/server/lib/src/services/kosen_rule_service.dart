import 'dart:convert';
import 'dart:io';

class CourseRule {
  CourseRule({required this.displayName, required this.scrapeTargets});

  final String displayName;
  final List<String> scrapeTargets;
}

class KosenRule {
  KosenRule({
    required this.kosenName,
    required this.aliases,
    required this.grades,
  });

  final String kosenName;
  final List<String> aliases;
  final Map<int, List<CourseRule>> grades;
}

class KosenRuleService {
  static const Map<String, String> _ruleKeyMap = <String, String>{
    '長野工業高等専門学校': 'nagano',
    '長野高専': 'nagano',
  };

  Future<List<String>?> getDisplayNames({
    required String kosenName,
    required int grade,
  }) async {
    final rule = await loadRuleByKosenName(kosenName);
    if (rule == null) {
      return null;
    }

    final rules = rule.grades[grade];
    if (rules == null || rules.isEmpty) {
      return null;
    }

    return rules.map((r) => r.displayName).toList(growable: false);
  }

  Future<List<String>?> getScrapeTargets({
    required String kosenName,
    required int grade,
    required String displayName,
  }) async {
    final rule = await loadRuleByKosenName(kosenName);
    if (rule == null) {
      return null;
    }

    final rules = rule.grades[grade];
    if (rules == null || rules.isEmpty) {
      return null;
    }

    final normalizedDisplay = _normalize(displayName);
    CourseRule? matched;

    for (final item in rules) {
      final normalizedRuleName = _normalize(item.displayName);
      if (normalizedRuleName == normalizedDisplay ||
          normalizedRuleName.contains(normalizedDisplay) ||
          normalizedDisplay.contains(normalizedRuleName)) {
        matched = item;
        break;
      }
    }

    if (matched == null) {
      return null;
    }

    final targets = matched.scrapeTargets
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    if (targets.isEmpty) {
      return null;
    }

    return targets;
  }

  Future<KosenRule?> loadRuleByKosenName(String kosenName) async {
    final ruleKey = _resolveRuleKey(kosenName);
    if (ruleKey == null) {
      return null;
    }

    final file = _locateRuleFile(ruleKey);
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return _parseRule(decoded);
  }

  String? _resolveRuleKey(String kosenName) {
    final trimmed = kosenName.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = _ruleKeyMap[trimmed];
    if (direct != null) {
      return direct;
    }

    final normalized = _normalize(trimmed);
    for (final entry in _ruleKeyMap.entries) {
      final keyNormalized = _normalize(entry.key);
      if (keyNormalized == normalized ||
          keyNormalized.contains(normalized) ||
          normalized.contains(keyNormalized)) {
        return entry.value;
      }
    }

    return null;
  }

  File _locateRuleFile(String ruleKey) {
    final candidates = <String>[
      '${Directory.current.path}/lib/src/config/kosen_rules/$ruleKey.json',
      '${Directory.current.path}/backend/server/lib/src/config/kosen_rules/$ruleKey.json',
    ];

    for (final path in candidates) {
      final normalizedPath = path.trim();
      final file = File(normalizedPath);
      if (file.existsSync()) {
        return file;
      }
    }

    return File(candidates.first.trim());
  }

  KosenRule _parseRule(Map<String, dynamic> json) {
    final kosenName = (json['kosenName'] ?? '').toString();

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

          final displayName = (item['displayName'] ?? '').toString().trim();
          if (displayName.isEmpty) {
            continue;
          }

          final targetsRaw = item['scrapeTargets'];
          final targets = targetsRaw is List
              ? targetsRaw
                  .map((v) => v.toString().trim())
                  .where((v) => v.isNotEmpty)
                  .toList(growable: false)
              : const <String>[];

          rules.add(
            CourseRule(displayName: displayName, scrapeTargets: targets),
          );
        }

        if (rules.isNotEmpty) {
          grades[grade] = rules;
        }
      }
    }

    return KosenRule(kosenName: kosenName, aliases: aliases, grades: grades);
  }

  String _normalize(String value) {
    return value.replaceAll(RegExp(r'\s+'), '').trim();
  }
}
