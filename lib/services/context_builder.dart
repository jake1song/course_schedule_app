import '../config/app_config.dart';
import '../models/native_course.dart';

class ContextBuilder {
  ContextBuilder({required this.courses, required this.memories});
  final List<NativeCourse> courses;
  final String memories;

  String build() {
    final now = DateTime.now();
    final week = AppConfig.detectTeachingWeek(now);
    final todayName = AppConfig.dayName(now.weekday);

    final buf = StringBuffer('''
你是课表星图 AI 助手。你有用户全部课程数据的使用权。回答简洁准确，引用数据时标注来源。

[当前时间]
${now.year}年${now.month}月${now.day}日  $todayName  第$week教学周

''');

    // ── 全量课程（按周分组）──
    final byWeek = <int, List<NativeCourse>>{};
    for (final c in courses) {
      (byWeek[c.week] ??= []).add(c);
    }
    final weeks = byWeek.keys.toList()..sort();

    buf.writeln('[全部课程数据 - ${weeks.length} 周，共 ${courses.length} 节课]');

    for (final w in weeks) {
      final wc = byWeek[w]!..sort(NativeCourse.compare);
      final monday = AppConfig.teachingWeekStarts[w];
      final sunday = monday?.add(const Duration(days: 6));
      final range = monday != null ? '  ${monday.month}.${monday.day}-${sunday!.month}.${sunday.day}' : '';
      buf.writeln('\n第$w周$range：');
      for (final c in wc) {
        final time = AppConfig.periodTimes[c.period] ?? c.period;
        buf.write('  $c.day $c.period $time  ${c.course}');
        if (c.room.isNotEmpty) buf.write('  ${c.room}');
        if (c.note.isNotEmpty) buf.write('  $c.note');
        buf.writeln();
      }
    }

    // ── 跨周统计 ──
    buf.writeln('\n[跨周统计]');

    // Course recurrence pattern
    final courseWeeks = <String, List<int>>{};
    for (final c in courses) {
      (courseWeeks[c.course] ??= []).add(c.week);
    }
    buf.writeln('课程规律：');
    for (final entry in courseWeeks.entries) {
      final ws = entry.value..sort();
      if (ws.length == 1) {
        buf.writeln('  ${entry.key}：仅第${ws.first}周');
      } else if (ws.length > 1) {
        buf.writeln('  ${entry.key}：第${ws.join('、')}周（共${ws.length}次）');
      }
    }

    // Busiest day overall
    final dayCount = <String, int>{};
    final weekDay = <String, Set<String>>{};
    for (final c in courses) {
      dayCount[c.day] = (dayCount[c.day] ?? 0) + 1;
      (weekDay[c.course] ??= {}).add(c.day);
    }
    if (dayCount.isNotEmpty) {
      final busiest = dayCount.entries.reduce((a, b) => a.value >= b.value ? a : b);
      buf.writeln('总计 ${courses.length} 节，${courseWeeks.length} 门课。${busiest.key}最多(${busiest.value}节)');
    }

    // This week
    final thisWeek = byWeek[week] ?? [];
    buf.write('本周($todayName)：');
    if (thisWeek.isEmpty) {
      buf.writeln('无课');
    } else {
      buf.write('${thisWeek.length}节 - ');
      for (final d in NativeCourse.dayNames) {
        final dc = thisWeek.where((c) => c.day == d).length;
        if (dc > 0) buf.write('$d ${dc}节  ');
      }
      buf.writeln();
    }

    // Next week
    final nextWeek = byWeek[week + 1];
    if (nextWeek != null) {
      buf.write('下周：${nextWeek.length}节 - ');
      for (final d in NativeCourse.dayNames) {
        final nd = nextWeek.where((c) => c.day == d).length;
        if (nd > 0) buf.write('$d ${nd}节  ');
      }
      buf.writeln();
    }

    // Memories
    if (memories.isNotEmpty) {
      buf.writeln('\n[用户长期记忆]\n$memories');
    }

    buf.writeln('\n[约束]');
    buf.writeln('- 你有完整的课程数据，可以回答任意周的课表问题');
    buf.writeln('- 禁止编造上述数据中不存在的课程名、时间、地点');
    buf.writeln('- 回答日期以"当前时间"为准');
    buf.writeln('- 用中文回答，简洁准确');

    return buf.toString();
  }

}
