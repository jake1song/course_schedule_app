import 'package:flutter/material.dart';

class WeekNumberField extends StatelessWidget {
  const WeekNumberField({required this.value, required this.onChanged, super.key});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: TextEditingController(text: '$value'),
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(labelText: '周次'),
    onChanged: (v) {
      final n = int.tryParse(v);
      if (n != null && n >= 1 && n <= 30) onChanged(n);
    },
  );
}

class DayDropdown extends StatelessWidget {
  const DayDropdown({required this.value, required this.onChanged, super.key});
  final String value;
  final ValueChanged<String?> onChanged;

  static const items = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : items.first,
    decoration: const InputDecoration(labelText: '星期'),
    items: items.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
    onChanged: onChanged,
  );
}

class PeriodDropdown extends StatelessWidget {
  const PeriodDropdown({required this.value, required this.onChanged, super.key});
  final String value;
  final ValueChanged<String?> onChanged;

  static const items = ['第1节', '第2节', '第3节', '第4节', '第5节', '第6节'];

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    value: items.contains(value) ? value : items.first,
    decoration: const InputDecoration(labelText: '节次'),
    items: items.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
    onChanged: onChanged,
  );
}
