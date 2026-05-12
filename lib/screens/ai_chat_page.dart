import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../models/native_course.dart';
import '../services/ai_key_store.dart';
import '../services/ai_service.dart';
import '../services/context_builder.dart';
import '../services/fallback_engine.dart';
import '../services/memory_store.dart';
import '../services/search_service.dart';
import '../services/user_profile.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});
  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _keyStore = AiKeyStore();
  final _store = MemoryStore();
  final _profileService = UserProfileService();
  late SearchService _search;
  AiService? _aiService;
  final _messages = <_ChatMessage>[];
  bool _loading = false;
  bool _forceSearch = false;
  String _conversationId = '';
  bool _hadKey = false;
  List<NativeCourse> _allCourses = const [];
  String _context = '';
  FallbackEngine? _fallback;
  UserProfileData _profile = UserProfileData.empty();

  @override
  void initState() {
    super.initState();
    _initKey();
  }

  void _setupSearch() {
    final session = context.read<AuthController>().session;
    _search = SearchService(baseUrl: AppConfig.apiBaseUrl, idToken: session?.idToken ?? '');
  }

  Future<void> _initKey() async {
    final key = await _keyStore.readKey();
    if (key.isNotEmpty) {
      _hadKey = true;
      final url = await _keyStore.readUrl();
      final model = await _keyStore.readModel();
      if (mounted) {
        setState(() => _aiService = AiService(apiKey: key, baseUrl: url, model: model));
        _setupSearch();
        _profile = await _profileService.load();
        await _loadCourses();
        await _startNewConversation();
      }
    }
  }

  Future<void> _saveKey(String key) async {
    _hadKey = true;
    await _keyStore.saveKey(key.trim());
    final url = await _keyStore.readUrl();
    final model = await _keyStore.readModel();
    if (mounted) {
      setState(() => _aiService = AiService(apiKey: key.trim(), baseUrl: url, model: model));
      _setupSearch();
      await _loadCourses();
      await _startNewConversation();
    }
  }

  Future<void> _loadCourses() async {
    try {
      final session = context.read<AuthController>().session;
      if (session == null) return;
      final decoded = await context.read<AuthApi>().authenticatedGet('courses', session.idToken);
      final items = decoded['courses'] is List ? decoded['courses'] as List : const [];
      final courses = items.map(NativeCourse.fromJson).whereType<NativeCourse>().toList()..sort(NativeCourse.compare);
      if (mounted) {
        setState(() {
          _allCourses = courses;
          _fallback = FallbackEngine(courses);
          _rebuildContext();
        });
      }
    } catch (_) { /* non-critical, continue without courses */ }
  }

  void _rebuildContext() {
    _context = ContextBuilder(courses: _allCourses, memories: '').build();
  }

  Future<void> _startNewConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _conversationId = id;
    await _store.saveConversation(ConversationData(id: id, title: '新对话', createdAt: DateTime.now()));
    if (mounted) setState(() => _messages.clear());
  }

  Future<void> _loadConversation(String id) async {
    _conversationId = id;
    final msgs = await _store.loadMessages(id);
    if (mounted) { setState(() { _messages.clear(); for (final m in msgs) { _messages.add(_ChatMessage(role: m.role, content: m.content)); }}); }
  }

  String _buildContext(String searchCtx) {
    final buf = StringBuffer();

    // Priority 1: User profile (highest)
    final profileCtx = _profile.toPromptContext();
    if (profileCtx.isNotEmpty) buf.write(profileCtx);

    // Priority 2: Course data + search results
    buf.write(_context);
    if (searchCtx.isNotEmpty) buf.write(searchCtx);

    // Style constraints at end (model pays high attention to end of prompt)
    buf.writeln('[对话约束]');
    buf.writeln('- 用口语化、自然的方式回答，像朋友聊天');
    buf.writeln('- 用户画像中有信息优先结合，让回复有针对性');
    buf.writeln('- 避免生硬列表格式，用自然段落表达');
    buf.writeln('- 回答精简，控制在200字左右');
    return buf.toString();
  }

  List<_ChatMessage> _recentHistory() {
    final relevant = _messages
        .where((m) => m.role == 'user' || m.role == 'assistant')
        .toList();
    if (relevant.isEmpty) return [];
    // Exclude the last user message (current question), keep previous 3 turns (6 msgs)
    final history = relevant.length > 1 ? relevant.sublist(0, relevant.length - 1) : <_ChatMessage>[];
    return history.length > 6 ? history.sublist(history.length - 6) : history;
  }

  Future<void> _send({String? overrideText}) async {
    final text = (overrideText ?? _inputController.text).trim();
    if (text.isEmpty || _loading || _aiService == null) return;
    if (overrideText == null) _inputController.clear();

    if (_messages.isEmpty && text.isNotEmpty) {
      final title = text.length > 20 ? '${text.substring(0, 20)}...' : text;
      await _store.updateTitle(_conversationId, title);
    }

    final userMsg = _ChatMessage(role: 'user', content: text);
    setState(() { _messages.add(userMsg); _loading = true; });
    _scrollToBottom();

    await _store.saveMessage(MessageData(id: '${_conversationId}_${_messages.length}_u', conversationId: _conversationId, role: 'user', content: text, createdAt: DateTime.now()));

    try {
      // Web search if needed
      String searchCtx = '';
      if (_forceSearch || _search.needsSearch(text)) {
        final result = await _search.search(text);
        if (result.isUnavailable) {
          searchCtx = '\n\n[搜索状态] 联网搜索暂不可用（服务器网络限制），请基于已有课程数据回答。如实告知用户无法获取实时信息。';
          if (mounted) setState(() => _messages.add(const _ChatMessage(role: 'system', content: '联网搜索暂不可用，AI 助手将基于已有知识回答')));
        } else if (!result.isEmpty) {
          searchCtx = '\n\n[网络搜索结果]\n${result.full}\n\n请基于以上网络搜索结果和课程数据回答。若用户询问院校公开信息，请用口语化方式整合搜索结果，不要调用内部数据，避免使用列表格式。';
          if (mounted) setState(() => _messages.add(const _ChatMessage(role: 'system', content: '已获取网络搜索结果')));
        }
      }

      // Build prompt with priority: profile > course/search > history
      final systemCtx = _buildContext(searchCtx);
      final history = _recentHistory();

      final allMessages = <Map<String, String>>[
        {'role': 'system', 'content': systemCtx},
        for (final m in history) {'role': m.role, 'content': m.content},
        {'role': 'user', 'content': text},
      ];
      final reply = await _aiService!.chatRaw(allMessages, temperature: 0.65, maxTokens: 1024, frequencyPenalty: 0.3, presencePenalty: 0.2);
      if (mounted) _addReply(reply);
    } on AiServiceException catch (_) {
      // AI API failed, try fallback engine
      final local = _fallback?.answer(text);
      if (local != null && mounted) {
        _addReply('（AI 服务暂时不可用，以下是本地回答）\n\n$local');
      } else if (mounted) {
        setState(() { _messages.add(const _ChatMessage(role: 'system', content: 'AI 服务不可用，请稍后重试')); _loading = false; });
      }
    } catch (_) {
      final local = _fallback?.answer(text);
      if (local != null && mounted) {
        _addReply('（离线模式）\n\n$local');
      } else if (mounted) {
        setState(() { _messages.add(const _ChatMessage(role: 'system', content: '连接失败，请稍后重试')); _loading = false; });
      }
    }
    _scrollToBottom();
  }

  void _addReply(String reply) {
    if (!mounted) return;
    final aiMsg = _ChatMessage(role: 'assistant', content: reply);
    setState(() { _messages.add(aiMsg); _loading = false; });
    _store.saveMessage(MessageData(id: '${_conversationId}_${_messages.length}_a', conversationId: _conversationId, role: 'assistant', content: reply, createdAt: DateTime.now()));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() { _inputController.dispose(); _scrollController.dispose(); super.dispose(); }

  bool _hasStoredKey() => _hadKey;

  void _showKeyDialog() => showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('API Key'), content: const Text('已配置 API Key，可以更换或清除。'),
    actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('取消')), TextButton(onPressed: () { Navigator.of(ctx).pop(); _changeKey(); }, child: const Text('更换 Key')), FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)), onPressed: () async { Navigator.of(ctx).pop(); await _keyStore.clear(); if (mounted) setState(() { _aiService = null; _messages.clear(); }); }, child: const Text('清除 Key'))],
  ));

  void _changeKey() { if (mounted) setState(() { _aiService = null; _messages.clear(); }); }

  void _showProfileEditor() {
    final nickCtrl = TextEditingController(text: _profile.nickname);
    final majorCtrl = TextEditingController(text: _profile.major);
    final gradeCtrl = TextEditingController(text: _profile.grade);
    final interestCtrl = TextEditingController(text: _profile.interests.join('、'));
    final goalCtrl = TextEditingController(text: _profile.goal);
    String style = _profile.responseStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (ctx, sc) => SingleChildScrollView(
          controller: sc,
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.of(ctx).padding.bottom),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('个人画像', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            const Text('让我更了解你，回复会更贴心', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
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
              decoration: const InputDecoration(labelText: '回复风格', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: '口语化', child: Text('口语化 — 像朋友聊天')),
                DropdownMenuItem(value: '简洁', child: Text('简洁 — 言简意赅')),
                DropdownMenuItem(value: '详细', child: Text('详细 — 充分展开')),
                DropdownMenuItem(value: '幽默', child: Text('幽默 — 轻松风趣')),
              ],
              onChanged: (v) { if (v != null) style = v; },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                _profile = UserProfileData(
                  nickname: nickCtrl.text.trim(),
                  major: majorCtrl.text.trim(),
                  grade: gradeCtrl.text.trim(),
                  interests: interestCtrl.text.split('、').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  goal: goalCtrl.text.trim(),
                  responseStyle: style,
                );
                await _profileService.save(_profile);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  setState(() {});
                  _messages.add(const _ChatMessage(role: 'system', content: '画像已更新，我会更好地了解你'));
                }
              },
              child: const Text('保存画像'),
            ),
          ]),
        ),
      ),
    );
  }

  void _openHistory() async {
    final conversations = await _store.listConversations();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (ctx, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            const Text('历史对话', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1F2937))),
            const Divider(),
            Expanded(
              child: conversations.isEmpty
                  ? const Center(child: Text('暂无对话记录', style: TextStyle(color: Color(0xFF9CA3AF))))
                  : ListView.builder(
                      controller: sc,
                      itemCount: conversations.length,
                      itemBuilder: (_, i) {
                        final c = conversations[i];
                        final active = c.id == _conversationId;
                        return ListTile(
                          selected: active,
                          title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(_fmt(c.updatedAt ?? c.createdAt), style: const TextStyle(fontSize: 12)),
                          trailing: active ? const Icon(Icons.check, size: 16, color: Color(0xFF0066FF)) : null,
                          onTap: () { Navigator.of(context).pop(); _loadConversation(c.id); },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 日程助手'),
        actions: [
          if (_aiService != null) ...[IconButton(icon: Icon(_forceSearch ? Icons.travel_explore : Icons.travel_explore_outlined, color: _forceSearch ? const Color(0xFF0066FF) : null), tooltip: _forceSearch ? '已开启强制联网搜索' : '强制联网搜索（关闭）', onPressed: () => setState(() => _forceSearch = !_forceSearch)), IconButton(icon: const Icon(Icons.person_outline), tooltip: '个人画像', onPressed: _showProfileEditor), IconButton(icon: const Icon(Icons.history), tooltip: '历史对话', onPressed: _openHistory), IconButton(icon: const Icon(Icons.add_comment), tooltip: '新对话', onPressed: _startNewConversation), IconButton(icon: const Icon(Icons.vpn_key), tooltip: '管理 API Key', onPressed: _showKeyDialog)],
        ],
      ),
      body: SafeArea(child: _aiService != null ? _buildChat() : _KeyInputPage(onSave: _saveKey, onCancel: _hasStoredKey() ? () => _initKey() : null)),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        // Quick prompts
        if (_messages.isEmpty) Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _QuickChip('今天课表', '今天有什么课？'),
            _QuickChip('明天课表', '明天有什么课？'),
            _QuickChip('本周空余', '我这周什么时候有空？'),
            _QuickChip('课程统计', '这周共几节课？'),
          ]),
        ),
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyChat()
              : ListView.builder(controller: _scrollController, padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), itemCount: _messages.length, itemBuilder: (_, i) => _Bubble(msg: _messages[i])),
        ),
        if (_loading) const LinearProgressIndicator(color: Color(0xFF0066FF)),
        Container(
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE5E7EB)))),
          padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
          child: Row(children: [
            Expanded(child: TextField(controller: _inputController, decoration: const InputDecoration(hintText: '输入问题...', border: OutlineInputBorder()), minLines: 1, maxLines: 4, onSubmitted: (_) => _send())),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: _loading ? null : () => _send(), icon: const Icon(Icons.send)),
          ]),
        ),
      ],
    );
  }

  Widget _QuickChip(String label, String query) => ActionChip(
    label: Text(label, style: const TextStyle(fontSize: 13)),
    onPressed: () => _send(overrideText: query),
    backgroundColor: const Color(0xFFE8F0FE),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _ChatMessage msg;
  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    final isSys = msg.role == 'system';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start, children: [
        if (!isUser) ...[CircleAvatar(radius: 14, backgroundColor: isSys ? const Color(0xFFFEF3C7) : null, child: Icon(isSys ? Icons.memory : Icons.auto_awesome, size: 16)), const SizedBox(width: 8)],
        Flexible(child: Container(padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72), decoration: BoxDecoration(color: isUser ? const Color(0xFF0066FF) : (isSys ? const Color(0xFFFEF9C3) : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(12)), child: Text(msg.content, style: TextStyle(color: isUser ? Colors.white : const Color(0xFF1F2937))))),
      ]),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 48, color: Color(0xFF9CA3AF)),
        SizedBox(height: 12),
        Text('询问 AI 关于课程安排的建议', style: TextStyle(color: Color(0xFF9CA3AF))),
        SizedBox(height: 4),
        Text('点击上方快捷提问或输入问题', style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
      ],
    ),
  );
}

