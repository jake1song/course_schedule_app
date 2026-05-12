import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/native_course.dart';
import '../services/ai_key_store.dart';
import '../services/ai_service.dart';
import '../services/context_builder.dart';
import '../services/fallback_engine.dart';
import '../services/memory_store.dart';
import '../services/search_service.dart';
import '../services/user_profile.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/history_sheet.dart';
import '../widgets/key_input_page.dart';
import '../widgets/profile_editor.dart';

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
  final _messages = <_ChatMsg>[];
  bool _loading = false;
  bool _forceSearch = false;
  String _conversationId = '';
  bool _hadKey = false;
  List<NativeCourse> _allCourses = const [];
  String _context = '';
  FallbackEngine? _fallback;
  UserProfileData _profile = UserProfileData.empty();

  @override
  void initState() { super.initState(); _initKey(); }

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
    } catch (_) {}
  }

  void _rebuildContext() { _context = ContextBuilder(courses: _allCourses, memories: '').build(); }

  Future<void> _startNewConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _conversationId = id;
    await _store.saveConversation(ConversationData(id: id, title: '新对话', createdAt: DateTime.now()));
    if (mounted) setState(() => _messages.clear());
  }

  Future<void> _loadConversation(String id) async {
    _conversationId = id;
    final msgs = await _store.loadMessages(id);
    if (mounted) {
      setState(() {
        _messages.clear();
        for (final m in msgs) { _messages.add(_ChatMsg(role: m.role, content: m.content)); }
      });
    }
  }

  String _buildContext(String searchCtx) {
    final buf = StringBuffer();
    final profileCtx = _profile.toPromptContext();
    if (profileCtx.isNotEmpty) buf.write(profileCtx);
    buf.write(_context);
    if (searchCtx.isNotEmpty) buf.write(searchCtx);
    buf.writeln('[对话约束]');
    buf.writeln('- 用口语化、自然的方式回答，像朋友聊天');
    buf.writeln('- 避免生硬列表格式，用自然段落表达');
    buf.writeln('- 回答精简，控制在200字左右');
    return buf.toString();
  }

  List<_ChatMsg> _recentHistory() {
    final relevant = _messages.where((m) => m.role == 'user' || m.role == 'assistant').toList();
    if (relevant.isEmpty) return [];
    final history = relevant.length > 1 ? relevant.sublist(0, relevant.length - 1) : <_ChatMsg>[];
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

    final userMsg = _ChatMsg(role: 'user', content: text);
    setState(() { _messages.add(userMsg); _loading = true; });
    _scrollToBottom();

    await _store.saveMessage(MessageData(id: '${_conversationId}_${_messages.length}_u', conversationId: _conversationId, role: 'user', content: text, createdAt: DateTime.now()));

    try {
      String searchCtx = '';
      if (_forceSearch || _search.needsSearch(text)) {
        final result = await _search.search(text);
        if (result.isUnavailable) {
          searchCtx = '\n\n[搜索状态] 联网搜索暂不可用，请基于已有课程数据回答。';
          if (mounted) _addSystemMsg('联网搜索暂不可用，AI 助手将基于已有知识回答');
        } else if (!result.isEmpty) {
          searchCtx = '\n\n[网络搜索结果]\n${result.full}\n\n请整合搜索结果和课程数据回答，口语化，不使用列表格式。';
          if (mounted) _addSystemMsg('已获取网络搜索结果');
        }
      }
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
      final local = _fallback?.answer(text);
      if (local != null && mounted) {
        _addReply('（AI 服务暂时不可用，以下是本地回答）\n\n$local');
      } else if (mounted) {
        _addSystemMsg('AI 服务不可用，请稍后重试');
        setState(() => _loading = false);
      }
    } catch (_) {
      final local = _fallback?.answer(text);
      if (local != null && mounted) {
        _addReply('（离线模式）\n\n$local');
      } else if (mounted) {
        _addSystemMsg('连接失败，请稍后重试');
        setState(() => _loading = false);
      }
    }
    _scrollToBottom();
  }

  void _addSystemMsg(String content) => setState(() => _messages.add(_ChatMsg(role: 'system', content: content)));
  void _addReply(String reply) {
    if (!mounted) return;
    setState(() { _messages.add(_ChatMsg(role: 'assistant', content: reply)); _loading = false; });
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: _aiService != null ? _buildChat() : KeyInputPage(onSave: _saveKey, onCancel: _hasStoredKey() ? () => _initKey() : null),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Column(
      children: [
        // Header bar
        Container(
          padding: EdgeInsets.fromLTRB(8, 4, 4, 0),
          child: Row(
            children: [
              const SizedBox(width: 4),
              Expanded(child: const Text('AI 日程助手', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white))),
              // Force search toggle
              _BarIcon(
                icon: _forceSearch ? Icons.travel_explore : Icons.travel_explore_outlined,
                active: _forceSearch,
                tooltip: _forceSearch ? '已开启强制联网搜索' : '强制联网搜索',
                onTap: () => setState(() => _forceSearch = !_forceSearch),
              ),
              _BarIcon(icon: Icons.person_outline, tooltip: '个人画像', onTap: () => ProfileEditorSheet.show(context, _profile, _profileService, () { if (mounted) { setState(() {}); _addSystemMsg('画像已更新'); } })),
              _BarIcon(icon: Icons.history, tooltip: '历史对话', onTap: () => HistorySheet.show(context, _store, _conversationId, _loadConversation)),
              _BarIcon(icon: Icons.add_comment, tooltip: '新对话', onTap: _startNewConversation),
              _BarIcon(icon: Icons.vpn_key, tooltip: '管理 API Key', onTap: _showKeyDialog),
            ],
          ),
        ),
        // Quick prompts
        if (_messages.isEmpty) _buildQuickPrompts(),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? const _EmptyState()
              : ListView.builder(controller: _scrollController, padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), itemCount: _messages.length, itemBuilder: (_, i) {
                  final m = _messages[i];
                  return ChatBubble(content: m.content, style: m.role == 'user' ? BubbleStyle.user : m.role == 'system' ? BubbleStyle.system : BubbleStyle.ai);
                }),
        ),
        if (_loading) const LinearProgressIndicator(color: Colors.white),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildQuickPrompts() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _QuickChip('今天课表', '今天有什么课？'),
          _QuickChip('明天课表', '明天有什么课？'),
          _QuickChip('本周空余', '我这周什么时候有空？'),
          _QuickChip('课程统计', '这周共几节课？'),
        ]),
      ),
    );
  }

  Widget _QuickChip(String label, String query) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13, color: Colors.white)),
      onPressed: () => _send(overrideText: query),
      backgroundColor: Colors.white.withAlpha(38),
      side: BorderSide(color: Colors.white.withAlpha(77), width: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(color: Colors.white.withAlpha(26), border: const Border(top: BorderSide(color: Color(0x1AFFFFFF)))),
      child: Row(children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(24)),
            child: TextField(
              controller: _inputController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '输入问题...', hintStyle: TextStyle(color: Color(0x99FFFFFF)), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
              minLines: 1, maxLines: 4,
              onSubmitted: (_) => _send(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(gradient: _loading ? null : AppTheme.primaryGradient, color: _loading ? Colors.white.withAlpha(51) : null, shape: BoxShape.circle),
          child: IconButton(
            onPressed: _loading ? null : () => _send(),
            icon: const Icon(Icons.send, size: 20, color: Colors.white),
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ──

class _ChatMsg { const _ChatMsg({required this.role, required this.content}); final String role; final String content; }

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, this.active = false, required this.tooltip, required this.onTap});
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 22, color: active ? Colors.white : const Color(0xCCFFFFFF)),
    tooltip: tooltip, visualDensity: VisualDensity.compact, splashRadius: 20,
    onPressed: onTap,
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.white.withAlpha(38), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.auto_awesome, size: 32, color: Color(0xCCFFFFFF))),
        const SizedBox(height: 16),
        const Text('询问 AI 关于课程安排的建议', style: TextStyle(color: Color(0xCCFFFFFF))),
        const SizedBox(height: 4),
        const Text('点击上方快捷提问或输入问题', style: TextStyle(fontSize: 12, color: Color(0x80FFFFFF))),
      ],
    ),
  );
}
