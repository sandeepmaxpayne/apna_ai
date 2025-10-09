import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/chat_session.dart';

class ChatDatabase {
  static final ChatDatabase instance = ChatDatabase._init();
  static Database? _database;

  ChatDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_sessions.db');
    return _database!;
  }

  //Fetch all session

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT,
        timestamp TEXT
      )
    ''');
  }

  // ✅ Insert new session
  Future<int> insertSession(ChatSession session) async {
    final db = await instance.database;
    return await db.insert('chat_sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ✅ Update existing session (ongoing)
  Future<int> updateSession(ChatSession session) async {
    final db = await instance.database;
    return await db.update(
      'chat_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<ChatSession>> fetchAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'chat_sessions', // <- change to your table name if different
      orderBy: 'timestamp DESC', // adjust if different column name
    );
    return maps.map((m) => ChatSession.fromMap(m)).toList();
  }

  /// Search sessions by title or message (simple LIKE search)
  Future<List<ChatSession>> searchSessions(String query) async {
    final db = await database;
    final maps = await db.query(
      'chat_sessions', // adjust to your table
      where: 'title LIKE ? OR message LIKE ?', // adjust column names
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => ChatSession.fromMap(m)).toList();
  }

  // ✅ Fetch last session
  Future<ChatSession?> getLatestSession() async {
    final db = await instance.database;
    final result = await db.query(
      'chat_sessions',
      orderBy: 'id DESC',
      limit: 1,
    );
    return null;
  }

  Future<void> deleteAll() async {
    final db = await instance.database;
    await db.delete('chat_sessions');
  }
}
