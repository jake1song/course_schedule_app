import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/user_profile.dart';

class ProfileEditorSheet {
  ProfileEditorSheet._();

  static void show(BuildContext context, UserProfileData profile, UserProfileService service, VoidCallback onDone) {
    final nickCtrl = TextEditingController(text: profile.nickname);
    final majorCtrl = TextEditingController(text: profile.major);
    final gradeCtrl = TextEditingController(text: profile.grade);
    final interestCtrl = TextEditingController(text: profile.interests.join('、'));
    final goalCtrl = TextEditingController(text: profile.goal);
    String style = profile.responseStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: AppTheme.topSheetRadius),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
          builder: (ctx, sc) => SingleChildScrollView(
            controller: sc,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(ctx).padding.bottom),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('个人画像', style: AppTheme.pageTitle),
              const SizedBox(height: 4),
              const Text('让我更了解你，回复会更贴心', style: TextStyle(fontSize: 13, color: AppTheme.textTertiary)),
              const SizedBox(height: 20),
              TextField(controller: nickCtrl, decoration: const InputDecoration(labelText: '称呼', hintText: '例如：小明')),
              const SizedBox(height: 12),
              TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: '年级', hintText: '例如：大二')),
              const SizedBox(height: 12),
              TextField(controller: majorCtrl, decoration: const InputDecoration(labelText: '专业', hintText: '例如：计算机科学')),
              const SizedBox(height: 12),
              TextField(controller: interestCtrl, decoration: const InputDecoration(labelText: '兴趣', hintText: '用顿号分隔，例如：编程、摄影、篮球')),
              const SizedBox(height: 12),
              TextField(controller: goalCtrl, decoration: const InputDecoration(labelText: '目标', hintText: '例如：考研、就业、留学')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: style,
                decoration: const InputDecoration(labelText: '回复风格'),
                items: const [
                  DropdownMenuItem(value: '口语化', child: Text('口语化 — 像朋友聊天')),
                  DropdownMenuItem(value: '简洁', child: Text('简洁 — 言简意赅')),
                  DropdownMenuItem(value: '详细', child: Text('详细 — 充分展开')),
                  DropdownMenuItem(value: '幽默', child: Text('幽默 — 轻松风趣')),
                ],
                onChanged: (v) { if (v != null) { style = v; setSheetState(() {}); } },
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(AppTheme.smallRadius)),
                child: FilledButton(
                  onPressed: () async {
                    final updated = UserProfileData(
                      nickname: nickCtrl.text.trim(), major: majorCtrl.text.trim(),
                      grade: gradeCtrl.text.trim(),
                      interests: interestCtrl.text.split('、').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                      goal: goalCtrl.text.trim(), responseStyle: style,
                    );
                    await service.save(updated);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    onDone();
                  },
                  style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.smallRadius))),
                  child: const Text('保存画像'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
