// lib/features/learn/data/services/progress_service.dart
//
// SQLite-backed progress persistence service.
// Uses AppDatabase (sqflite) — completely separate from the Hive auth layer.
// Table: lesson_progress
//   user_id      TEXT  — Firebase UID
//   module_id    TEXT
//   lesson_id    TEXT  — e.g. 'm01_l03'
//   is_completed INTEGER (0/1)
//   last_viewed  TEXT  — ISO-8601
//   completed_at TEXT  — ISO-8601, nullable
//   PRIMARY KEY (user_id, lesson_id)

import '../../../../core/database/app_database.dart';

class ProgressService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  String _uid = 'anonymous';

  /// The current user ID. Read-only for external callers.
  String get currentUserId => _uid;

  /// Call immediately after every successful auth event.
  void setUserId(String uid) => _uid = uid;

  // ── Create table if not already created by AppDatabase ───────────────────
  // AppDatabase creates this table during its own migration — this guard
  // is a safety net so the service works even in isolation during tests.
  Future<void> ensureTable() async {
    final db = await AppDatabase.instance.database;
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

  // ── Write operations ──────────────────────────────────────────────────────

  /// Upsert a "last viewed" record without marking as complete.
  Future<void> saveLastViewed(String moduleId, String lessonId) async {
    final db = await AppDatabase.instance.database;
    await db.rawInsert('''
      INSERT INTO lesson_progress (user_id, module_id, lesson_id, is_completed, last_viewed)
      VALUES (?, ?, ?, 0, ?)
      ON CONFLICT(user_id, lesson_id) DO UPDATE SET
        last_viewed = excluded.last_viewed
    ''', [_uid, moduleId, lessonId, DateTime.now().toIso8601String()]);
  }

  /// Mark lesson as complete and upsert the progress row.
  Future<void> markLessonComplete(String moduleId, String lessonId) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO lesson_progress (user_id, module_id, lesson_id, is_completed, last_viewed, completed_at)
      VALUES (?, ?, ?, 1, ?, ?)
      ON CONFLICT(user_id, lesson_id) DO UPDATE SET
        is_completed = 1,
        last_viewed  = excluded.last_viewed,
        completed_at = COALESCE(lesson_progress.completed_at, excluded.completed_at)
    ''', [_uid, moduleId, lessonId, now, now]);
  }

  // ── Read operations ───────────────────────────────────────────────────────

  /// Returns the last lesson_id the user opened in this module, or null.
  Future<String?> getLastViewedLesson(String moduleId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'lesson_progress',
      columns: ['lesson_id'],
      where: 'user_id = ? AND module_id = ?',
      whereArgs: [_uid, moduleId],
      orderBy: 'last_viewed DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['lesson_id'] as String?;
  }

  /// Returns how many lessons in this module are marked complete.
  Future<int> getCompletedLessonCount(String moduleId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'lesson_progress',
      where: 'user_id = ? AND module_id = ? AND is_completed = 1',
      whereArgs: [_uid, moduleId],
    );
    return rows.length;
  }

  /// Returns all completed lesson_ids for a module.
  Future<List<String>> getAllCompletedLessons(String moduleId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'lesson_progress',
      columns: ['lesson_id'],
      where: 'user_id = ? AND module_id = ? AND is_completed = 1',
      whereArgs: [_uid, moduleId],
    );
    return rows.map((r) => r['lesson_id'] as String).toList();
  }

  /// True if every lesson in [allLessonIds] has been completed.
  Future<bool> areAllLessonsComplete(
    String moduleId,
    List<String> allLessonIds,
  ) async {
    final completed = await getAllCompletedLessons(moduleId);
    return allLessonIds.every((id) => completed.contains(id));
  }
}
