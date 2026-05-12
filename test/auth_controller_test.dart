import 'package:course_schedule_app/auth/auth_api.dart';
import 'package:course_schedule_app/auth/auth_controller.dart';
import 'package:course_schedule_app/auth/auth_models.dart';
import 'package:course_schedule_app/auth/token_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'dart:async';

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

class HangingReadTokenStore implements TokenStore {
  bool cleared = false;

  @override
  Future<StoredSession?> read() => Completer<StoredSession?>().future;

  @override
  Future<void> write(AuthSession session) async {}

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

class HangingWriteTokenStore implements TokenStore {
  bool cleared = false;

  @override
  Future<StoredSession?> read() async => null;

  @override
  Future<void> write(AuthSession session) => Completer<void>().future;

  @override
  Future<void> clear() async {
    cleared = true;
  }
}

class SuccessfulAuthApi extends AuthApi {
  SuccessfulAuthApi()
    : super(
        baseUrl: Uri.parse('http://example.test/api'),
        client: _NoopClient(),
      );

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    return AuthSession(
      user: const AuthUser(id: 'u1', phone: '13800138000'),
      idToken: 'id-token',
      refreshToken: 'refresh-token',
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
  }
}

class ThrowingAuthApi extends AuthApi {
  ThrowingAuthApi()
    : super(
        baseUrl: Uri.parse('http://example.test/api'),
        client: _NoopClient(),
      );

  @override
  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    throw const AuthApiException('网络连接失败，请稍后重试', 0);
  }

  @override
  Future<AuthSession> refresh(String refreshToken) async {
    throw const AuthApiException('登录已过期，请重新登录', 0);
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw StateError('Unexpected HTTP request in auth controller test.');
  }
}

void main() {
  test('boot recovers when secure token storage read hangs', () async {
    final store = HangingReadTokenStore();
    final controller = AuthController(
      tokenStore: store,
      tokenStoreTimeout: const Duration(milliseconds: 20),
    );

    await controller.boot();

    expect(store.cleared, true);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.errorMessage, '本地登录状态读取失败，请重新登录');
  });

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

  test('boot clears expired stored token when refresh fails', () async {
    final store =
        FakeTokenStore()
          ..value = StoredSession(
            idToken: 'id-token',
            refreshToken: 'refresh-token',
            expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
          );
    final controller = AuthController(
      tokenStore: store,
      authApi: ThrowingAuthApi(),
    );

    await controller.boot();

    expect(store.cleared, true);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.errorMessage, '登录已过期，请重新登录');
  });

  test(
    'login recovers from network failure instead of staying loading',
    () async {
      final controller = AuthController(
        tokenStore: FakeTokenStore(),
        authApi: ThrowingAuthApi(),
      );

      await controller.login('13800138000', 'pass123456');

      expect(controller.status, AuthStatus.unauthenticated);
      expect(controller.errorMessage, '网络连接失败，请稍后重试');
    },
  );

  test('login recovers when secure token storage write hangs', () async {
    final store = HangingWriteTokenStore();
    final controller = AuthController(
      tokenStore: store,
      authApi: SuccessfulAuthApi(),
      tokenStoreTimeout: const Duration(milliseconds: 20),
    );

    await controller.login('13800138000', 'pass123456');

    expect(store.cleared, true);
    expect(controller.session, isNull);
    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.errorMessage, '本地登录状态保存失败，请重试');
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
