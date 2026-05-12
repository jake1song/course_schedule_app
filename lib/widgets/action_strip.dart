import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ActionStrip extends StatelessWidget {
  const ActionStrip({
    required this.selectedWeek, required this.totalCount, required this.weeks,
    required this.onWeekSelected, required this.onImport, required this.onAi,
    required this.onSettings, super.key,
  });

  final int selectedWeek;
  final int totalCount;
  final List<int> weeks;
  final ValueChanged<int> onWeekSelected;
  final VoidCallback onImport;
  final VoidCallback onAi;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final monday = AppConfig.teachingWeekStarts[selectedWeek];
    final sunday = monday?.add(const Duration(days: 6));
    final dateStr = monday != null ? '${monday.month}.${sunday!.month}  ·  ${monday.day} - ${sunday.day}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('第 $selectedWeek 周', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: Color(0xFF1F2937), height: 1.1)),
                    const SizedBox(height: 2),
                    Text(dateStr, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.settings_outlined, onTap: onSettings),
              _IconBtn(icon: Icons.upload_file_rounded, onTap: onImport),
              _IconBtn(icon: Icons.auto_awesome, onTap: onAi),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weeks.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final week = weeks[index];
                final wMon = AppConfig.teachingWeekStarts[week];
                final isSelected = week == selectedWeek;
                return GestureDetector(
                  onTap: () => onWeekSelected(week),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected ? null : Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      wMon != null ? '${wMon.month}.${wMon.day}' : '$week',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF6B7280)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: IconButton(icon: Icon(icon, size: 22, color: const Color(0xFF6B7280)), onPressed: onTap, visualDensity: VisualDensity.compact, splashRadius: 20),
  );
}
