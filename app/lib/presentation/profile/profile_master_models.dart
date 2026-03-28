class SchoolOption {
  const SchoolOption({
    required this.kosenId,
    required this.kosenName,
    this.aliases = const <String>[],
  });

  final String kosenId;
  final String kosenName;
  final List<String> aliases;

  factory SchoolOption.fromJson(Map<String, dynamic> json) {
    final aliasesRaw = json['aliases'];
    final aliases = aliasesRaw is List
        ? aliasesRaw
              .map((value) => value.toString().trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
        : const <String>[];

    return SchoolOption(
      kosenId: (json['kosenId'] ?? '').toString().trim(),
      kosenName: (json['kosenName'] ?? '').toString().trim(),
      aliases: aliases,
    );
  }
}

class DepartmentOption {
  const DepartmentOption({required this.id, required this.displayName});

  final String id;
  final String displayName;

  factory DepartmentOption.fromJson(Map<String, dynamic> json) {
    return DepartmentOption(
      id: (json['id'] ?? '').toString().trim(),
      displayName: (json['displayName'] ?? '').toString().trim(),
    );
  }
}
