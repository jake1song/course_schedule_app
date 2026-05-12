import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({required this.onImport, super.key});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.today_rounded, size: 52, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 14),
        Text('当前没有课程', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF1F2937))),
        const SizedBox(height: 8),
        const Text('点击导入，粘贴教务系统或表格文本', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF9CA3AF))),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onImport, icon: const Icon(Icons.upload_file_rounded), label: const Text('导入课表')),
      ],
    ),
  );
}
