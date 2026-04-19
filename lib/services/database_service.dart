import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static Database? _db;

  DatabaseService._();
  static DatabaseService get instance => _instance ??= DatabaseService._();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'offline_ai.db'),
      version: 2, // ✅ FIXED: Incremented for migration
      onCreate: (db, version) async {
        // ✅ FIXED: Enable foreign keys
        await db.execute('PRAGMA foreign_keys = ON');
        
        await db.execute('''
          CREATE TABLE sessions(
            id TEXT PRIMARY KEY,
            title TEXT,
            modelId TEXT,
            modelName TEXT,
            createdAt INTEGER,
            updatedAt INTEGER,
            messageCount INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE messages(
            id TEXT PRIMARY KEY,
            sessionId TEXT,
            role TEXT,
            text TEXT,
            timestamp INTEGER,
            FOREIGN KEY (sessionId) REFERENCES sessions(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE downloaded_models(
            id TEXT PRIMARY KEY,
            name TEXT,
            version TEXT,
            family TEXT,
            size TEXT,
            sizeMB INTEGER,
            filePath TEXT,
            downloadedAt INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ✅ FIXED: Add migration logic
        if (oldVersion < 2) {
          await db.execute('PRAGMA foreign_keys = ON');
          // Add any new columns here in future versions
        }
      },
      onConfigure: (db) async {
        // ✅ FIXED: Ensure foreign keys are enabled on every open
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ── Sessions ────────────────────────────────────────────────
  Future<List<ChatSession>> getSessions() async {
    final database = await db;
    final maps = await database.query(
      'sessions',
      orderBy: 'updatedAt DESC',
    );
    return maps.map((m) => ChatSession.fromMap(m)).toList();
  }

  Future<void> insertSession(ChatSession session) async {
    final database = await db;
    await database.insert('sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSession(ChatSession session) async {
    final database = await db;
    await database.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    final database = await db;
    // ✅ FIXED: Foreign keys will now cascade delete messages
    await database.delete('sessions', where: 'id = ?', whereArgs: [id]);
    // This line is now redundant but kept for safety
    await database
        .delete('messages', where: 'sessionId = ?', whereArgs: [id]);
  }

  // ── Messages ────────────────────────────────────────────────
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final database = await db;
    final maps = await database.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => ChatMessage.fromMap(m)).toList();
  }

  Future<void> insertMessage(String sessionId, ChatMessage message) async {
    final database = await db;
    await database.insert('messages', {
      ...message.toMap(),
      'sessionId': sessionId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Downloaded models ───────────────────────────────────────────────
  Future<List<String>> getDownloadedModelIds() async {
    final database = await db;
    final maps = await database.query('downloaded_models', columns: ['id']);
    return maps.map((m) => m['id'] as String).toList();
  }

  Future<void> saveDownloadedModel(LlmModel model, String filePath) async {
    final database = await db;
    await database.insert(
      'downloaded_models',
      {
        'id': model.id,
        'name': model.name,
        'version': model.version,
        'family': model.family,
        'size': model.size,
        'sizeMB': model.sizeMB, // ✅ FIXED: Updated field name
        'filePath': filePath,
        'downloadedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDownloadedModel(String id) async {
    final database = await db;
    await database
        .delete('downloaded_models', where: 'id = ?', whereArgs: [id]);
  }

  Future<String?> getModelFilePath(String id) async {
    final database = await db;
    final result = await database.query(
      'downloaded_models',
      columns: ['filePath'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return result.first['filePath'] as String?;
  }
}
