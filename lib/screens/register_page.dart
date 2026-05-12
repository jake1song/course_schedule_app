import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  String _smsMessage = '';
  bool _obscurePassword = true;

  @override
  void dispose() { _phoneController.dispose(); _codeController.dispose(); _passwordController.dispose(); super.dispose(); }

  String? _phoneError() { final t = _phoneController.text.trim(); if (t.isEmpty) return null; if (!RegExp(r'^1\d{10}$').hasMatch(t)) return '请输入正确的 11 位手机号'; return null; }
  String? _passwordError() { final t = _passwordController.text; if (t.isNotEmpty && t.length < 8) return '密码至少 8 位'; return null; }

  Future<void> _requestSms() async {
    final p = _phoneController.text.trim();
    if (p.isEmpty || !RegExp(r'^1\d{10}$').hasMatch(p)) return;
    try { await context.read<AuthApi>().requestSms(p); if (mounted) setState(() => _smsMessage = '验证码已发送'); }
    on AuthApiException catch (e) { if (mounted) setState(() => _smsMessage = e.message); }
  }

  Future<void> _register() async {
    final p = _phoneController.text.trim(); final pw = _passwordController.text;
    if (p.isEmpty || !RegExp(r'^1\d{10}$').hasMatch(p)) return; if (pw.length < 8) return;
    await context.read<AuthController>().register(phone: p, code: _codeController.text.trim(), password: pw);
    if (!mounted) return;
    if (context.read<AuthController>().status == AuthStatus.authenticated) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.status == AuthStatus.loading;
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: '手机号', prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF)), errorText: _phoneError())),
                  const SizedBox(height: 14),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: TextField(controller: _codeController, keyboardType: TextInputType.number, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: '验证码', prefixIcon: Icon(Icons.sms_outlined, color: Color(0xFF9CA3AF))))), const SizedBox(width: 12), OutlinedButton(onPressed: isLoading ? null : _requestSms, child: const Text('获取验证码'))]),
                  const SizedBox(height: 14),
                  TextField(controller: _passwordController, obscureText: _obscurePassword, textInputAction: TextInputAction.done, onSubmitted: (_) => _register(), onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: '设置密码', helperText: '至少 8 位', prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)), suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)), errorText: _passwordError())),
                  if (_smsMessage.isNotEmpty) ...[const SizedBox(height: 12), Text(_smsMessage, style: const TextStyle(color: Color(0xFFEF4444)))],
                  if (auth.errorMessage.isNotEmpty) ...[const SizedBox(height: 12), Text(auth.errorMessage, style: const TextStyle(color: Color(0xFFEF4444)))],
                  const SizedBox(height: 24),
                  FilledButton(onPressed: isLoading ? null : _register, child: Text(isLoading ? '处理中...' : '注册并登录')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
