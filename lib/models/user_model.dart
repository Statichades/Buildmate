class User {
  final int id;
  final String name;
  final String email;
  final bool emailVerified;
  final String? mobileNumber;
  final String? profileUrl;
  final String? deleteUrl;
  final String? role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerified = false,
    this.mobileNumber,
    this.profileUrl,
    this.deleteUrl,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerified:
          (json['email_verified'] == 1) || (json['email_verified'] == true),
      mobileNumber: json['mobile_number'],
      profileUrl: json['profile_url'],
      deleteUrl: json['delete_url'],
      role: json['role'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified': emailVerified,
      'mobile_number': mobileNumber,
      'profile_url': profileUrl,
      'delete_url': deleteUrl,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? emailVerified,
    String? mobileNumber,
    String? profileUrl,
    String? deleteUrl,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileUrl: profileUrl ?? this.profileUrl,
      deleteUrl: deleteUrl ?? this.deleteUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
