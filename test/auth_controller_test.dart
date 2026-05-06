import 'dart:async';

import 'package:course_schedule_app/auth/auth_controller.dart';
import 'package:course_schedule_app/auth/auth_models.dart';
import 'package:course_schedule_app/auth/token_store.dart';
import 'package:course_schedule_app/push/push_registrar.dart';
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

class FakePushRegistrar implements PushRegistrar {
  final tokens = <String>[];

  @override
  Future<void> registerAndBind({required String idToken}) async {
    tokens.add(idToken);
  }
}

class BlockingPushRegistrar implements PushRegistrar {
  BlockingPushRegistrar(this.completer);

  final Completer<void> completer;
  final tokens = <String>[];

  @override
  Future<void> registerAndBind({required String idToken}) async {
    tokens.add(idToken);
    await completer.future;
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

  test('boot registers push device after stored token authenticates', () async {
    final store =
        FakeTokenStore()
          ..value = StoredSession(
            idToken: 'id-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
    final pushRegistrar = FakePushRegistrar();
    final controller = AuthController(
      tokenStore: store,
      pushRegistrar: pushRegistrar,
    );

    await controller.boot();
    await Future<void>.delayed(Duration.zero);

    expect(pushRegistrar.tokens, ['id-token']);
  });

  test('boot does not wait for slow push device binding', () async {
    final store =
        FakeTokenStore()
          ..value = StoredSession(
            idToken: 'id-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
    final completer = Completer<void>();
    final pushRegistrar = BlockingPushRegistrar(completer);
    final controller = AuthController(
      tokenStore: store,
      pushRegistrar: pushRegistrar,
    );

    await controller.boot().timeout(const Duration(milliseconds: 100));
    await Future<void>.delayed(Duration.zero);

    expect(controller.status, AuthStatus.authenticated);
    expect(pushRegistrar.tokens, ['id-token']);
    completer.complete();
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
