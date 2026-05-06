class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    this.displayName = '',
    this.avatarUrl = '',
  });

  final String id;
  final String phone;
  final String displayName;
  final String avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String,
      phone: json['phone'] as String,
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final AuthUser user;
  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      idToken: json['idToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class StoredSession {
  const StoredSession({
    required this.idToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String idToken;
  final String refreshToken;
  final DateTime expiresAt;
}
