import 'dart:async';

import 'package:flutter/foundation.dart';

import '../util/app_logger.dart';
import 'auth_api.dart';
import 'auth_models.dart';
import 'token_store.dart';

enum AuthStatus { loading, unauthenticated, authenticated }

class AuthController extends ChangeNotifier {
  AuthController({
    required TokenStore tokenStore,
    AuthApi? authApi,
    Duration tokenStoreTimeout = const Duration(seconds: 3),
  }) : _tokenStore = tokenStore,
       _authApi = authApi,
       _tokenStoreTimeout = tokenStoreTimeout;

  final TokenStore _tokenStore;
  final AuthApi? _authApi;
  final Duration _tokenStoreTimeout;

  AuthStatus status = AuthStatus.loading;
  StoredSession? session;
  String errorMessage = '';

  Future<void> boot() async {
    AppLogger.info('AuthController: booting');
    StoredSession? stored;
    try {
      stored = await _tokenStore.read().timeout(_tokenStoreTimeout);
    } catch (_) {
      AppLogger.warn('AuthController: token store read failed (timeout or error)');
      await _clearTokenStoreBestEffort();
      errorMessage = '本地登录状态读取失败，请重新登录';
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    if (stored != null &&
        stored.expiresAt.isAfter(
          DateTime.now().add(const Duration(minutes: 5)),
        )) {
      session = stored;
      status = AuthStatus.authenticated;
    } else if (stored != null && _authApi != null) {
      try {
        final refreshed = await _authApi.refresh(stored.refreshToken);
        await _writeTokenStore(refreshed);
        session = StoredSession(
          idToken: refreshed.idToken,
          refreshToken: refreshed.refreshToken,
          expiresAt: refreshed.expiresAt,
        );
        status = AuthStatus.authenticated;
      } on AuthApiException catch (error) {
        await _clearTokenStoreBestEffort();
        errorMessage = error.message;
        status = AuthStatus.unauthenticated;
      } catch (_) {
        await _clearTokenStoreBestEffort();
        errorMessage = '登录已过期，请重新登录';
        status = AuthStatus.unauthenticated;
      }
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String phone, String password) async {
    if (_authApi == null) return;
    AppLogger.info('AuthController: login requested for $phone');
    status = AuthStatus.loading;
    errorMessage = '';
    notifyListeners();
    try {
      final authSession = await _authApi.login(
        phone: phone,
        password: password,
      );
      await _writeTokenStore(authSession);
      session = StoredSession(
        idToken: authSession.idToken,
        refreshToken: authSession.refreshToken,
        expiresAt: authSession.expiresAt,
      );
      status = AuthStatus.authenticated;
    } on AuthApiException catch (error) {
      errorMessage = error.message;
      status = AuthStatus.unauthenticated;
    } on TimeoutException {
      await _clearTokenStoreBestEffort();
      session = null;
      errorMessage = '本地登录状态保存失败，请重试';
      status = AuthStatus.unauthenticated;
    } catch (_) {
      errorMessage = '网络连接失败，请稍后重试';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    if (_authApi == null) return;
    AppLogger.info('AuthController: register requested for $phone');
    status = AuthStatus.loading;
    errorMessage = '';
    notifyListeners();
    try {
      final authSession = await _authApi.register(
        phone: phone,
        code: code,
        password: password,
      );
      await _writeTokenStore(authSession);
      session = StoredSession(
        idToken: authSession.idToken,
        refreshToken: authSession.refreshToken,
        expiresAt: authSession.expiresAt,
      );
      status = AuthStatus.authenticated;
    } on AuthApiException catch (error) {
      errorMessage = error.message;
      status = AuthStatus.unauthenticated;
    } catch (_) {
      errorMessage = '网络连接失败，请稍后重试';
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearTokenStoreBestEffort();
    session = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _writeTokenStore(AuthSession session) {
    return _tokenStore.write(session).timeout(_tokenStoreTimeout);
  }

  Future<void> _clearTokenStoreBestEffort() async {
    try {
      await _tokenStore.clear().timeout(_tokenStoreTimeout);
    } catch (_) {
      // The UI state must recover even if platform secure storage is stuck.
    }
  }
}
