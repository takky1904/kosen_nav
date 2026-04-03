class Evaluation {
  const Evaluation({
    required this.id,
    required this.name,
    required this.ratio,
    this.userScore,
    this.maxScore = 100,
  });

  final String id;
  final String name;
  final int ratio;
  final double? userScore;
  final int maxScore; // 満点（例: 30, 60, 100など）

  Evaluation copyWith({
    String? id,
    String? name,
    int? ratio,
    double? userScore,
    int? maxScore,
    bool clearUserScore = false,
  }) {
    return Evaluation(
      id: id ?? this.id,
      name: name ?? this.name,
      ratio: ratio ?? this.ratio,
      userScore: clearUserScore ? null : (userScore ?? this.userScore),
      maxScore: maxScore ?? this.maxScore,
    );
  }

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ratio: _parseInt(json['ratio'])?.clamp(0, 100) ?? 0,
      userScore: _parseDouble(json['userScore'] ?? json['score']),
      maxScore: _parseInt(json['maxScore']) ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'ratio': ratio,
      'userScore': userScore,
      'maxScore': maxScore,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PeriodicTests {
  const PeriodicTests({
    required this.ratio,
    this.count = 4,
    required this.scores,
    this.maxScore = 100,
  });

  final int ratio;
  final int count;
  final List<double?> scores;
  final int maxScore; // 定期試験の満点

  PeriodicTests normalized() {
    final normalizedScores = List<double?>.filled(count, null, growable: false);
    for (var i = 0; i < count && i < scores.length; i++) {
      normalizedScores[i] = scores[i];
    }
    return PeriodicTests(
      ratio: ratio.clamp(0, 100),
      count: count,
      scores: normalizedScores,
      maxScore: maxScore,
    );
  }

  PeriodicTests copyWith({
    int? ratio,
    int? count,
    List<double?>? scores,
    int? maxScore,
  }) {
    return PeriodicTests(
      ratio: ratio ?? this.ratio,
      count: count ?? this.count,
      scores: scores ?? this.scores,
      maxScore: maxScore ?? this.maxScore,
    ).normalized();
  }

  factory PeriodicTests.fromJson(Map<String, dynamic> json) {
    final parsedCount = Evaluation._parseInt(json['count']) ?? 4;
    final rawScores = json['scores'];
    final parsedScores = <double?>[];
    if (rawScores is List) {
      for (final value in rawScores) {
        parsedScores.add(Evaluation._parseDouble(value));
      }
    }

    return PeriodicTests(
      ratio: Evaluation._parseInt(json['ratio']) ?? 0,
      count: parsedCount <= 0 ? 4 : parsedCount,
      scores: parsedScores,
      maxScore: Evaluation._parseInt(json['maxScore']) ?? 100,
    ).normalized();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ratio': ratio,
      'count': count,
      'scores': scores,
      'maxScore': maxScore,
    };
  }
}
