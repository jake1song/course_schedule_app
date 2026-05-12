import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../widgets/form_fields.dart';

class AddCoursePage extends StatefulWidget {
  const AddCoursePage({this.defaultWeek, this.defaultDay, super.key});
  final int? defaultWeek;
  final String? defaultDay;

  @override
  State<AddCoursePage> createState() => _AddCoursePageState();
}

class _AddCoursePageState extends State<AddCoursePage> {
  late int _week;
  late String _day;
  String _period = '第1节';
  late TextEditingController _nameCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _noteCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _week = widget.defaultWeek ?? AppConfig.detectTeachingWeek();
    _day = widget.defaultDay ?? DayDropdown.items[now.weekday - 1];
    _nameCtrl = TextEditingController();
    _roomCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() { _nameCtrl.dispose(); _roomCtrl.dispose(); _noteCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = '课程名不能为空'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final session = context.read<AuthController>().session;
      if (session == null) { if (mounted) Navigator.of(context).pop(); return; }
      await context.read<AuthApi>().addCourse(session.idToken, {
        'week': _week, 'day': _day, 'period': _period,
        'course': name, 'room': _roomCtrl.text.trim(), 'note': _noteCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _saving = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      title: const Text('新增课程', style: AppTheme.pageTitle),
      actions: [
        _saving
            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
            : TextButton(onPressed: _saving ? null : _save, child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
      ],
    ),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Week + Day card
          _Card(children: [
            Row(children: [
              Expanded(child: WeekNumberField(value: _week, onChanged: (v) => _week = v)),
              const SizedBox(width: 12),
              Expanded(child: DayDropdown(value: _day, onChanged: (v) => _day = v!)),
            ]),
          ]),
          const SizedBox(height: 12),
          // Period card
          _Card(children: [PeriodDropdown(value: _period, onChanged: (v) => _period = v!)]),
          const SizedBox(height: 12),
          // Course details card
          _Card(children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '课程名')),
            const SizedBox(height: 14),
            TextField(controller: _roomCtrl, decoration: const InputDecoration(labelText: '教室')),
            const SizedBox(height: 14),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: '备注'), maxLines: 2),
          ]),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))],
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius))),
              child: Text(_saving ? '保存中...' : '添加课程', style: const TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    ))),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [AppTheme.cardShadow]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: children),
  );
}
