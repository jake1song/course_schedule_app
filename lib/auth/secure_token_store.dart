import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_models.dart';
import 'token_store.dart';

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _idTokenKey = 'idToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _expiresAtKey = 'expiresAt';

  final FlutterSecureStorage _storage;

  @override
  Future<StoredSession?> read() async {
    final idToken = await _storage.read(key: _idTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAt = await _storage.read(key: _expiresAtKey);
    if (idToken == null || refreshToken == null || expiresAt == null) {
      return null;
    }
    return StoredSession(
      idToken: idToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAt),
    );
  }

  @override
  Future<void> write(AuthSession session) async {
    await _storage.write(key: _idTokenKey, value: session.idToken);
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(
      key: _expiresAtKey,
      value: session.expiresAt.toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
