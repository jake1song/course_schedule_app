import 'auth_models.dart';

abstract class TokenStore {
  Future<StoredSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}
