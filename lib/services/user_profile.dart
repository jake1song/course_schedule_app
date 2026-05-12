import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class UserProfileData {
  String nickname;
  String major;
  String grade;
  List<String> interests;
  String goal;
  String responseStyle;
  DateTime updatedAt;

  UserProfileData({
    this.nickname = '',
    this.major = '',
    this.grade = '',
    this.interests = const [],
    this.goal = '',
    this.responseStyle = '口语化',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory UserProfileData.empty() => UserProfileData();

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      nickname: json['nickname'] as String? ?? '',
      major: json['major'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      interests: (json['interests'] as List?)?.cast<String>() ?? [],
      goal: json['goal'] as String? ?? '',
      responseStyle: json['responseStyle'] as String? ?? '口语化',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'major': major,
        'grade': grade,
        'interests': interests,
        'goal': goal,
        'responseStyle': responseStyle,
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isEmpty =>
      nickname.isEmpty && major.isEmpty && grade.isEmpty && interests.isEmpty && goal.isEmpty;

  String toPromptContext() {
    if (isEmpty) return '';
    final buf = StringBuffer('[用户画像]\n');
    if (nickname.isNotEmpty) buf.writeln('称呼：$nickname');
    if (grade.isNotEmpty) buf.writeln('年级：$grade');
    if (major.isNotEmpty) buf.writeln('专业：$major');
    if (interests.isNotEmpty) buf.writeln('兴趣：${interests.join('、')}');
    if (goal.isNotEmpty) buf.writeln('目标：$goal');
    return '$buf\n';
  }
}

class UserProfileService {
  UserProfileService();

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/user_profile.json');
  }

  Future<UserProfileData> load() async {
    try {
      final file = await _file;
      if (!file.existsSync()) return UserProfileData.empty();
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfileData.fromJson(json);
    } catch (_) {
      return UserProfileData.empty();
    }
  }

  Future<void> save(UserProfileData data) async {
    data.updatedAt = DateTime.now();
    final file = await _file;
    await file.writeAsString(jsonEncode(data.toJson()));
  }
}
