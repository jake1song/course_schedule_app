import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../models/native_course.dart';
import '../widgets/form_fields.dart';

class EditCoursePage extends StatefulWidget {
  const EditCoursePage({required this.course, super.key});
  final NativeCourse course;

  @override
  State<EditCoursePage> createState() => _EditCoursePageState();
}

class _EditCoursePageState extends State<EditCoursePage> {
  late int _week;
  late String _day;
  late String _period;
  late TextEditingController _nameCtrl;
  late TextEditingController _roomCtrl;
  late TextEditingController _noteCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _week = widget.course.week;
    _day = DayDropdown.items.contains(widget.course.day) ? widget.course.day : DayDropdown.items.first;
    _period = PeriodDropdown.items.contains(widget.course.period) ? widget.course.period : PeriodDropdown.items.first;
    _nameCtrl = TextEditingController(text: widget.course.course);
    _roomCtrl = TextEditingController(text: widget.course.room);
    _noteCtrl = TextEditingController(text: widget.course.note);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = '课程名不能为空'); return; }
    setState(() { _saving = true; _error = null; });

    try {
      final session = context.read<AuthController>().session;
      if (session == null) { if (mounted) Navigator.of(context).pop(); return; }
      await context.read<AuthApi>().updateCourse(widget.course.id!, session.idToken, {
        'week': _week, 'day': _day, 'period': _period,
        'course': name, 'room': _roomCtrl.text.trim(), 'note': _noteCtrl.text.trim(),
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) { if (mounted) setState(() { _error = e.toString(); _saving = false; }); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('编辑课程'), actions: [
      IconButton(icon: const Icon(Icons.check), onPressed: _saving ? null : _save, tooltip: '保存'),
    ]),
    body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: WeekNumberField(value: _week, onChanged: (v) => _week = v)),
          const SizedBox(width: 12),
          Expanded(child: DayDropdown(value: _day, onChanged: (v) => _day = v!)),
        ]),
        const SizedBox(height: 14),
        PeriodDropdown(value: _period, onChanged: (v) => _period = v!),
        const SizedBox(height: 14),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '课程名', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        TextField(controller: _roomCtrl, decoration: const InputDecoration(labelText: '教室', border: OutlineInputBorder())),
        const SizedBox(height: 14),
        TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: '备注', border: OutlineInputBorder()), maxLines: 2),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Color(0xFFEF4444)))],
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? '保存中...' : '保存修改')),
      ]),
    )))),
  );
}

