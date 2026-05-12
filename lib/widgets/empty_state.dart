import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({required this.onImport, super.key});
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.today_rounded, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text('当前没有课程', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        const Text('点击导入，粘贴教务系统或表格文本', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary)),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
          child: FilledButton.icon(
            onPressed: onImport,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('导入课表'),
            style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius))),
          ),
        ),
      ],
    ),
  );
}
