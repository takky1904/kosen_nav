class SchoolOption {
  const SchoolOption({required this.kosenId, required this.kosenName});

  final String kosenId;
  final String kosenName;

  factory SchoolOption.fromJson(Map<String, dynamic> json) {
    return SchoolOption(
      kosenId: (json['kosenId'] ?? '').toString().trim(),
      kosenName: (json['kosenName'] ?? '').toString().trim(),
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
