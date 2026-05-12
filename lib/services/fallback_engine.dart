import '../config/app_config.dart';
import '../models/native_course.dart';

class FallbackEngine {
  FallbackEngine(this.courses);

  final List<NativeCourse> courses;

  String? answer(String question) {
    final q = question.trim();

    // Today's courses
    if (q.contains('今天') && (q.contains('课') || q.contains('什么'))) return _todayCourses(0);
    if (q.contains('明天') && (q.contains('课') || q.contains('什么'))) return _todayCourses(1);

    // Day-specific
    for (var i = 0; i < NativeCourse.dayNames.length; i++) {
      if (q.contains(NativeCourse.dayNames[i]) && q.contains('课')) return _dayCourses(NativeCourse.dayNames[i]);
    }

    // Free time
    if (q.contains('空') || q.contains('闲')) return _freeTime();
    if (q.contains('有空')) return _freeTime();

    // Stats
    if (q.contains('几节') || q.contains('多少节') || q.contains('共')) return _stats();
    if (q.contains('最忙') || q.contains('最多')) return _busiest();

    // Course search
    for (final c in courses.map((e) => e.course).toSet()) {
      if (q.contains(c)) return _findCourse(c);
    }

    return null; // Can't answer locally
  }

  String _todayCourses(int offset) {
    final now = DateTime.now().add(Duration(days: offset));
    final dayName = AppConfig.dayName((DateTime.now().weekday + offset - 1) % 7 + 1);
    final week = AppConfig.detectTeachingWeek(now);
    final dayCourses = courses.where((c) => c.week == week && c.day == dayName).toList()..sort(NativeCourse.compare);

    if (dayCourses.isEmpty) return '${now.month}月${now.day}日 $dayName · 第${week}周\n\n今天没有课程，好好休息吧！';

    final buf = StringBuffer('${now.month}月${now.day}日 $dayName · 第${week}周\n\n');
    for (final c in dayCourses) {
      final time = AppConfig.periodTimes[c.period] ?? c.period;
      buf.writeln('$c.period  $time');
      buf.writeln('${c.course}');
      if (c.room.isNotEmpty) buf.write('  📍 ${c.room}');
      buf.writeln('\n');
    }
    return buf.toString().trimRight();
  }

  String _dayCourses(String day) {
    final week = AppConfig.detectTeachingWeek(DateTime.now());
    final dayCourses = courses.where((c) => c.week == week && c.day == day).toList()..sort(NativeCourse.compare);

    if (dayCourses.isEmpty) return '$day · 第${week}周\n\n没有课程';

    final buf = StringBuffer('$day · 第${week}周\n\n');
    for (final c in dayCourses) {
      final time = AppConfig.periodTimes[c.period] ?? c.period;
      buf.writeln('$c.period  $time  ${c.course}  ${c.room}');
    }
    return buf.toString().trimRight();
  }

  String _freeTime() {
    final week = AppConfig.detectTeachingWeek(DateTime.now());
    final weekCourses = courses.where((c) => c.week == week).toList();
    const allPeriods = ['第1节', '第2节', '第3节', '第4节', '第5节', '第6节'];
    final buf = StringBuffer('第${week}周空闲时段\n\n');

    for (final day in NativeCourse.dayNames) {
      final busy = weekCourses.where((c) => c.day == day).map((c) => c.period).toSet();
      final free = allPeriods.where((p) => !busy.contains(p)).toList();
      if (free.isEmpty) { buf.writeln('$day：全天满课'); continue; }
      if (free.length == allPeriods.length) { buf.writeln('$day：全天空闲'); continue; }
      buf.write('$day：');
      for (final p in free) { buf.write('$p(${AppConfig.periodTimes[p]}) '); }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  String _stats() {
    final week = AppConfig.detectTeachingWeek(DateTime.now());
    final wk = courses.where((c) => c.week == week).toList();
    if (wk.isEmpty) return '第${week}周暂无课程';
    final names = wk.map((e) => e.course).toSet();
    return '第${week}周共 ${wk.length} 节课，${names.length} 门课程：${names.join('、')}';
  }

  String _busiest() {
    final week = AppConfig.detectTeachingWeek(DateTime.now());
    final wk = courses.where((c) => c.week == week).toList();
    final byDay = <String, int>{};
    for (final c in wk) { byDay[c.day] = (byDay[c.day] ?? 0) + 1; }
    if (byDay.isEmpty) return '本周暂无课程';
    final busiest = byDay.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return '${busiest.key}最忙，有 ${busiest.value} 节课';
  }

  String _findCourse(String courseName) {
    final wk = courses.where((c) => c.course == courseName).toList()..sort(NativeCourse.compare);
    if (wk.isEmpty) return '未找到课程：$courseName';
    final buf = StringBuffer('$courseName\n\n');
    for (final c in wk) {
      buf.writeln('第${c.week}周 $c.day $c.period  ${c.room}');
    }
    return buf.toString().trimRight();
  }

}
