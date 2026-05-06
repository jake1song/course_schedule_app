import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
  late final Widget _webViewWidget;
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
          ..setBackgroundColor(Colors.white)
          ..enableZoom(false)
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
              if (typeof setLockedState === 'function') {
                setLockedState(false);
              }
              if (typeof loadAppData === 'function') {
                Promise.resolve(loadAppData()).catch(function () {});
              }
            ''');
              },
            ),
          )
          ..loadRequest(
            AppConfig.webBaseUrl,
            headers: {'Authorization': 'Bearer ${session.idToken}'},
          );
    _webViewWidget = WebViewWidget(controller: _controller);
  }

  Future<void> _handleBackNavigation() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    await SystemNavigator.pop();
  }

  Future<void> _reload() async {
    setState(() {
      _error = '';
      _progress = 0;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 44,
          titleSpacing: 0,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: [
            IconButton(
              tooltip: '刷新',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<String>(
              tooltip: '更多',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'logout') auth.logout();
              },
              itemBuilder:
                  (context) => const [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 10),
                          Text('退出登录'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
          bottom:
              _progress < 100
                  ? PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(value: _progress / 100),
                  )
                  : null,
        ),
        body: SafeArea(
          top: false,
          child:
              _error.isEmpty
                  ? _webViewWidget
                  : Center(
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
                            onPressed: _reload,
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
