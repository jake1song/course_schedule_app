import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_api.dart';
import 'auth/auth_controller.dart';
import 'auth/secure_token_store.dart';
import 'config/app_config.dart';
import 'push/jpush_registrar.dart';
import 'push/push_device_api.dart';
import 'push/push_registrar.dart';
import 'screens/auth_gate.dart';

void main() {
  runApp(const CourseScheduleApp());
}

class CourseScheduleApp extends StatelessWidget {
  const CourseScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthApi>(
          create: (_) => AuthApi(baseUrl: AppConfig.apiBaseUrl),
        ),
        Provider<PushDeviceApi>(
          create: (_) => PushDeviceApi(baseUrl: AppConfig.apiBaseUrl),
        ),
        Provider<PushRegistrar>(
          create:
              (context) =>
                  JPushRegistrar(pushDeviceApi: context.read<PushDeviceApi>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create:
              (context) => AuthController(
                tokenStore: SecureTokenStore(),
                authApi: context.read<AuthApi>(),
                pushRegistrar: context.read<PushRegistrar>(),
              ),
        ),
      ],
      child: MaterialApp(
        title: '课表星图',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
