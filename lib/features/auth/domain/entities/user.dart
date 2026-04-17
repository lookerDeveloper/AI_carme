class User {
  final String id;
  final String username;
  final String email;
  final String role;
  final String? avatar;
  final int usageCount;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatar,
    this.usageCount = 0,
    this.lastLoginAt,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? role,
    String? avatar,
    int? usageCount,
    DateTime? lastLoginAt,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      usageCount: usageCount ?? this.usageCount,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        username: json['username'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        avatar: json['avatar'] as String?,
        usageCount: (json['usage_count'] as int?) ?? 0,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.tryParse(json['last_login_at'] as String)
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'role': role,
        'avatar': avatar,
        'usage_count': usageCount,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

enum UserRole { admin, user }
