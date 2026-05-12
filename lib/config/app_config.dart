import 'dart:convert';

class AppConfig {
  static final Uri apiBaseUrl = Uri.parse(
    const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://szk333333.fun/api'),
  );
  static final Uri webBaseUrl = Uri.parse(
    const String.fromEnvironment('WEB_BASE_URL', defaultValue: 'https://szk333333.fun/'),
  );

  static bool get enableHardwareAcceleration =>
      const String.fromEnvironment('HW_ACCEL', defaultValue: 'true') == 'true';

  static bool get performanceMode =>
      const String.fromEnvironment('PERF_MODE', defaultValue: 'false') == 'true';

  static Map<int, DateTime> get teachingWeekStarts {
    final raw = const String.fromEnvironment('TEACHING_WEEK_STARTS');
    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final parsed = <int, DateTime>{};
        for (final entry in decoded.entries) {
          final week = int.parse(entry.key);
          parsed[week] = DateTime.parse(entry.value as String);
        }
        return parsed;
      } catch (_) {}
    }
    return {
      9: DateTime(2026, 4, 27),
      10: DateTime(2026, 5, 4),
      11: DateTime(2026, 5, 11),
      12: DateTime(2026, 5, 18),
      13: DateTime(2026, 5, 25),
      14: DateTime(2026, 6, 1),
    };
  }

  static const Map<String, String> periodTimes = {
    '第1节': '08:00-09:40', '第2节': '10:00-11:40',
    '第3节': '14:00-15:40', '第4节': '16:00-17:40',
    '第5节': '19:00-20:40', '第6节': '20:50-22:30',
  };

  static int detectTeachingWeek([DateTime? date]) {
    final today = date ?? DateTime.now();
    final sorted = teachingWeekStarts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    for (final e in sorted.reversed) {
      if (!today.isBefore(e.value)) return e.key;
    }
    return sorted.isNotEmpty ? sorted.first.key : 1;
  }

  static String dayName(int weekday) =>
      const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][weekday - 1];

  static String weekDateRange(int week) {
    final monday = teachingWeekStarts[week];
    if (monday == null) return '第 $week 周';
    final sunday = monday.add(const Duration(days: 6));
    String fmt(DateTime d) => '${d.month}/${d.day}';
    return '第 $week 周 (${fmt(monday)}-${fmt(sunday)})';
  }
}
