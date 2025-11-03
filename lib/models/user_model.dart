class User {
  final int id;
  final String name;
  final String email;
  final bool emailVerified;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerified: json['email_verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified': emailVerified,
    };
  }
}
