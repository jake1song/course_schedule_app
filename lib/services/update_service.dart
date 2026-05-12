import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.downloadUrl,
    required this.changelog,
  });

  final String versionName;
  final int versionCode;
  final String downloadUrl;
  final String changelog;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionName: json['versionName'] as String? ?? '',
      versionCode: json['versionCode'] as int? ?? 0,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
    );
  }
}

class UpdateResult {
  const UpdateResult({this.update, this.error});
  final UpdateInfo? update;
  final String? error;
  bool get hasUpdate => update != null;
}

class UpdateService {
  UpdateService({required this.checkUrl, http.Client? client})
    : _client = client ?? http.Client();

  final Uri checkUrl;
  final http.Client _client;

  Future<UpdateResult> check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(info.buildNumber) ?? 0;
      debugPrint('[Update] current=$currentCode, checking $checkUrl');

      final response = await _client
          .get(checkUrl, headers: {'accept': 'application/json'})
          .timeout(const Duration(seconds: 8));
      debugPrint('[Update] server status=${response.statusCode}');
      if (response.statusCode != 200) return const UpdateResult();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final update = UpdateInfo.fromJson(data);
      debugPrint('[Update] server versionCode=${update.versionCode}');
      if (update.versionCode > currentCode) {
        debugPrint('[Update] NEW VERSION AVAILABLE');
        return UpdateResult(update: update);
      }
      debugPrint('[Update] up to date');
      return const UpdateResult();
    } on SocketException {
      debugPrint('[Update] network unavailable');
      return const UpdateResult();
    } on TimeoutException {
      debugPrint('[Update] timed out');
      return const UpdateResult();
    } catch (e) {
      debugPrint('[Update] error: $e');
      return UpdateResult(error: e.toString());
    }
  }
}
