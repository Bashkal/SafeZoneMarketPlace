enum UserRole {
  user('User'),
  admin('Admin');

  const UserRole(this.displayName);
  final String displayName;

  bool get isAdmin => this == UserRole.admin;
}

class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final int productsSubmitted;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.productsSubmitted = 0,
    this.role = UserRole.user,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'productsSubmitted': productsSubmitted,
      'role': role.name,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final roleName = map['role'] as String?;

    return AppUser(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      productsSubmitted: (map['productsSubmitted'] as num?)?.toInt() ?? 0,
      role: roleName != null
          ? UserRole.values.firstWhere(
              (e) => e.name == roleName,
              orElse: () => UserRole.user,
            )
          : UserRole.user,
    );
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    int? productsSubmitted,
    UserRole? role,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      productsSubmitted: productsSubmitted ?? this.productsSubmitted,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AppUser(uid: $uid, email: $email, role: ${role.name})';
}
