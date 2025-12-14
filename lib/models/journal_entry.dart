class JournalEntry {
  final String id;
  final DateTime date;
  final String content;
  final List<String> linkedEntryIds; // IDs of past entries linked to this one
  final Map<String, String> goalResponses; // goalId -> response
  final DateTime createdAt;
  final DateTime? updatedAt;

  JournalEntry({
    required this.id,
    required this.date,
    required this.content,
    this.linkedEntryIds = const [],
    this.goalResponses = const {},
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'content': content,
      'linkedEntryIds': linkedEntryIds,
      'goalResponses': goalResponses,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      content: json['content'],
      linkedEntryIds: List<String>.from(json['linkedEntryIds'] ?? []),
      goalResponses: Map<String, String>.from(json['goalResponses'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}
