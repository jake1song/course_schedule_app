import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() { _phoneController.dispose(); _passwordController.dispose(); super.dispose(); }

  String? _phoneError() {
    final t = _phoneController.text.trim();
    if (t.isEmpty) return null;
    if (!RegExp(r'^1\d{10}$').hasMatch(t)) return '请输入正确的 11 位手机号';
    return null;
  }

  Future<void> _login() async {
    if (_phoneController.text.trim().isEmpty || _passwordController.text.isEmpty) return;
    if (!RegExp(r'^1\d{10}$').hasMatch(_phoneController.text.trim())) return;
    await context.read<AuthController>().login(_phoneController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.status == AuthStatus.loading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.today_rounded, size: 56, color: Color(0xFF0066FF)),
                  const SizedBox(height: 20),
                  Text('课表星图', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF1F2937))),
                  const SizedBox(height: 8),
                  Text('登录后继续使用课程表与 AI 日程助手', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF6B7280), fontSize: 14)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _phoneController, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(labelText: '手机号', prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF9CA3AF)), errorText: _phoneError()),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController, obscureText: _obscurePassword, textInputAction: TextInputAction.done, onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: '密码', prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9CA3AF)),
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF9CA3AF)), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                    ),
                  ),
                  if (auth.errorMessage.isNotEmpty) ...[const SizedBox(height: 12), Text(auth.errorMessage, style: const TextStyle(color: Color(0xFFEF4444)))],
                  const SizedBox(height: 22),
                  FilledButton(onPressed: isLoading ? null : _login, child: Text(isLoading ? '登录中...' : '登录')),
                  TextButton(onPressed: isLoading ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterPage())), child: const Text('还没有账号？注册')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
