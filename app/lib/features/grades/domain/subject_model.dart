import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'evaluation.dart';

enum GradeRank { a, b, c, d }

extension GradeRankExt on GradeRank {
  String get label => name.toUpperCase();

  String get description {
    switch (this) {
      case GradeRank.a:
        return '優 (80〜100)';
      case GradeRank.b:
        return '良 (70〜79)';
      case GradeRank.c:
        return '可 (60〜69)';
      case GradeRank.d:
        return '不可 (0〜59)';
    }
  }
}

class SubjectModel {
  final String id;
  final String name;
  final int units; // 単位数
  int get credits => units;
  final PeriodicTests periodicTests;
  final List<Evaluation> variableComponents;
  final String? teacher; // 担任教員名（任意）

  List<Evaluation> get evaluations {
    final examScore = () {
      final valid = periodicTests.scores.whereType<double>().toList(
        growable: false,
      );
      if (valid.isEmpty) return null;
      return valid.reduce((a, b) => a + b) / valid.length;
    }();

    return <Evaluation>[
      Evaluation(
        id: 'exam',
        name: '定期試験',
        ratio: periodicTests.ratio,
        userScore: examScore,
      ),
      ...variableComponents,
    ];
  }

  List<double?> get testScores => periodicTests.scores;

  double? get regularScore {
    for (final component in variableComponents) {
      if (component.id == 'normal' || component.name.contains('平常')) {
        return component.userScore;
      }
    }
    return null;
  }

