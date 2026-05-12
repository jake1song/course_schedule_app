import 'dart:convert';
import 'dart:async';
import 'dart:io';

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
  AuthApi({
    required this.baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client(),
       _timeout = timeout;

  final Uri baseUrl;
  final http.Client _client;
  final Duration _timeout;

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

  Future<Map<String, dynamic>> authenticatedGet(
    String path,
    String idToken,
  ) async {
    try {
      final response = await _client
          .get(
            baseUrl.replace(path: '${baseUrl.path}/${path.replaceFirst(RegExp(r'^/'), '')}'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'accept': 'application/json',
            },
          )
          .timeout(_timeout);
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
    } on TimeoutException {
      throw const AuthApiException('请求超时，请检查网络后重试', 0);
    } on SocketException catch (e) {
      throw AuthApiException('无法连接服务器（${e.address?.address ?? e.message}），请确认服务器已启动', 0);
    } on AuthApiException {
      rethrow;
    } on Object {
      throw const AuthApiException('网络连接失败，请稍后重试', 0);
    }
  }

  Future<Map<String, dynamic>> authenticatedPost(
    String path,
    String idToken,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            baseUrl.replace(path: '${baseUrl.path}/${path.replaceFirst(RegExp(r'^/'), '')}'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'content-type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
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
    } on TimeoutException {
      throw const AuthApiException('请求超时，请检查网络后重试', 0);
    } on SocketException catch (e) {
      throw AuthApiException('无法连接服务器（${e.address?.address ?? e.message}），请确认服务器已启动', 0);
    } on AuthApiException {
      rethrow;
    } on Object {
      throw const AuthApiException('网络连接失败，请稍后重试', 0);
    }
  }

  Future<Map<String, dynamic>> addCourse(
    String idToken,
    Map<String, dynamic> data,
  ) async => _authorizedRequest('POST', 'courses', idToken, data);

  Future<Map<String, dynamic>> updateCourse(
    String id,
    String idToken,
    Map<String, dynamic> data,
  ) async => _authorizedRequest('PUT', 'courses/$id', idToken, data);

  Future<Map<String, dynamic>> deleteCourse(
    String id,
    String idToken,
  ) async => _authorizedRequest('DELETE', 'courses/$id', idToken, null);

  Future<Map<String, dynamic>> _authorizedRequest(
    String method,
    String path,
    String idToken,
    Map<String, dynamic>? data,
  ) async {
    try {
      final uri = baseUrl.replace(
        path: '${baseUrl.path}/${path.replaceFirst(RegExp(r'^/'), '')}',
      );
      late final http.Response response;
      switch (method) {
        case 'POST':
          response = await _client.post(uri, headers: _headers(idToken), body: jsonEncode(data ?? {})).timeout(_timeout);
        case 'PUT':
          response = await _client.put(uri, headers: _headers(idToken), body: jsonEncode(data ?? {})).timeout(_timeout);
        case 'DELETE':
          response = await _client.delete(uri, headers: _headers(idToken)).timeout(_timeout);
        default:
          throw const AuthApiException('不支持的请求方法', 0);
      }
      final decoded = jsonDecode(response.body.isEmpty ? '{}' : response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthApiException(decoded['error'] as String? ?? '请求失败', response.statusCode);
      }
      return decoded;
    } on TimeoutException {
      throw const AuthApiException('请求超时，请检查网络后重试', 0);
    } on SocketException catch (e) {
      throw AuthApiException('无法连接服务器（${e.address?.address ?? e.message}）', 0);
    } on AuthApiException {
      rethrow;
    } on Object {
      throw const AuthApiException('网络连接失败，请稍后重试', 0);
    }
  }

  Map<String, String> _headers(String idToken) => {
    'Authorization': 'Bearer $idToken',
    'content-type': 'application/json',
  };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            baseUrl.replace(path: '${baseUrl.path}/${path.replaceFirst(RegExp(r'^/'), '')}'),
            headers: {'content-type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
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
    } on TimeoutException {
      throw const AuthApiException('请求超时，请检查网络后重试', 0);
    } on SocketException catch (e) {
      throw AuthApiException('无法连接服务器（${e.address?.address ?? e.message}），请确认服务器已启动', 0);
    } on AuthApiException {
      rethrow;
    } on Object {
      throw const AuthApiException('网络连接失败，请稍后重试', 0);
    }
  }
}
