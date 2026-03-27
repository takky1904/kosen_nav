import 'dart:convert';
import 'package:uuid/uuid.dart';

enum GradeRank { a, b, c, d }

extension GradeRankExt on GradeRank {
  String get label => name.toUpperCase();

  String get description {
    switch (this) {
      case GradeRank.a:
        return '優 (上位20%)';
      case GradeRank.b:
        return '良 (上位20〜50%)';
      case GradeRank.c:
        return '可 (上位50〜80%)';
      case GradeRank.d:
        return '不可 (下位20%)';
    }
  }
}

class SubjectModel {
  final String id;
  final String name;
  final int units; // 単位数
  int get credits => units;
  final List<double?> testScores; // 最大4回 (null = 未受験)
  final double? regularScore; // 平常点 (0〜100)
  final double testWeight; // テスト比率 (例: 0.7)
  final double regularWeight; // 平常点比率 (例: 0.3)
  final String? teacher; // 担任教員名（任意）
  final int? examRatio; // シラバス由来の試験比率（%）

  const SubjectModel({
    required this.id,
    required this.name,
    required this.units,
    required this.testScores,
    this.regularScore,
    this.testWeight = 0.7,
    this.regularWeight = 0.3,
    this.teacher,
    this.examRatio,
  }) : assert(testScores.length <= 4, 'testScores must have at most 4 entries');

  factory SubjectModel.create({
    required String name,
    required int units,
    double testWeight = 0.7,
    String? teacher,
    int? examRatio,
  }) {
    return SubjectModel(
      id: const Uuid().v4(),
      name: name,
      units: units,
      testScores: const [null, null, null, null],
      testWeight: testWeight,
      regularWeight: 1.0 - testWeight,
      teacher: teacher,
      examRatio: examRatio,
    );
  }

  SubjectModel copyWith({
    String? name,
    int? units,
    List<double?>? testScores,
    double? regularScore,
    double? testWeight,
    String? teacher,
    int? examRatio,
  }) {
    final tw = testWeight ?? this.testWeight;
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      units: units ?? this.units,
      testScores: testScores ?? this.testScores,
      regularScore: regularScore ?? this.regularScore,
      testWeight: tw,
      regularWeight: 1.0 - tw,
      teacher: teacher ?? this.teacher,
      examRatio: examRatio ?? this.examRatio,
    );
  }

  SubjectModel withTestScore(int index, double? score) {
    final updated = List<double?>.from(testScores);
    updated[index] = score;
    return copyWith(testScores: updated);
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
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
      testScores: _parseTestScores(json['test_scores']),
      regularScore: _parseDouble(json['regular_score']),
      testWeight: _parseDouble(json['test_weight']) ?? 0.7,
      regularWeight: _parseDouble(json['regular_weight']) ?? 0.3,
      teacher: json['teacher']?.toString(),
      examRatio: _parseInt(json['exam_ratio'] ?? json['examRatio']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credits': units,
      'units': units,
      'test_scores': jsonEncode(testScores),
      'regular_score': regularScore,
      'test_weight': testWeight,
      'regular_weight': regularWeight,
      'teacher': teacher,
      'exam_ratio': examRatio,
      'examRatio': examRatio,
    };
  }

  static List<double?> _parseTestScores(dynamic value) {
    if (value == null || value is! String || value.isEmpty) {
      return [null, null, null, null];
    }
    try {
      final List<dynamic> decoded = jsonDecode(value);
      return decoded
          .map((e) => e == null ? null : (e as num).toDouble())
          .toList();
    } catch (_) {
      return [null, null, null, null];
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