  int get examRatio => periodicTests.ratio;
  double get testWeight => periodicTests.ratio / 100.0;
  double get regularWeight => 1.0 - testWeight;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.units,
    required this.periodicTests,
    required this.variableComponents,
    this.teacher,
  });

  factory SubjectModel.create({
    required String name,
    required int units,
    String? teacher,
  }) {
    return SubjectModel(
      id: const Uuid().v4(),
      name: name,
      units: units,
      periodicTests: const PeriodicTests(
        ratio: 70,
        count: 4,
        scores: <double?>[],
      ).normalized(),
      variableComponents: const <Evaluation>[
        Evaluation(id: 'normal', name: '平常点', ratio: 30),
      ],
      teacher: teacher,
    );
  }

  SubjectModel copyWith({
    String? name,
    int? units,
    PeriodicTests? periodicTests,
    List<Evaluation>? variableComponents,
    String? teacher,
  }) {
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      units: units ?? this.units,
      periodicTests: (periodicTests ?? this.periodicTests).normalized(),
      variableComponents: variableComponents ?? this.variableComponents,
      teacher: teacher ?? this.teacher,
    );
  }

  SubjectModel withPeriodicTestScore(int index, double? score) {
    final updated = List<double?>.from(periodicTests.normalized().scores);
    if (index < 0 || index >= updated.length) {
      return this;
    }
    updated[index] = score;
    return copyWith(periodicTests: periodicTests.copyWith(scores: updated));
  }

  SubjectModel withVariableComponentScore(String componentId, double? score) {
    final normalizedId = componentId.trim();
    final updated = variableComponents
        .map(
          (component) => component.id == normalizedId
              ? component.copyWith(userScore: score)
              : component,
        )
        .toList(growable: false);
    return copyWith(variableComponents: updated);
  }

  SubjectModel addVariableComponent({
    required String name,
    required int ratio,
  }) {
    final component = Evaluation(
      id: const Uuid().v4(),
      name: name,
      ratio: ratio.clamp(0, 100),
    );
    final updated = List<Evaluation>.from(variableComponents)..add(component);
    return copyWith(variableComponents: updated);
  }

  SubjectModel removeVariableComponent(String componentId) {
    final updated = variableComponents
        .where((component) => component.id != componentId)
        .toList(growable: false);
    return copyWith(variableComponents: updated);
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final rawEvaluations = json['evaluations'] ?? json['evaluations_json'];
    final periodic = _parsePeriodicTests(
      rawPeriodic: json['periodic_tests'] ?? json['periodic_tests_json'],
      rawEvaluations: rawEvaluations,
      examRatio: _parseInt(json['exam_ratio'] ?? json['examRatio']),
      testScoresRaw: json['test_scores'],
      testWeightRaw: json['test_weight'],
    );

    final variableComponents = _parseVariableComponents(
      rawVariable:
          json['variable_components'] ?? json['variable_components_json'],
      rawEvaluations: rawEvaluations,
      regularScoreRaw: json['regular_score'],
      periodicRatio: periodic.ratio,
    );

    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      units: json['credits'] is int
          ? json['credits'] as int
          : (json['units'] is int
                ? json['units'] as int
                : int.tryParse(json['credits']?.toString() ?? '') ??
                      int.tryParse(json['units']?.toString() ?? '2') ??
                      2),
      periodicTests: periodic,
      variableComponents: variableComponents,
      teacher: json['teacher']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final variableJson = variableComponents
        .map((component) => component.toJson())
        .toList(growable: false);

    return {
      'id': id,
      'name': name,
      'credits': units,
      'units': units,
      'periodic_tests': periodicTests.toJson(),
      'variable_components': variableJson,
      'evaluations': _toLegacyEvaluations(),
      'test_scores': jsonEncode(testScores),
      'regular_score': regularScore,
      'test_weight': testWeight,
      'regular_weight': regularWeight,
      'teacher': teacher,
      'exam_ratio': examRatio,
      'examRatio': examRatio,
    };
  }

  List<Map<String, dynamic>> _toLegacyEvaluations() {
    final legacy = <Map<String, dynamic>>[
      <String, dynamic>{'id': 'exam', 'name': '定期試験', 'ratio': examRatio},
      ...variableComponents.map((component) => component.toJson()),
    ];

    if (periodicTests.scores.any((score) => score != null)) {
      final valid = periodicTests.scores.whereType<double>().toList(
        growable: false,
      );
      final avg = valid.isEmpty
          ? null
          : valid.reduce((a, b) => a + b) / valid.length;
      legacy.first['userScore'] = avg;
    }
    return legacy;
  }

  static PeriodicTests _parsePeriodicTests({
    required dynamic rawPeriodic,
    required dynamic rawEvaluations,
    required int? examRatio,
    required dynamic testScoresRaw,
    required dynamic testWeightRaw,
  }) {
    PeriodicTests? parsedPeriodic;
    if (rawPeriodic is Map<String, dynamic>) {
      parsedPeriodic = PeriodicTests.fromJson(rawPeriodic).normalized();
    } else if (rawPeriodic is String && rawPeriodic.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPeriodic);
        if (decoded is Map<String, dynamic>) {
          parsedPeriodic = PeriodicTests.fromJson(decoded).normalized();
        }
      } catch (_) {}
    }

    final testScores = _parseTestScores(testScoresRaw);
    final examFromEvaluations = _tryParseEvaluationList(rawEvaluations)
        .where((component) => component.id.trim().toLowerCase() == 'exam')
        .cast<Evaluation?>()
        .firstWhere((component) => component != null, orElse: () => null);

    final parsedPeriodicLooksDefaultZero =
        parsedPeriodic != null &&
        parsedPeriodic.ratio == 0 &&
        !parsedPeriodic.scores.any((score) => score != null);

    final ratioFromPeriodic =
        (parsedPeriodic != null && !parsedPeriodicLooksDefaultZero)
        ? parsedPeriodic.ratio
        : null;

    final ratio =
        examFromEvaluations?.ratio ??
        examRatio ??
        ratioFromPeriodic ??
        (((_parseDouble(testWeightRaw) ?? 0.7) * 100).round().clamp(0, 100));

    final scores = (parsedPeriodic != null && parsedPeriodic.scores.isNotEmpty)
        ? parsedPeriodic.scores
        : testScores;

    return PeriodicTests(ratio: ratio, count: 4, scores: scores).normalized();
  }

  static List<Evaluation> _parseVariableComponents({
    required dynamic rawVariable,
    required dynamic rawEvaluations,
    required dynamic regularScoreRaw,
    required int periodicRatio,
  }) {
    final parsedVariable = _tryParseEvaluationList(rawVariable);
    if (parsedVariable.isNotEmpty) {
      return parsedVariable;
    }

    final parsedLegacy = _tryParseEvaluationList(rawEvaluations)
        .where((component) {
          final id = component.id.trim().toLowerCase();
          return id != 'exam';
        })
        .toList(growable: false);
    if (parsedLegacy.isNotEmpty) {
      return parsedLegacy;
    }

    final regularScore = _parseDouble(regularScoreRaw);
    final regularRatio = (100 - periodicRatio).clamp(0, 100);
    if (regularRatio == 0 && regularScore == null) {
      return const <Evaluation>[];
    }

    return <Evaluation>[
      Evaluation(
        id: 'normal',
        name: '平常点',
        ratio: regularRatio,
        userScore: regularScore,
      ),
    ];
  }

  static List<Evaluation> _tryParseEvaluationList(dynamic raw) {
    if (raw is List) {
      final parsed = raw
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .map(Evaluation.fromJson)
          .where((e) => e.id.trim().isNotEmpty && e.name.trim().isNotEmpty)
          .toList(growable: false);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = decoded
              .whereType<Map>()
              .map(
                (entry) =>
                    entry.map((key, value) => MapEntry(key.toString(), value)),
              )
              .map(Evaluation.fromJson)
              .where((e) => e.id.trim().isNotEmpty && e.name.trim().isNotEmpty)
              .toList(growable: false);
          if (parsed.isNotEmpty) {
            return parsed;
          }
        }
      } catch (_) {}
    }

    return const <Evaluation>[];
  }

  static List<double?> _parseTestScores(dynamic value) {
    if (value == null || value is! String || value.isEmpty) {
      return const <double?>[];
    }

    try {
      final List<dynamic> decoded = jsonDecode(value);
      return decoded
          .map((e) => e == null ? null : (e as num).toDouble())
          .toList();
    } catch (_) {
      return const <double?>[];
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
