import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class NavTab extends StatelessWidget {
  const NavTab({required this.icon, required this.label, required this.onTap, super.key});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppTheme.textSecondary),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    ),
  );
}
