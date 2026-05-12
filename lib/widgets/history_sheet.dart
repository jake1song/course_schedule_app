import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/memory_store.dart';

class HistorySheet {
  HistorySheet._();

  static Future<void> show(BuildContext context, MemoryStore store, String currentId, ValueChanged<String> onSelect) async {
    final conversations = await store.listConversations();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.topSheetRadius),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (ctx, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            const Text('历史对话', style: AppTheme.pageTitle),
            const Divider(),
            Expanded(
              child: conversations.isEmpty
                  ? const Center(child: Text('暂无对话记录', style: TextStyle(color: AppTheme.textTertiary)))
                  : ListView.builder(
                      controller: sc,
                      itemCount: conversations.length,
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        final active = c.id == currentId;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primaryStart.withAlpha(15) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: active ? Border.all(color: AppTheme.primaryStart.withAlpha(77), width: 1) : null,
                          ),
                          child: ListTile(
                            selected: active,
                            title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w500, color: active ? AppTheme.primaryStart : AppTheme.textPrimary)),
                            subtitle: Text(_fmt(c.updatedAt ?? c.createdAt), style: AppTheme.tinyText),
                            trailing: active ? const Icon(Icons.check, size: 16, color: AppTheme.primaryStart) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onTap: () { Navigator.of(context).pop(); onSelect(c.id); },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m-$d $h:$min';
  }
}
