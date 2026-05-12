import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 2),
        child: Row(
          children: [
            Container(width: 3, height: 14, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), borderRadius: BorderRadius.all(Radius.circular(2)))),
            const SizedBox(width: 10),
            Text(row.day, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
            const Spacer(),
            Text(row.count == 0 ? '休息' : '${row.count} 节', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    final time = periodTimes[course.period] ?? course.period;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: const Color(0x0A000000), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(course.period.replaceAll('第', '').replaceAll('节', ''), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0066FF))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(course.course, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(time, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        if (course.room.isNotEmpty) ...[
                          Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                          Flexible(child: Text(course.room, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ],
                        if (course.note.isNotEmpty) ...[
                          Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6), decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                          Flexible(child: Text(course.note, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
    );
  }
}
