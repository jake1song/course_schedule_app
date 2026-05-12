import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/ai_key_store.dart';

class KeyInputPage extends StatefulWidget {
  const KeyInputPage({required this.onSave, this.onCancel, super.key});
  final ValueChanged<String> onSave;
  final VoidCallback? onCancel;

  @override
  State<KeyInputPage> createState() => _KeyInputPageState();
}

class _KeyInputPageState extends State<KeyInputPage> {
  final _ctrl = TextEditingController();
  String? _error;
  String _model = 'deepseek-chat';

  static const _models = [
    'deepseek-chat',
    'deepseek-reasoner',
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-3.5-turbo',
    'claude-3.5-sonnet',
    'qwen-plus',
    'glm-4',
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    final key = _ctrl.text.trim();
    if (key.isEmpty) { setState(() => _error = '请输入 API Key'); return; }
    if (!key.startsWith('sk-')) { setState(() => _error = 'Key 格式不正确，应以 sk- 开头'); return; }
    AiKeyStore().saveModel(_model);
    widget.onSave(key);
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [AppTheme.cardShadow],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.vpn_key, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('配置 AI', style: AppTheme.pageTitle, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text('Key 加密存储在本地', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(labelText: 'API Key', hintText: 'sk-...', errorText: _error),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _model,
                  decoration: const InputDecoration(labelText: '模型', prefixIcon: Icon(Icons.smart_toy_outlined, color: AppTheme.textTertiary)),
                  items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _model = v); },
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius))),
                    child: const Text('保存并开始使用', style: TextStyle(fontSize: 16)),
                  ),
                ),
                if (widget.onCancel != null) ...[const SizedBox(height: 8), TextButton(onPressed: widget.onCancel, child: const Text('返回'))],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
