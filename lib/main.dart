import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_api.dart';
import 'auth/auth_controller.dart';
import 'auth/secure_token_store.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';
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
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(
            tokenStore: SecureTokenStore(),
            authApi: context.read<AuthApi>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: '课表星图',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryStart),
          scaffoldBackgroundColor: AppTheme.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          inputDecorationTheme: AppTheme.inputDecorationTheme,
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryStart,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textPrimary,
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryStart),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
