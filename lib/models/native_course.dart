class NativeCourse {
  const NativeCourse({
    this.id,
    required this.week,
    required this.day,
    required this.period,
    required this.course,
    required this.room,
    required this.note,
  });

  final String? id;
  final int week;
  final String day;
  final String period;
  final String course;
  final String room;
  final String note;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'week': week,
        'day': day,
        'period': period,
        'course': course,
        'room': room,
        'note': note,
      };

  static NativeCourse? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = _stringValue(value['id']);
    final week = _parseInt(value['week']);
    final day = _stringValue(value['day']);
    final period = _stringValue(value['period']);
    final course = _stringValue(
      value['course'] ?? value['courseName'] ?? value['name'],
    );
    if (week == null || day.isEmpty || period.isEmpty || course.isEmpty) {
      return null;
    }
    return NativeCourse(
      id: id.isNotEmpty ? id : null,
      week: week,
      day: day,
      period: period,
      course: course,
      room: _stringValue(value['room']),
      note: _stringValue(value['note']),
    );
  }

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_stringValue(value));
  }

  static String _stringValue(Object? value) => (value ?? '').toString().trim();

  static const List<String> dayNames = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];

  static int compare(NativeCourse a, NativeCourse b) {
    final week = a.week.compareTo(b.week);
    if (week != 0) return week;
    final day = _dayOrder(a.day).compareTo(_dayOrder(b.day));
    if (day != 0) return day;
    return _periodOrder(a.period).compareTo(_periodOrder(b.period));
  }

  static int _dayOrder(String day) {
    final index = dayNames.indexOf(day);
    return index < 0 ? 99 : index;
  }

  static int _periodOrder(String period) {
    final match = RegExp(r'\d+').firstMatch(period);
    return match == null ? 99 : int.parse(match.group(0)!);
  }
}

class ScheduleRow {
  const ScheduleRow.day(this.day, this.count) : course = null;
  const ScheduleRow.course(this.course) : day = '', count = 0;

  final String day;
  final int count;
  final NativeCourse? course;
}

class NativeCourseSchedule {
  const NativeCourseSchedule({
    required this.weeks,
    required this.coursesByWeek,
    required this.rowsByWeek,
  });

  static const empty = NativeCourseSchedule(
    weeks: <int>[],
    coursesByWeek: <int, List<NativeCourse>>{},
    rowsByWeek: <int, List<ScheduleRow>>{},
  );

  final List<int> weeks;
  final Map<int, List<NativeCourse>> coursesByWeek;
  final Map<int, List<ScheduleRow>> rowsByWeek;

  factory NativeCourseSchedule.fromCourses(List<NativeCourse> courses) {
    final coursesByWeek = <int, List<NativeCourse>>{};
    for (final course in courses) {
      (coursesByWeek[course.week] ??= <NativeCourse>[]).add(course);
    }
    final weeks = coursesByWeek.keys.toList()..sort();
    final rowsByWeek = <int, List<ScheduleRow>>{
      for (final week in weeks) week: _rowsFor(coursesByWeek[week]!),
    };
    return NativeCourseSchedule(
      weeks: List<int>.unmodifiable(weeks),
      coursesByWeek: Map<int, List<NativeCourse>>.unmodifiable({
        for (final entry in coursesByWeek.entries)
          entry.key: List<NativeCourse>.unmodifiable(entry.value),
      }),
      rowsByWeek: Map<int, List<ScheduleRow>>.unmodifiable({
        for (final entry in rowsByWeek.entries)
          entry.key: List<ScheduleRow>.unmodifiable(entry.value),
      }),
    );
  }

  static List<ScheduleRow> _rowsFor(List<NativeCourse> courses) {
    final rows = <ScheduleRow>[];
    for (final day in NativeCourse.dayNames) {
      final dayCourses = courses.where((item) => item.day == day).toList();
      rows.add(ScheduleRow.day(day, dayCourses.length));
      for (final course in dayCourses) {
        rows.add(ScheduleRow.course(course));
      }
    }
    return rows;
  }
}
