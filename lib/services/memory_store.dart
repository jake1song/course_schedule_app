import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class ConversationData {
  ConversationData({required this.id, required this.title, required this.createdAt, this.updatedAt});
  final String id;
  String title;
  final DateTime createdAt;
  DateTime? updatedAt;
}

class MessageData {
  MessageData({required this.id, required this.conversationId, required this.role, required this.content, required this.createdAt});
  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'conversation_id': conversationId,
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  factory MessageData.fromMap(Map<String, dynamic> m) => MessageData(
    id: m['id'] as String,
    conversationId: m['conversation_id'] as String,
    role: m['role'] as String,
    content: m['content'] as String,
    createdAt: DateTime.parse(m['created_at'] as String),
  );
}

class MemoryEntry {
  MemoryEntry({this.id, required this.summary, required this.keywords, required this.createdAt});
  int? id;
  final String summary;
  final String keywords;
  final DateTime createdAt;
}

class MemoryStore {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'ai_memory.db');
    _db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE memories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        summary TEXT NOT NULL,
        keywords TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_msg_conv ON messages(conversation_id)');
  }

  // ── Conversations ──

  Future<List<ConversationData>> listConversations() async {
    final d = await db;
    final rows = await d.query('conversations', orderBy: 'updated_at DESC');
    return rows.map((r) => ConversationData(
      id: r['id'] as String,
      title: r['title'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: r['updated_at'] != null ? DateTime.parse(r['updated_at'] as String) : null,
    )).toList();
  }

  Future<void> saveConversation(ConversationData conv) async {
    final d = await db;
    await d.insert('conversations', {
      'id': conv.id,
      'title': conv.title,
      'created_at': conv.createdAt.toIso8601String(),
      'updated_at': (conv.updatedAt ?? conv.createdAt).toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateTitle(String id, String title) async {
    final d = await db;
    await d.update('conversations', {'title': title, 'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteConversation(String id) async {
    final d = await db;
    await d.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    await d.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ── Messages ──

  Future<List<MessageData>> loadMessages(String conversationId) async {
    final d = await db;
    final rows = await d.query('messages', where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'created_at ASC');
    return rows.map((r) => MessageData.fromMap(r)).toList();
  }

  Future<void> saveMessage(MessageData msg) async {
    final d = await db;
    await d.insert('messages', msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    await d.update('conversations', {'updated_at': DateTime.now().toIso8601String()}, where: 'id = ?', whereArgs: [msg.conversationId]);
  }

  Future<int> messageCount(String conversationId) async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) as cnt FROM messages WHERE conversation_id = ?', [conversationId]);
    return (r.first['cnt'] as int?) ?? 0;
  }

  Future<List<MessageData>> searchMessages(String keyword, {int limit = 10}) async {
    final d = await db;
    final rows = await d.query('messages', where: 'content LIKE ?', whereArgs: ['%$keyword%'], orderBy: 'created_at DESC', limit: limit);
    return rows.map((r) => MessageData.fromMap(r)).toList();
  }

  // ── Memories (AI summaries) ──

  Future<MemoryEntry?> latestMemory() async {
    final d = await db;
    final rows = await d.query('memories', orderBy: 'created_at DESC', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return MemoryEntry(id: r['id'] as int, summary: r['summary'] as String, keywords: r['keywords'] as String, createdAt: DateTime.parse(r['created_at'] as String));
  }

  Future<void> saveMemory(MemoryEntry memory) async {
    final d = await db;
    await d.insert('memories', {
      'summary': memory.summary,
      'keywords': memory.keywords,
      'created_at': memory.createdAt.toIso8601String(),
    });
    // Keep only last 5 summaries
    await d.rawDelete('DELETE FROM memories WHERE id NOT IN (SELECT id FROM memories ORDER BY created_at DESC LIMIT 5)');
  }

  Future<List<MessageData>> allMessages() async {
    final d = await db;
    final rows = await d.query('messages', orderBy: 'created_at ASC', limit: 200);
    return rows.map((r) => MessageData.fromMap(r)).toList();
  }
}
