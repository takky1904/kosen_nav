class TeamsAssignment {
  const TeamsAssignment({required this.id, required this.title, this.dueDate});

  final String id;
  final String title;
  final DateTime? dueDate;

  factory TeamsAssignment.fromGraphJson(Map<String, dynamic> json) {
    final dueDateTime = json['dueDateTime'];
    DateTime? parsedDueDate;

    if (dueDateTime is Map<String, dynamic>) {
      final raw = dueDateTime['dateTime'];
      if (raw is String && raw.isNotEmpty) {
        parsedDueDate = DateTime.tryParse(raw);
      }
    }

    return TeamsAssignment(
      id: json['id']?.toString() ?? '',
      title:
          json['displayName']?.toString() ??
          json['title']?.toString() ??
          'Teams課題',
      dueDate: parsedDueDate,
    );
  }
}
