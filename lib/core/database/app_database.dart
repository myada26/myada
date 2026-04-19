import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static Database? _db;

  AppDatabase._();

  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = join(await getDatabasesPath(), 'myada.db');
    return openDatabase(
      dbPath,
      version: 2,
      onCreate: _createSchema,
      onUpgrade: _onUpgrade,
      onOpen: (db) async => await _seedIfNeeded(db),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addLessonProgressTable(db);
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch();

    batch.execute('''CREATE TABLE IF NOT EXISTS learners (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      created_at TEXT NOT NULL,
      last_active TEXT
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS modules (
      id TEXT PRIMARY KEY,
      sequence_order INTEGER NOT NULL UNIQUE,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      estimated_minutes INTEGER NOT NULL
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS lessons (
      id TEXT PRIMARY KEY,
      module_id TEXT NOT NULL,
      sequence_order INTEGER NOT NULL,
      title TEXT NOT NULL,
      content_json TEXT NOT NULL,
      FOREIGN KEY (module_id) REFERENCES modules(id),
      UNIQUE(module_id, sequence_order)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_questions (
      id TEXT PRIMARY KEY,
      module_id TEXT NOT NULL,
      question_type TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      difficulty_tier INTEGER NOT NULL,
      prompt_text TEXT NOT NULL,
      content_json TEXT NOT NULL,
      correct_answer TEXT NOT NULL,
      explanation TEXT NOT NULL,
      point_weight REAL NOT NULL DEFAULT 1.0,
      is_retry_eligible INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (module_id) REFERENCES modules(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS diagnostic_questions (
      id TEXT PRIMARY KEY,
      skill_tag TEXT NOT NULL,
      tier INTEGER NOT NULL,
      question_type TEXT NOT NULL,
      prompt_text TEXT NOT NULL,
      content_json TEXT NOT NULL,
      correct_answer TEXT NOT NULL
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS module_unlocks (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      unlocked_at TEXT NOT NULL,
      unlock_reason TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      FOREIGN KEY (module_id) REFERENCES modules(id),
      UNIQUE(learner_id, module_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS lesson_completions (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      lesson_id TEXT NOT NULL,
      completed_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, lesson_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_attempts (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      attempt_type TEXT NOT NULL,
      attempt_number INTEGER NOT NULL DEFAULT 1,
      started_at TEXT NOT NULL,
      submitted_at TEXT,
      time_limit_seconds INTEGER NOT NULL,
      time_used_seconds INTEGER,
      accuracy_score INTEGER NOT NULL DEFAULT 0,
      time_bonus INTEGER NOT NULL DEFAULT 0,
      first_attempt_bonus INTEGER NOT NULL DEFAULT 0,
      streak_bonus INTEGER NOT NULL DEFAULT 0,
      total_score INTEGER NOT NULL DEFAULT 0,
      passed INTEGER,
      accuracy_pct REAL,
      skill_level_achieved TEXT,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      FOREIGN KEY (module_id) REFERENCES modules(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS quiz_responses (
      id TEXT PRIMARY KEY,
      attempt_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      answer_given TEXT,
      is_correct INTEGER,
      was_skipped INTEGER NOT NULL DEFAULT 0,
      points_earned INTEGER NOT NULL DEFAULT 0,
      time_taken_seconds INTEGER,
      answered_at TEXT NOT NULL,
      FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS skill_profiles (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      skill_tag TEXT NOT NULL,
      level TEXT NOT NULL,
      raw_score REAL NOT NULL DEFAULT 0,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, skill_tag)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS diagnostic_sessions (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      completed_at TEXT,
      overall_level TEXT,
      bypass_reason TEXT,
      FOREIGN KEY (learner_id) REFERENCES learners(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS leaderboard_scores (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL UNIQUE,
      total_points INTEGER NOT NULL DEFAULT 0,
      modules_completed INTEGER NOT NULL DEFAULT 0,
      first_attempt_passes INTEGER NOT NULL DEFAULT 0,
      current_streak INTEGER NOT NULL DEFAULT 0,
      longest_streak INTEGER NOT NULL DEFAULT 0,
      last_updated TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS learner_badges (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      badge_id TEXT NOT NULL,
      earned_at TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, badge_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS learner_certificates (
      id TEXT PRIMARY KEY,
      learner_id TEXT NOT NULL,
      module_id TEXT NOT NULL,
      cert_code TEXT NOT NULL UNIQUE,
      issued_at TEXT NOT NULL,
      score_pct REAL NOT NULL,
      skills_covered TEXT NOT NULL,
      FOREIGN KEY (learner_id) REFERENCES learners(id),
      UNIQUE(learner_id, module_id)
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS sync_queue (
      id TEXT PRIMARY KEY,
      table_name TEXT NOT NULL,
      record_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL,
      synced_at TEXT,
      sync_attempts INTEGER NOT NULL DEFAULT 0
    )''');

    batch.execute('''CREATE TABLE IF NOT EXISTS app_meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )''');

    await batch.commit(noResult: true);

    // lesson_progress table (used by ProgressService)
    await _addLessonProgressTable(db);

    await db.insert('app_meta', {'key': 'schema_version', 'value': '2'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('app_meta', {'key': 'seed_loaded', 'value': '0'},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _addLessonProgressTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lesson_progress (
        user_id      TEXT NOT NULL,
        module_id    TEXT NOT NULL,
        lesson_id    TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        last_viewed  TEXT NOT NULL,
        completed_at TEXT,
        PRIMARY KEY (user_id, lesson_id)
      )
    ''');
  }

  Future<void> _seedIfNeeded(Database db) async {
    final meta = await db.query('app_meta',
        where: 'key = ?', whereArgs: ['seed_loaded']);
    if (meta.isNotEmpty && meta.first['value'] == '1') return;

    await _loadJsonAsset(db, 'assets/data/modules.json', 'modules');
    await _loadJsonAsset(db, 'assets/data/quiz_questions.json', 'quiz_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
          'is_retry_eligible': (m['is_retry_eligible'] as bool) ? 1 : 0,
        });
    await _loadJsonAsset(db, 'assets/data/retry_questions.json', 'quiz_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
          'is_retry_eligible': 1,
        });
    await _loadJsonAsset(db, 'assets/data/diagnostic_questions.json',
        'diagnostic_questions',
        transform: (m) => {
          ...m,
          'content_json': jsonEncode(m['content']),
        });

    await db.update('app_meta', {'value': '1'},
        where: 'key = ?', whereArgs: ['seed_loaded']);
  }

  Future<void> _loadJsonAsset(
    Database db,
    String assetPath,
    String tableName, {
    Map<String, dynamic> Function(Map<String, dynamic>)? transform,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final List<dynamic> items = jsonDecode(raw);
    final batch = db.batch();
    for (final item in items) {
      final map = Map<String, dynamic>.from(item as Map);
      final row = transform != null ? transform(map) : map;
      // Remove keys not in table schema
      row.remove('content');
      batch.insert(tableName, row,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
