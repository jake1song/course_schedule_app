import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchResult {
  SearchResult._({this.answer = '', this.brief = '', this.full = '', this.status = ''});
  factory SearchResult.empty() => SearchResult._();
  factory SearchResult.unavailable(String msg) => SearchResult._(status: 'unavailable', brief: msg, full: msg);

  final String answer;
  final String brief;
  final String full;
  final String status;
  bool get isEmpty => full.isEmpty;
  bool get isUnavailable => status == 'unavailable';
}

class SearchService {
  SearchService({required this.baseUrl, this.idToken = '', http.Client? client})
    : _client = client ?? http.Client();

  final Uri baseUrl;
  final String idToken;
  final http.Client _client;

  bool needsSearch(String question) {
    // Campus-specific queries — use local course data, skip web search
    final campusQ = [
      '我的课表', '成绩', '选课', '学分', '绩点', '我的课程',
      '今天有', '明天有', '这周', '下周', '几节课', '课表', '空余', '空闲', '统计',
      '今天什么课', '明天什么课', '今天上什么', '明天上什么',
    ];
    if (campusQ.any((k) => question.contains(k))) return false;

    // Trigger web search keywords
    final kw = [
      // 院校 / 教育
      '大学', '院校', '录取线', '录取', '招生', '分数线', '专业', '考研', '高考',
      '报志愿', '报考', '择校', '学位', '硕士', '博士', '研究生', '本科', '专科',
      '就业', '前景', '薪资', '实习', '校招', '社招', '面试', '简历',
      // 知识 / 实时
      '最新', '新闻', '天气', '今天', '现在', '当前', '实时', '查询',
      '考试', '报名', '是什么', '怎么', '如何', '为什么',
      // 数据
      '股价', '汇率', '排名', '多少', '几点', '几号', '日期', '周几', '预报', '政策',
      // 年轻人常用
      '推荐', '有什么', '哪个好', '评价', '经验', '怎么学', '入门', '教程',
      '对比', '区别', '优缺点', '踩坑', '避雷', '值得', '有用吗',
    ];
    return kw.any((k) => question.contains(k));
  }

  Future<SearchResult> search(String query) async {
    try {
      final url = baseUrl.replace(path: '${baseUrl.path}/search'.replaceAll('//', '/'));
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'query': query}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return SearchResult.empty();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'ok';

      if (status == 'unavailable') {
        return SearchResult.unavailable(data['message'] as String? ?? '搜索暂不可用');
      }

      final resultsList = data['results'];
      if (resultsList is! List || resultsList.isEmpty) {
        return SearchResult.empty();
      }

      final answer = (data['answer'] as String?) ?? '';
      final buf = StringBuffer();
      if (answer.isNotEmpty) buf.writeln(answer);
      for (final item in resultsList) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] as String? ?? '';
          final content = item['content'] as String? ?? '';
          final url = item['url'] as String? ?? '';
          if (content.isNotEmpty) {
            buf.writeln('[$title]');
            buf.writeln(content);
            if (url.isNotEmpty) buf.writeln('来源: $url');
            buf.writeln();
          }
        }
      }
      final full = buf.toString().trim();
      return SearchResult._(answer: answer, brief: full, full: full, status: 'ok');
    } catch (_) {
      return SearchResult.empty();
    }
  }
}
