class User {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool hasCompletedOnboarding;
  final String? auth0Id;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.hasCompletedOnboarding = false,
    this.auth0Id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'auth0Id': auth0Id,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      auth0Id: json['auth0Id'],
    );
  }
}
