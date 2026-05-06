import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../auth/auth_controller.dart';
import '../config/app_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _tokenInjected = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthController>();
    final session = auth.session!;
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'NativeAuth',
            onMessageReceived: (message) {
              final data = jsonDecode(message.message) as Map<String, dynamic>;
              if (data['type'] == 'logout') auth.logout();
            },
          )
          ..addJavaScriptChannel('NativePush', onMessageReceived: (_) {})
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) => setState(() => _progress = progress),
              onWebResourceError: (error) {
                if (error.isForMainFrame ?? false) {
                  setState(() => _error = error.description);
                }
              },
              onPageFinished: (_) async {
                if (_tokenInjected) return;
                _tokenInjected = true;
                await _controller.runJavaScript('''
              localStorage.setItem('courseScheduleAuthTokenV1', ${jsonEncode(session.idToken)});
              localStorage.setItem('courseScheduleAuthTokenExpiresV1', ${jsonEncode(session.expiresAt.toIso8601String())});
              location.reload();
            ''');
              },
            ),
          )
          ..loadRequest(
            AppConfig.webBaseUrl,
            headers: {'Authorization': 'Bearer ${session.idToken}'},
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (_error.isEmpty)
              WebViewWidget(controller: _controller)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48),
                      const SizedBox(height: 12),
                      Text(_error, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          setState(() => _error = '');
                          _controller.reload();
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
          ],
        ),
      ),
    );
  }
}
