import 'dart:convert';

import 'package:course_schedule_app/auth/auth_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('login returns parsed auth session', () async {
    final api = AuthApi(
      baseUrl: Uri.parse('http://example.test/api'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/native/auth/login');
        expect(jsonDecode(request.body), {
          'phone': '13800138000',
          'password': 'pass123456',
        });
        return http.Response(
          jsonEncode({
            'user': {'id': 'u1', 'phone': '13800138000'},
            'idToken': 'id-token',
            'refreshToken': 'refresh-token',
            'expiresAt': '2026-05-07T00:00:00.000Z',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final session = await api.login(
      phone: '13800138000',
      password: 'pass123456',
    );

    expect(session.user.id, 'u1');
    expect(session.user.phone, '13800138000');
    expect(session.idToken, 'id-token');
    expect(session.refreshToken, 'refresh-token');
  });

  test('login throws api exception on backend error', () async {
    final api = AuthApi(
      baseUrl: Uri.parse('http://example.test/api'),
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Invalid phone or password'}),
          401,
        );
      }),
    );

    expect(
      () => api.login(phone: '13800138000', password: 'bad-password'),
      throwsA(isA<AuthApiException>()),
    );
  });
}
