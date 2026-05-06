import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_models.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class AuthApi {
  AuthApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  Future<void> requestSms(String phone) async {
    await _post('/native/auth/sms', {'phone': phone});
  }

  Future<AuthSession> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    final json = await _post('/native/auth/register', {
      'phone': phone,
      'code': code,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> login({
    required String phone,
    required String password,
  }) async {
    final json = await _post('/native/auth/login', {
      'phone': phone,
      'password': password,
    });
    return AuthSession.fromJson(json);
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final json = await _post('/native/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthSession.fromJson(json);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      baseUrl.replace(path: '${baseUrl.path}$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    final decoded =
        jsonDecode(response.body.isEmpty ? '{}' : response.body)
            as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(
        decoded['error'] as String? ??
            decoded['detail'] as String? ??
            'Request failed',
        response.statusCode,
      );
    }
    return decoded;
  }
}
