import 'package:flutter/foundation.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';

import '../config/app_config.dart';
import 'push_device_api.dart';
import 'push_registrar.dart';

class JPushRegistrar implements PushRegistrar {
  static const int registrationIdAttempts = 5;

  JPushRegistrar({
    required PushDeviceApi pushDeviceApi,
    JPushFlutterInterface? jpush,
    TargetPlatform? platform,
    Future<void> Function(Map<String, dynamic> event)? onOpenNotification,
  }) : _pushDeviceApi = pushDeviceApi,
       _jpush = jpush ?? JPush.newJPush(),
       _platform = platform ?? defaultTargetPlatform,
       _onOpenNotification = onOpenNotification;

  final PushDeviceApi _pushDeviceApi;
  final JPushFlutterInterface _jpush;
  final TargetPlatform _platform;
  final Future<void> Function(Map<String, dynamic> event)? _onOpenNotification;

  bool _initialized = false;

  @override
  Future<void> registerAndBind({required String idToken}) async {
    final appKey = AppConfig.jpushAppKey.trim();
    if (appKey.isEmpty) return;

    _initialize(appKey);
    final registrationId = await _readRegistrationId();
    if (registrationId.isEmpty) return;

    await _pushDeviceApi.bindJPushDevice(
      idToken: idToken,
      registrationId: registrationId,
      platform: _platformName(_platform),
    );
  }

  void _initialize(String appKey) {
    if (_initialized) return;

    _jpush.addEventHandler(
      onOpenNotification: (event) async {
        await _onOpenNotification?.call(event);
      },
    );
    _jpush.setAuth(enable: true);
    _jpush.setup(
      appKey: appKey,
      channel: AppConfig.jpushChannel,
      production: AppConfig.jpushProduction,
      debug: !AppConfig.jpushProduction,
    );
    _jpush.requestRequiredPermission();
    _jpush.applyPushAuthority();
    _initialized = true;
  }

  Future<String> _readRegistrationId() async {
    for (var attempt = 0; attempt < registrationIdAttempts; attempt += 1) {
      final registrationId = (await _jpush.getRegistrationID()).trim();
      if (registrationId.isNotEmpty) return registrationId;
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    return '';
  }

  String _platformName(TargetPlatform platform) {
    return platform == TargetPlatform.iOS ? 'ios' : 'android';
  }
}
