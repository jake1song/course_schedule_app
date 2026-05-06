import 'package:course_schedule_app/auth/auth_controller.dart';
import 'package:course_schedule_app/auth/auth_models.dart';
import 'package:course_schedule_app/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeTokenStore implements TokenStore {
  StoredSession? value;
  bool cleared = false;

  @override
  Future<StoredSession?> read() async => value;

  @override
  Future<void> write(AuthSession session) async {
    value = StoredSession(
      idToken: session.idToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
  }

  @override
  Future<void> clear() async {
    cleared = true;
    value = null;
  }
}

void main() {
  test('boot uses stored unexpired token', () async {
    final store =
        FakeTokenStore()
          ..value = StoredSession(
            idToken: 'id-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
    final controller = AuthController(tokenStore: store);

    await controller.boot();

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.session?.idToken, 'id-token');
  });

  test('logout clears token store', () async {
    final store =
        FakeTokenStore()
          ..value = StoredSession(
            idToken: 'id-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
    final controller = AuthController(tokenStore: store);

    await controller.boot();
    await controller.logout();

    expect(store.cleared, true);
    expect(controller.status, AuthStatus.unauthenticated);
  });
}
