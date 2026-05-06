import 'dart:convert';

import 'package:course_schedule_app/push/push_device_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('bindJPushDevice sends registrationId with native auth token', () async {
    final api = PushDeviceApi(
      baseUrl: Uri.parse('http://example.test/api'),
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/user/bind_push');
        expect(request.headers['authorization'], 'Bearer id-token');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), {
          'provider': 'jpush',
          'registrationId': 'rid-android',
          'platform': 'android',
        });
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }),
    );

    await api.bindJPushDevice(
      idToken: 'id-token',
      registrationId: 'rid-android',
      platform: 'android',
    );
  });
}
