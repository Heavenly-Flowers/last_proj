enum UserRole {
  user,
  admin;

  static UserRole fromString(String value) {
    return value == 'admin' ? UserRole.admin : UserRole.user;
  }

  String get displayName {
    return switch (this) {
      UserRole.user => 'Пользователь',
      UserRole.admin => 'Администратор',
    };
  }
}

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'user'),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}
