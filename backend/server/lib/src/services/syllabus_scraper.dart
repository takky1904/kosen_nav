import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class SyllabusSourceUnavailableException implements Exception {
  SyllabusSourceUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _SubjectSeed {
  _SubjectSeed({
    required this.subjectName,
    required this.detailUrl,
    required this.credits,
    required this.teacher,
    required this.term,
  });

  final String subjectName;
  final Uri detailUrl;
  final int credits;
  final String teacher;
  final String term;
}

class SyllabusScraper {
  SyllabusScraper({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  static final Uri _defaultTopUri = Uri.parse(
    'https://syllabus.kosen-k.go.jp/Pages/PublicSchools?lang=ja',
  );

  Future<List<Map<String, dynamic>>> fetchSyllabus({
    required String kosenName,
    required int grade,
    required String courseId,
    List<String>? scrapeTargets,
  }) async {
    final useMock =
        (Platform.environment['SYLLABUS_USE_MOCK'] ?? '').toLowerCase() ==
            'true';

    if (useMock) {
      return _buildMockData(
        kosenName: kosenName,
        grade: grade,
        courseId: courseId,
      );
    }

    final topUrl = Platform.environment['SYLLABUS_TOP_URL'];
    final topUri = (topUrl == null || topUrl.trim().isEmpty)
        ? _defaultTopUri
        : Uri.parse(topUrl.trim());

    try {
      final schoolUri = await _resolveSchoolUri(topUri, kosenName);
      final subjectSeeds = await _collectSubjectSeeds(
        schoolUri: schoolUri,
        courseId: courseId,
        grade: grade,
        scrapeTargets: scrapeTargets,
      );

      if (subjectSeeds.isEmpty) {
        throw SyllabusSourceUnavailableException(
          'No subjects found for grade=$grade at course=$courseId',
        );
      }

      final result = <Map<String, dynamic>>[];
      for (var i = 0; i < subjectSeeds.length; i++) {
        if (i > 0) {
          // Rate limiting: 科目詳細アクセス間は1秒以上空ける。
          await Future<void>.delayed(const Duration(seconds: 1));
        }

        final seed = subjectSeeds[i];
        try {
          final evaluations = await _extractEvaluations(seed.detailUrl);
          result.add(<String, dynamic>{
            'subjectName': seed.subjectName,
            'credits': seed.credits,
            'teacher': seed.teacher,
            'term': seed.term,
            'evaluations': evaluations,
          });
        } catch (_) {
          // 一部科目の解析失敗は全体停止せず、デフォルト値で継続する。
          result.add(<String, dynamic>{
            'subjectName': seed.subjectName,
            'credits': seed.credits,
            'teacher': seed.teacher,
            'term': seed.term,
            'evaluations': <String, int>{
              'exam': 0,
              'assignment': 0,
              'other': 100,
            },
          });
        }
      }

      return result;
    } catch (e) {
      throw SyllabusSourceUnavailableException(
        'Failed to crawl syllabus: $e',
      );
    }
  }

  Future<List<_SubjectSeed>> _collectSubjectSeeds({
    required Uri schoolUri,
    required String courseId,
    required int grade,
    List<String>? scrapeTargets,
  }) async {
    final targets = (scrapeTargets ?? const <String>[])
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    if (targets.isEmpty) {
      final courseListUri = await _resolveCourseListUri(schoolUri, courseId);
      return _collectSubjectsByGrade(courseListUri, grade);
    }

    final uris = await _resolveCourseListUrisByTargets(schoolUri, targets);
    final byKey = <String, _SubjectSeed>{};

    for (final uri in uris) {
      final seeds = await _collectSubjectsByGrade(uri, grade);
      for (final seed in seeds) {
        final key = '${seed.detailUrl}|${_norm(seed.subjectName)}';
        byKey.putIfAbsent(key, () => seed);
      }
    }

    return byKey.values.toList(growable: false);
  }

  Future<List<String>> fetchDepartments({required String kosenName}) async {
    final topUrl = Platform.environment['SYLLABUS_TOP_URL'];
    final topUri = (topUrl == null || topUrl.trim().isEmpty)
        ? _defaultTopUri
        : Uri.parse(topUrl.trim());

    try {
      final schoolUri = await _resolveSchoolUri(topUri, kosenName);
      return await _extractDepartmentNames(schoolUri);
    } catch (e) {
      throw SyllabusSourceUnavailableException(
        'Failed to fetch departments: $e',
      );
    }
  }

  Future<List<String>> fetchSchools() async {
    final topUrl = Platform.environment['SYLLABUS_TOP_URL'];
    final topUri = (topUrl == null || topUrl.trim().isEmpty)
        ? _defaultTopUri
        : Uri.parse(topUrl.trim());

    try {
      final document = await _fetchDocument(topUri);
      final anchors = document.querySelectorAll('a[href]');

      final schools = <String>[];
      final seen = <String>{};

      for (final anchor in anchors) {
        final href = anchor.attributes['href'] ?? '';
        if (!href.contains('/Pages/PublicDepartments')) {
          continue;
        }

        final name = anchor.text.trim();
        if (name.isEmpty) {
          continue;
        }

        final key = _norm(name);
        if (seen.add(key)) {
          schools.add(name);
        }
      }

      if (schools.isEmpty) {
        throw SyllabusSourceUnavailableException(
            'No schools found at top page.');
      }

      return schools;
    } catch (e) {
      throw SyllabusSourceUnavailableException(
        'Failed to fetch schools: $e',
      );
    }
  }

  Future<Uri> _resolveSchoolUri(Uri topUri, String kosenName) async {
    final document = await _fetchDocument(topUri);
    final anchors = document.querySelectorAll('a[href]');
    final wanted = _normalizeSchoolName(kosenName);

    Element? bestMatch;
    for (final a in anchors) {
      final text = a.text.trim();
      final normalizedText = _normalizeSchoolName(text);

      if (normalizedText == wanted) {
        bestMatch = a;
        break;
      }
      if (normalizedText.contains(wanted) || wanted.contains(normalizedText)) {
        bestMatch ??= a;
      }
    }

    if (bestMatch == null) {
      throw SyllabusSourceUnavailableException(
        'School link not found for kosenName=$kosenName',
      );
    }

    final href = bestMatch.attributes['href'];
    if (href == null || href.isEmpty) {
      throw SyllabusSourceUnavailableException(
        'School href is missing for kosenName=$kosenName',
      );
    }

    return topUri.resolve(href);
  }

  Future<Uri> _resolveCourseListUri(Uri schoolUri, String courseId) async {
    final document = await _fetchDocument(schoolUri);
    final wantedCourse = _normalizeCourseName(courseId);

    final departmentBlocks = document.querySelectorAll('.row');
    for (final block in departmentBlocks) {
      final heading = block.querySelector('h4, h3, .list-group-item-heading');
      final headingText = _normalizeCourseName(heading?.text ?? '');
      if (headingText.isEmpty || !_courseMatches(headingText, wantedCourse)) {
        continue;
      }

      final links = block.querySelectorAll('a[href]');
      for (final link in links) {
        final label = link.text.trim();
        if (!label.contains('本年度の開講科目一覧')) {
          continue;
        }
        final href = link.attributes['href'];
        if (href != null && href.isNotEmpty) {
          return schoolUri.resolve(href);
        }
      }
    }

    final anchors = document.querySelectorAll('a[href]');
    for (final a in anchors) {
      final text = a.text.trim();
      if (!text.contains(courseId)) continue;

      var container = a.parent;
      while (container != null) {
        final links = container.querySelectorAll('a[href]');
        for (final link in links) {
          final label = link.text.trim();
          if (label.contains('本年度の開講科目一覧')) {
            final href = link.attributes['href'];
            if (href != null && href.isNotEmpty) {
              return schoolUri.resolve(href);
            }
          }
        }
        container = container.parent;
      }
    }

    for (final link in anchors) {
      final label = link.text.trim();
      if (label.contains(courseId) && label.contains('開講科目一覧')) {
        final href = link.attributes['href'];
        if (href != null && href.isNotEmpty) {
          return schoolUri.resolve(href);
        }
      }
      if (label.contains('本年度の開講科目一覧') && label.contains(courseId)) {
        final href = link.attributes['href'];
        if (href != null && href.isNotEmpty) {
          return schoolUri.resolve(href);
        }
      }
    }

    throw SyllabusSourceUnavailableException(
      'Course subject list link not found for courseId=$courseId',
    );
  }

  Future<List<Uri>> _resolveCourseListUrisByTargets(
    Uri schoolUri,
    List<String> scrapeTargets,
  ) async {
    final document = await _fetchDocument(schoolUri);
    final rows = document.querySelectorAll('.row');

    final normalizedTargets = scrapeTargets
        .map(_normalizeCourseName)
        .where((v) => v.isNotEmpty)
        .toList(growable: false);

    final uris = <Uri>[];
    final seen = <String>{};

    for (final row in rows) {
      final heading = row.querySelector('h4, h3, .list-group-item-heading');
      if (heading == null) {
        continue;
      }

      final headingText = _normalizeCourseName(heading.text);
      if (headingText.isEmpty) {
        continue;
      }

      final matched = normalizedTargets.any((target) {
        return _courseMatches(headingText, target) ||
            headingText.contains(target) ||
            target.contains(headingText);
      });

      if (!matched) {
        continue;
      }

      final links = row.querySelectorAll('a[href]');
      for (final link in links) {
        final label = link.text.trim();
        if (!label.contains('本年度の開講科目一覧')) {
          continue;
        }

        final href = link.attributes['href'];
        if (href == null || href.isEmpty) {
          continue;
        }

        final uri = schoolUri.resolve(href);
        final uriText = uri.toString();
        if (seen.add(uriText)) {
          uris.add(uri);
        }
      }
    }

    if (uris.isEmpty) {
      throw SyllabusSourceUnavailableException(
        'Course subject links not found for targets=${scrapeTargets.join(',')}',
      );
    }

    return uris;
  }

  Future<List<String>> _extractDepartmentNames(Uri schoolUri) async {
    final document = await _fetchDocument(schoolUri);
    final rows = document.querySelectorAll('.row');

    final names = <String>[];
    final seen = <String>{};

    for (final row in rows) {
      final heading = row.querySelector('h4, h3, .list-group-item-heading');
      if (heading == null) continue;

      final raw = heading.text.trim();
      if (raw.isEmpty) continue;
      if (raw == '学科一覧') continue;

      final key = _norm(raw);
      if (seen.contains(key)) continue;

      final hasSubjectsLink = row
          .querySelectorAll('a[href]')
          .any((a) => a.text.trim().contains('本年度の開講科目一覧'));
      if (!hasSubjectsLink) continue;

      seen.add(key);
      names.add(raw);
    }

    if (names.isEmpty) {
      throw SyllabusSourceUnavailableException(
        'No departments found for school page: $schoolUri',
      );
    }

    return names;
  }

  Future<List<_SubjectSeed>> _collectSubjectsByGrade(
    Uri subjectListUri,
    int grade,
  ) async {
    final document = await _fetchDocument(subjectListUri);
    final tables = document.querySelectorAll('table');
    if (tables.isEmpty) {
      throw SyllabusSourceUnavailableException('Subject list table not found.');
    }

    final seeds = <_SubjectSeed>[];

    for (final table in tables) {
      final headerCells = table.querySelectorAll('thead th, tr th');
      if (headerCells.isEmpty) continue;

      final headers = headerCells.map((cell) => _norm(cell.text)).toList();
      final gradeIndex = _findGradeColumnIndex(headers, grade);
      if (gradeIndex == -1) {
        continue;
      }

      final subjectIndex = _findColumnIndex(headers, <String>['授業科目名', '科目名']);
      final creditIndex = _findColumnIndex(headers, <String>['単位']);
      final teacherIndex = _findColumnIndex(headers, <String>['担当教員', '教員']);
      final termIndex =
          _findColumnIndex(headers, <String>['開講期', '学期', 'term']);

      final rows = table.querySelectorAll('tbody tr');
      for (final row in rows) {
        try {
          final cells = row.querySelectorAll('td');
          if (cells.isEmpty || gradeIndex >= cells.length) continue;

          final gradeValue = _norm(cells[gradeIndex].text);
          if (!_isGradeOffered(gradeValue)) {
            continue;
          }

          final subjectCell = (subjectIndex >= 0 && subjectIndex < cells.length)
              ? cells[subjectIndex]
              : cells.first;
          final subjectName = subjectCell.text.trim();
          if (subjectName.isEmpty) continue;

          final detailAnchor = subjectCell.querySelector('a[href]');
          if (detailAnchor == null) continue;
          final href = detailAnchor.attributes['href'];
          if (href == null || href.isEmpty) continue;

          final creditsText = (creditIndex >= 0 && creditIndex < cells.length)
              ? cells[creditIndex].text
              : '';
          final teacherText = (teacherIndex >= 0 && teacherIndex < cells.length)
              ? cells[teacherIndex].text
              : '';
          final termText = (termIndex >= 0 && termIndex < cells.length)
              ? cells[termIndex].text
              : '';

          final credits = _parseIntOrDefault(creditsText, 0);
          final teacher = teacherText.trim();
          final term = termText.trim().isEmpty ? '不明' : termText.trim();

          seeds.add(
            _SubjectSeed(
              subjectName: subjectName,
              detailUrl: subjectListUri.resolve(href),
              credits: credits,
              teacher: teacher,
              term: term,
            ),
          );
        } catch (_) {
          // 行単位の崩れは読み飛ばして継続する。
          continue;
        }
      }
    }

    return seeds;
  }

  Future<Map<String, int>> _extractEvaluations(Uri detailUri) async {
    final document = await _fetchDocument(detailUri);

    var exam = 0;
    var assignment = 0;
    var other = 0;

    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      final tableText = _norm(table.text);
      if (!tableText.contains('評価') && !tableText.contains('割合')) {
        continue;
      }

      final rows = table.querySelectorAll('tr');
      for (final row in rows) {
        final cells = row.querySelectorAll('th, td');
        if (cells.length < 2) continue;

        final label = _norm(cells.first.text);
        final valueText = cells.sublist(1).map((cell) => cell.text).join(' ');
        final value = _parsePercent(valueText);
        if (value == null) continue;

        if (label.contains('試験')) {
          exam += value;
          continue;
        }

        if (label.contains('発表') ||
            label.contains('ポートフォリオ') ||
            label.contains('課題') ||
            label.contains('レポート') ||
            label.contains('平常') ||
            label.contains('その他')) {
          assignment += value;
          continue;
        }

        other += value;
      }
    }

    if (exam + assignment + other == 0) {
      final text = _norm(document.body?.text ?? '');
      exam = _parseLabelPercent(text, '試験') ?? 0;
      assignment = (_parseLabelPercent(text, '発表') ?? 0) +
          (_parseLabelPercent(text, 'ポートフォリオ') ?? 0) +
          (_parseLabelPercent(text, '課題') ?? 0) +
          (_parseLabelPercent(text, 'レポート') ?? 0) +
          (_parseLabelPercent(text, '平常') ?? 0) +
          (_parseLabelPercent(text, 'その他') ?? 0);
      other = 100 - exam - assignment;
    }

    var normalizedOther = other;
    final sum = exam + assignment + normalizedOther;
    if (sum < 100) {
      normalizedOther += 100 - sum;
    } else if (sum > 100) {
      normalizedOther = normalizedOther - (sum - 100);
      if (normalizedOther < 0) normalizedOther = 0;
    }

    return <String, int>{
      'exam': exam.clamp(0, 100),
      'assignment': assignment.clamp(0, 100),
      'other': normalizedOther.clamp(0, 100),
    };
  }

  Future<Document> _fetchDocument(Uri uri) async {
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'KosenNavScraper/1.0');
    final response = await request.close();
    if (response.statusCode >= 400) {
      throw SyllabusSourceUnavailableException(
        'Failed to fetch $uri (status=${response.statusCode})',
      );
    }

    final body = await response.transform(utf8.decoder).join();
    return html_parser.parse(body);
  }

  int _findGradeColumnIndex(List<String> headers, int grade) {
    final candidates = <String>['$grade年', '$grade 年', '第$grade学年'];
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      for (final c in candidates) {
        if (h.contains(_norm(c))) {
          return i;
        }
      }
    }
    return -1;
  }

  int _findColumnIndex(List<String> headers, List<String> keywords) {
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      for (final keyword in keywords) {
        if (h.contains(_norm(keyword))) {
          return i;
        }
      }
    }
    return -1;
  }

  bool _isGradeOffered(String value) {
    if (value.isEmpty) return false;
    if (value == '-' || value == '－' || value == '0') return false;
    return true;
  }

  int _parseIntOrDefault(String raw, int fallback) {
    final m = RegExp(r'(\d+)').firstMatch(raw);
    if (m == null) return fallback;
    return int.tryParse(m.group(1) ?? '') ?? fallback;
  }

  int? _parsePercent(String raw) {
    final m = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (m == null) return null;
    final value = double.tryParse(m.group(1) ?? '');
    if (value == null) return null;
    return value.round();
  }

  int? _parseLabelPercent(String source, String label) {
    final pattern = RegExp('$label[^\\d]*(\\d+(?:\\.\\d+)?)');
    final m = pattern.firstMatch(source);
    if (m == null) return null;
    return double.tryParse(m.group(1) ?? '')?.round();
  }

  String _norm(String text) {
    return text.replaceAll(RegExp(r'\s+'), '').trim();
  }

  String _normalizeSchoolName(String text) {
    var s = _norm(text);
    s = s.replaceAll('国立', '');
    s = s.replaceAll('独立行政法人', '');
    return s;
  }

  String _normalizeCourseName(String text) {
    var s = _norm(text);
    s = s.replaceAll('学科', '');
    s = s.replaceAll('専攻', '');
    s = s.replaceAll('系', '');
    s = s.replaceAll('コース', '');
    s = s.replaceAll('・', '');
    s = s.replaceAll('/', '');
    return s;
  }

  bool _courseMatches(String heading, String wanted) {
    if (heading == wanted) return true;
    if (heading.contains(wanted) || wanted.contains(heading)) return true;

    final tokens = <String>['情報', '電気', '電子', '機械', '建築', '化学', '物質'];
    final wantedHits = tokens.where(wanted.contains).toSet();
    final headingHits = tokens.where(heading.contains).toSet();
    if (wantedHits.isNotEmpty && headingHits.isNotEmpty) {
      final overlap = wantedHits.intersection(headingHits);
      if (overlap.isNotEmpty) {
        return true;
      }
    }

    return false;
  }

  List<Map<String, dynamic>> _buildMockData({
    required String kosenName,
    required int grade,
    required String courseId,
  }) {
    return <Map<String, dynamic>>[
      {
        'subjectName': '基礎数学A',
        'credits': 2,
        'teacher': '轟 龍一',
        'term': '前期',
        'evaluations': <String, int>{
          'exam': 70,
          'assignment': 30,
          'other': 0,
        },
        'kosenName': kosenName,
        'grade': grade,
        'courseId': courseId,
      },
    ];
  }
}
