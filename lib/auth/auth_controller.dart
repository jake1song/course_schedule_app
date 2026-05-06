import 'package:flutter/foundation.dart';

import 'auth_api.dart';
import 'auth_models.dart';
import 'token_store.dart';
import '../push/push_registrar.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStore tokenStore,
    AuthApi? authApi,
    PushRegistrar? pushRegistrar,
  }) : _tokenStore = tokenStore,
       _authApi = authApi,
       _pushRegistrar = pushRegistrar;

  final TokenStore _tokenStore;
  final AuthApi? _authApi;
  final PushRegistrar? _pushRegistrar;

  AuthStatus status = AuthStatus.loading;
  StoredSession? session;
  String errorMessage = '';

  Future<void> boot() async {
    final stored = await _tokenStore.read();
    if (stored != null &&
        stored.expiresAt.isAfter(
          DateTime.now().add(const Duration(minutes: 5)),
        )) {
      session = stored;
      status = AuthStatus.authenticated;
      await _registerPushDevice();
    } else if (stored != null && _authApi != null) {
      try {
        final refreshed = await _authApi.refresh(stored.refreshToken);
        await _tokenStore.write(refreshed);
        session = StoredSession(
          idToken: refreshed.idToken,
          refreshToken: refreshed.refreshToken,
          expiresAt: refreshed.expiresAt,
        );
        status = AuthStatus.authenticated;
        await _registerPushDevice();
      } catch (_) {
        await _tokenStore.clear();
        status = AuthStatus.unauthenticated;
      }
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    if (_authApi == null) return;
    status = AuthStatus.loading;
    errorMessage = '';
    notifyListeners();
    try {
      final authSession = await _authApi.login(
        phone: phone,
        password: password,
      );
      await _tokenStore.write(authSession);
      session = StoredSession(
        idToken: authSession.idToken,
        refreshToken: authSession.refreshToken,
        expiresAt: authSession.expiresAt,
      );
      status = AuthStatus.authenticated;
      await _registerPushDevice();
    } on AuthApiException catch (error) {
      errorMessage = error.message;
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> saveSession(AuthSession authSession) async {
    await _tokenStore.write(authSession);
    session = StoredSession(
      idToken: authSession.idToken,
      refreshToken: authSession.refreshToken,
      expiresAt: authSession.expiresAt,
    );
    status = AuthStatus.authenticated;
    await _registerPushDevice();
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    session = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _registerPushDevice() async {
    final idToken = session?.idToken;
    if (idToken == null || _pushRegistrar == null) return;
    try {
      await _pushRegistrar.registerAndBind(idToken: idToken);
    } catch (_) {
      // Push registration must not block login or automatic session restore.
    }
  }
}
