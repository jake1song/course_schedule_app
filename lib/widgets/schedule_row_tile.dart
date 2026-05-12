import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/native_course.dart';

class ScheduleRowTile extends StatelessWidget {
  const ScheduleRowTile({required this.row, required this.periodTimes, this.onTap, super.key});

  final ScheduleRow row;
  final Map<String, String> periodTimes;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final course = row.course;
    if (course == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
        child: Row(
          children: [
            Container(width: 3, height: 12, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), borderRadius: BorderRadius.all(Radius.circular(2)))),
            const SizedBox(width: 10),
            Text(row.day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
            const Spacer(),
            Text(row.count == 0 ? '休息' : '${row.count} 节', style: AppTheme.tinyText),
          ],
        ),
      );
    }

    final time = periodTimes[course.period] ?? course.period;
    final accent = AppTheme.periodColor(course.period);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppTheme.cardBorderRadius,
          boxShadow: const [AppTheme.cardShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left color strip
              Container(width: 4, color: accent),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Row(
                    children: [
                      // Period badge
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [accent.withAlpha(40), accent.withAlpha(20)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          course.period.replaceAll('第', '').replaceAll('节', ''),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accent),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(course.course, style: AppTheme.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(time, style: AppTheme.captionText),
                                if (course.room.isNotEmpty) ...[
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                                  Flexible(child: Text(course.room, style: AppTheme.captionText, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                                if (course.note.isNotEmpty) ...[
                                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                                  Flexible(child: Text(course.note, style: AppTheme.tinyText, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null) const Icon(Icons.chevron_right, size: 18, color: Color(0xFFE5E7EB)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
