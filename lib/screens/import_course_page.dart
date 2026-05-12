import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../config/app_theme.dart';
import '../models/native_course.dart';
import '../util/app_logger.dart';

class ImportCoursePage extends StatefulWidget {
  const ImportCoursePage({super.key});

  @override
  State<ImportCoursePage> createState() => _ImportCoursePageState();
}

class _ImportCoursePageState extends State<ImportCoursePage> {
  final _textController = TextEditingController();
  List<NativeCourse> _preview = const [];
  bool _loading = false;
  String _message = '';

  @override
  void dispose() { _textController.dispose(); super.dispose(); }

  void _parse() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final courses = _parseText(text);
    setState(() {
      _preview = courses;
      _message = courses.isEmpty ? '未能解析到课程数据，请检查格式' : '解析到 ${courses.length} 条课程';
    });
  }

  Future<void> _submit() async {
    if (_preview.isEmpty) return;
    setState(() { _loading = true; _message = ''; });
    try {
      final session = context.read<AuthController>().session;
      if (session == null) {
        setState(() { _loading = false; _message = '登录状态已失效'; });
        return;
      }
      final api = context.read<AuthApi>();
      final courses = _preview.map((c) => {'week': c.week, 'day': c.day, 'period': c.period, 'course': c.course, 'room': c.room, 'note': c.note}).toList();
      await api.authenticatedPost('courses/batch', session.idToken, {'courses': courses});
      AppLogger.info('ImportCoursePage: imported ${courses.length} courses');
      if (mounted) Navigator.of(context).pop(true);
    } on AuthApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = '导入失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static List<NativeCourse> _parseText(String text) {
    final lines = text.split(RegExp(r'[\r\n]+')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const [];
    final firstLine = lines.first;
    String delimiter;
    if (firstLine.contains('\t')) { delimiter = '\t'; }
    else if (firstLine.contains(',')) { delimiter = ','; }
    else { delimiter = r'\s+'; }
    final courses = <NativeCourse>[];
    final startIndex = _looksLikeHeader(firstLine, delimiter) ? 1 : 0;

    for (var i = startIndex; i < lines.length; i++) {
      final parts = delimiter == r'\s+'
          ? lines[i].trim().split(RegExp(r'\s+'))
          : lines[i].split(delimiter).map((s) => s.trim()).toList();
      if (parts.length < 4) continue;
      final week = int.tryParse(parts[0]) ?? 0;
      final day = _normalizeDay(parts[1]);
      final period = _normalizePeriod(parts[2]);
      final courseName = parts[3];
      final room = parts.length > 4 ? parts[4] : '';
      final note = parts.length > 5 ? parts.sublist(5).join(' ') : '';
      if (week > 0 && day.isNotEmpty && period.isNotEmpty && courseName.isNotEmpty) {
        courses.add(NativeCourse(week: week, day: day, period: period, course: courseName, room: room, note: note));
      }
    }
    courses.sort(NativeCourse.compare);
    return courses;
  }

  static bool _looksLikeHeader(String line, String delimiter) {
    final lower = line.toLowerCase();
    return lower.contains('周') || lower.contains('星期') || lower.contains('week') || lower.contains('day');
  }

  static String _normalizeDay(String raw) {
    final map = {
      '周一': '周一', '星期二': '周二', '星期三': '周三', '星期四': '周四',
      '星期五': '周五', '星期六': '周六', '星期日': '周日',
      'mon': '周一', 'tue': '周二', 'wed': '周三', 'thu': '周四',
      'fri': '周五', 'sat': '周六', 'sun': '周日',
      '1': '周一', '2': '周二', '3': '周三', '4': '周四',
      '5': '周五', '6': '周六', '7': '周日',
    };
    return map[raw.toLowerCase()] ?? map[raw] ?? raw;
  }

  static String _normalizePeriod(String raw) {
    final cleaned = raw.replaceAll('节', '').trim();
    final n = int.tryParse(cleaned);
    if (n != null && n >= 1 && n <= 12) return '第$n节';
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('导入课表', style: AppTheme.pageTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [AppTheme.cardShadow]),
                child: TextField(
                  controller: _textController,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: '粘贴教务系统导出的课表文本\n\n支持格式：\n周次 星期 节次 课程名 教室 备注\n1 周一 第1节 高等数学 A101',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                    suffixIcon: _textController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _textController.clear(); setState(() { _preview = const []; _message = ''; }); })
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: _parse, child: const Text('解析预览')),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(gradient: _preview.isEmpty ? null : AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
                    child: FilledButton(
                      onPressed: _loading || _preview.isEmpty ? null : _submit,
                      style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius))),
                      child: Text(_loading ? '导入中...' : '导入 (${_preview.length}条)'),
                    ),
                  ),
                ],
              ),
            ),
            if (_message.isNotEmpty) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_message, style: TextStyle(color: _message.contains('成功') ? Colors.green : Colors.red, fontSize: 13)),
            ),
            const Divider(),
            Expanded(
              child: _preview.isEmpty
                  ? const Center(child: Text('粘贴课表文本后点击"解析预览"', style: TextStyle(color: AppTheme.textTertiary)))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                      itemCount: _preview.length,
                      itemBuilder: (context, index) {
                        final c = _preview[index];
                        final accent = AppTheme.periodColor(c.period);
                        return Dismissible(
                          key: ValueKey('$index-${c.week}-${c.day}-${c.period}-${c.course}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            setState(() {
                              _preview = List.of(_preview)..removeAt(index);
                              _message = '已移除 1 条，剩余 ${_preview.length} 条';
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: const [AppTheme.cardShadow]),
                            child: IntrinsicHeight(
                              child: Row(children: [
                                Container(width: 4, color: accent),
                                Expanded(
                                  child: ListTile(
                                    dense: true,
                                    title: Text(c.course, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text('第${c.week}周 $c.day $c.period  ${c.room.isNotEmpty ? c.room : ''}'),
                                    trailing: c.note.isNotEmpty ? Text(c.note, style: AppTheme.tinyText) : null,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
