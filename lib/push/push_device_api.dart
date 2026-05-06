import 'dart:convert';

import 'package:http/http.dart' as http;

class PushDeviceApiException implements Exception {
  const PushDeviceApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class PushDeviceApi {
  PushDeviceApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final http.Client _client;

  Future<void> bindJPushDevice({
    required String idToken,
    required String registrationId,
    required String platform,
  }) async {
    final response = await _client.post(
      baseUrl.replace(path: '${baseUrl.path}/user/bind_push'),
      headers: {
        'authorization': 'Bearer $idToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'provider': 'jpush',
        'registrationId': registrationId,
        'platform': platform,
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    final decoded =
        jsonDecode(response.body.isEmpty ? '{}' : response.body)
            as Map<String, dynamic>;
    throw PushDeviceApiException(
      decoded['error'] as String? ?? 'Failed to bind push device',
      response.statusCode,
    );
  }
}
