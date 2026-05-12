import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_controller.dart';
import '../config/app_theme.dart';
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
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient hero
            Container(
              height: height * 0.38,
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.today_rounded, size: 36, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text('课表星图', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text('课程表与 AI 日程助手', style: TextStyle(fontSize: 14, color: Color(0xB3FFFFFF))),
                  ],
                ),
              ),
            ),
            // Form card
            Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppTheme.screenHPadding),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [AppTheme.cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _phoneController, keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: '手机号',
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textTertiary),
                        errorText: _phoneError(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController, obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done, onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: '密码',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textTertiary),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    if (auth.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(auth.errorMessage, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
                      child: FilledButton(
                        onPressed: isLoading ? null : _login,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
                        ),
                        child: Text(isLoading ? '登录中...' : '登录', style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RegisterPage())),
                      child: const Text('还没有账号？注册'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
