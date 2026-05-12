import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth/auth_api.dart';
import 'auth/auth_controller.dart';
import 'auth/secure_token_store.dart';
import 'config/app_config.dart';
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
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
          scaffoldBackgroundColor: const Color(0xFFF7F8FA),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1F2937),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF0066FF)),
          ),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}