class _ChatMessage { const _ChatMessage({required this.role, required this.content}); final String role; final String content; }

class _KeyInputPage extends StatefulWidget {
  const _KeyInputPage({required this.onSave, this.onCancel});
  final ValueChanged<String> onSave;
  final VoidCallback? onCancel;
  @override
  State<_KeyInputPage> createState() => _KeyInputPageState();
}

class _KeyInputPageState extends State<_KeyInputPage> {
  final _ctrl = TextEditingController();
  String? _error;
  String _model = 'deepseek-chat';

  static const _models = [
    'deepseek-chat',
    'deepseek-reasoner',
    'gpt-4o',
    'gpt-4o-mini',
    'gpt-3.5-turbo',
    'claude-3.5-sonnet',
    'qwen-plus',
    'glm-4',
  ];

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submit() {
    final key = _ctrl.text.trim();
    if (key.isEmpty) { setState(() => _error = '请输入 API Key'); return; }
    if (!key.startsWith('sk-')) { setState(() => _error = 'Key 格式不正确，应以 sk- 开头'); return; }
    AiKeyStore().saveModel(_model);
    widget.onSave(key);
  }

  @override
  Widget build(BuildContext context) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 420), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.vpn_key, size: 48, color: Color(0xFF9CA3AF)), const SizedBox(height: 16),
    const Text('配置 AI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)), textAlign: TextAlign.center),
    const SizedBox(height: 8),
    const Text('Key 加密存储在本地', style: TextStyle(color: Color(0xFF6B7280)), textAlign: TextAlign.center),
    const SizedBox(height: 24),
    TextField(controller: _ctrl, decoration: InputDecoration(labelText: 'API Key', hintText: 'sk-...', border: const OutlineInputBorder(), errorText: _error), onSubmitted: (_) => _submit()),
    const SizedBox(height: 16),
    DropdownButtonFormField<String>(
      value: _model,
      decoration: const InputDecoration(labelText: '模型', border: OutlineInputBorder(), prefixIcon: Icon(Icons.smart_toy_outlined, color: Color(0xFF9CA3AF))),
      items: _models.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: (v) { if (v != null) setState(() => _model = v); },
    ),
    const SizedBox(height: 20),
    FilledButton(onPressed: _submit, child: const Text('保存并开始使用')),
    if (widget.onCancel != null) ...[const SizedBox(height: 8), TextButton(onPressed: widget.onCancel, child: const Text('返回'))],
  ]))));
}
