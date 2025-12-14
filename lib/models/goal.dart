class Goal {
  final String id;
  final String title;
  final String description;
  final String category; // e.g., 'exercise', 'hydration', 'reading', etc.
  final DateTime createdAt;
  final bool isActive;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      isActive: json['isActive'] ?? true,
    );
  }
}
