import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_controller.dart';
import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _bootTimeout = Duration(seconds: 8);

  Timer? _timeoutTimer;
  bool _bootTimedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timeoutTimer = Timer(_bootTimeout, () {
        if (!mounted) return;
        setState(() => _bootTimedOut = true);
      });
      final controller = context.read<AuthController>();
      controller.addListener(_onAuthChanged);
      controller.boot();
    });
  }

  void _onAuthChanged() {
    _timeoutTimer?.cancel();
    if (mounted) setState(() => _bootTimedOut = false);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    context.read<AuthController>().removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bootTimedOut) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48, color: Color(0xFFF59E0B)),
                const SizedBox(height: 16),
                const Text('启动超时，请检查网络后重试', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    _timeoutTimer?.cancel();
                    setState(() => _bootTimedOut = false);
                    context.read<AuthController>().boot();
                    _timeoutTimer = Timer(_bootTimeout, () {
                      if (!mounted) return;
                      setState(() => _bootTimedOut = true);
                    });
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final controller = context.watch<AuthController>();
    return switch (controller.status) {
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.authenticated => const HomePage(),
      AuthStatus.unauthenticated => const LoginPage(),
    };
  }
}
