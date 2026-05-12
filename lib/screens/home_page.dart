import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../models/native_course.dart';
import '../services/update_service.dart';
import '../util/app_logger.dart';
import '../widgets/action_strip.dart';
import '../widgets/empty_state.dart';
import '../widgets/nav_tab.dart';
import '../widgets/schedule_row_tile.dart';
import '../widgets/update_dialog.dart';
import 'add_course_page.dart';
import 'ai_chat_page.dart';
import 'edit_course_page.dart';
import 'import_course_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<NativeCourseSchedule> _coursesFuture;
  int _selectedWeek = AppConfig.detectTeachingWeek();
  final _scrollController = ScrollController();
  String _appVersion = '加载中...';

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadNativeCourses();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = '${info.version} (build ${info.buildNumber})');
    });
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  Future<NativeCourseSchedule> _loadNativeCourses() async {
    final session = context.read<AuthController>().session;
    if (session == null) {
      AppLogger.warn('HomePage: null session');
      if (mounted) context.read<AuthController>().logout();
      throw Exception('登录状态已失效，请重新登录');
    }
    AppLogger.info('HomePage: loading courses');
    final decoded = await context.read<AuthApi>().authenticatedGet('courses', session.idToken);
    final items = decoded['courses'] is List ? decoded['courses'] as List : const [];
    final courses = items.map(NativeCourse.fromJson).whereType<NativeCourse>().toList()..sort(NativeCourse.compare);
    return NativeCourseSchedule.fromCourses(courses);
  }

  void _checkUpdate() {
    final url = AppConfig.apiBaseUrl.replace(path: '${AppConfig.apiBaseUrl.path}/app/version'.replaceAll('//', '/'));
    UpdateDialog.showIfAvailable(context, UpdateService(checkUrl: url));
  }

  String get _todayDayName => const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][DateTime.now().weekday - 1];

  Future<void> _reloadCourses() async {
    final r = _loadNativeCourses();
    if (!mounted) return;
    setState(() => _coursesFuture = r);
    _scrollToToday(await r);
  }

  void _scrollToToday(NativeCourseSchedule s) {
    final rows = s.rowsByWeek[_effectiveWeek(s)]; if (rows == null || rows.isEmpty) return;
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].day == _todayDayName) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) _scrollController.animateTo(i * 96.0, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
        });
        return;
      }
    }
  }

  Future<void> _openImport() async { final r = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const ImportCoursePage())); if (r == true && mounted) await _reloadCourses(); }
  Future<void> _openEdit(NativeCourse course) async { final r = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => EditCoursePage(course: course))); if (r == true && mounted) await _reloadCourses(); }
  Future<void> _openAi() async { await Navigator.of(context).push<void>(MaterialPageRoute(builder: (_) => const AiChatPage())); }
  Future<void> _openAdd() async { final r = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AddCoursePage(defaultWeek: _selectedWeek, defaultDay: _todayDayName))); if (r == true && mounted) await _reloadCourses(); }

  Future<void> _deleteCourse(NativeCourse course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除「${course.course}」吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final session = context.read<AuthController>().session;
      if (session == null || course.id == null) return;
      await context.read<AuthApi>().deleteCourse(course.id!, session.idToken);
      await _reloadCourses();
    } on AuthApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  int _effectiveWeek(NativeCourseSchedule s) {
    if (s.weeks.contains(_selectedWeek)) return _selectedWeek;
    if (s.weeks.isEmpty) return _selectedWeek;
    final nw = AppConfig.detectTeachingWeek();
    return s.weeks.contains(nw) ? nw : s.weeks.first;
  }

  void _showDetail(NativeCourse course) {
    final time = AppConfig.periodTimes[course.period] ?? course.period;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(course.course, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            _D(Icons.calendar_today_outlined, '第${course.week}周  $course.day  $course.period'),
            _D(Icons.access_time, time),
            if (course.room.isNotEmpty) _D(Icons.location_on_outlined, course.room),
            if (course.note.isNotEmpty) _D(Icons.chat_bubble_outline, course.note),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: FilledButton.icon(onPressed: () { Navigator.of(context).pop(); _openEdit(course); }, icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('编辑'))),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.of(context).pop(); _deleteCourse(course); }, icon: const Icon(Icons.delete_outline, size: 18), label: const Text('删除'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444))))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (didPop) return; SystemNavigator.pop(); },
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<NativeCourseSchedule>(
            future: _coursesFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)));
              if (snap.hasError) return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 16),
                      Text(snap.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF6B7280))),
                      const SizedBox(height: 20),
                      OutlinedButton(onPressed: _reloadCourses, child: const Text('重试')),
                    ],
                  ),
                ),
              );
              final sched = snap.data ?? NativeCourseSchedule.empty;
              final ew = _effectiveWeek(sched);
              final rows = sched.rowsByWeek[ew] ?? const <ScheduleRow>[];

              return CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: ActionStrip(selectedWeek: ew, totalCount: sched.coursesByWeek[ew]?.length ?? 0, weeks: sched.weeks, onWeekSelected: (w) { setState(() => _selectedWeek = w); _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); }, onImport: _openImport, onAi: _openAi, onSettings: _openSettings)),
                  if (rows.isEmpty)
                    SliverFillRemaining(child: EmptyState(onImport: _openImport))
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(delegate: SliverChildBuilderDelegate((_, i) {
                        final row = rows[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: row.course != null ? 8.0 : 6.0),
                          child: ScheduleRowTile(row: row, periodTimes: AppConfig.periodTimes, onTap: row.course != null ? () => _showDetail(row.course!) : null),
                        );
                      }, childCount: rows.length)),
                    ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 10, offset: const Offset(0, -2))]),
          padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + MediaQuery.of(context).padding.bottom),
          child: Row(children: [
            NavTab(icon: Icons.add_circle_outline, label: '新增', onTap: _openAdd),
            NavTab(icon: Icons.upload_file_rounded, label: '导入', onTap: _openImport),
            NavTab(icon: Icons.today_rounded, label: '课表', onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut)),
            NavTab(icon: Icons.auto_awesome, label: 'AI', onTap: _openAi),
          ]),
        ),
      ),
    );
  }

  void _openSettings() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            const SizedBox(height: 16),
            _SettingRow('版本', _appVersion),
            _SettingRow('服务器', AppConfig.apiBaseUrl.host),
            const Divider(height: 32, color: Color(0xFFE5E7EB)),
            SizedBox(width: double.infinity, child: OutlinedButton(
              onPressed: () { context.read<AuthController>().logout(); Navigator.of(context).pop(); },
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444))),
              child: const Text('退出登录'),
            )),
          ],
        ),
      ),
    ),
  );
}

class _D extends StatelessWidget {
  const _D(this.icon, this.text);
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Icon(icon, size: 18, color: const Color(0xFF9CA3AF)), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))))]),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.title, this.subtitle);
  final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [Text(title, style: const TextStyle(color: Color(0xFF6B7280))), const Spacer(), Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF1F2937)))]),
  );
}
