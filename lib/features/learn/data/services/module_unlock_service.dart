// lib/features/learn/data/services/module_unlock_service.dart
//
// Authoritative source of truth for module/quiz unlock state.
// All reads and writes go through the sqflite `module_unlocks` table
// and the `quiz_attempts` table — NOT Hive.

import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';

enum ModuleState {
  locked,        // Not yet unlocked
  inProgress,    // Unlocked, lessons not all complete
  readyForQuiz,  // All lessons complete, quiz not yet passed
  passed,        // Quiz passed
}

class ModuleUnlockService {
  ModuleUnlockService._();
  static final ModuleUnlockService instance = ModuleUnlockService._();

  static const _uuid = Uuid();

  String _uid = 'anonymous';
  void setUserId(String uid) => _uid = uid;
  String get currentUserId => _uid;

  // ── Unlock a module for the current user ──────────────────────────────────

  Future<void> unlockModule(
    String moduleId, {
    String reason = 'quiz_passed',
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT OR IGNORE INTO module_unlocks
        (id, learner_id, module_id, unlocked_at, unlock_reason)
      VALUES (?, ?, ?, ?, ?)
    ''', [_uuid.v4(), _uid, moduleId, now, reason]);
  }

  // ── Check if a module is unlocked ─────────────────────────────────────────

  Future<bool> isModuleUnlocked(String moduleId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'module_unlocks',
      where: 'learner_id = ? AND module_id = ?',
      whereArgs: [_uid, moduleId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Check if a module quiz has been passed ─────────────────────────────────

  Future<bool> isQuizPassed(String moduleId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'quiz_attempts',
      where: 'learner_id = ? AND module_id = ? AND passed = 1',
      whereArgs: [_uid, moduleId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Save a completed quiz attempt ─────────────────────────────────────────

  Future<void> saveQuizAttempt({
    required String moduleId,
    required bool passed,
    required int totalScore,
    required int timeUsedSeconds,
    required double accuracyPct,
    required String skillLevelAchieved,
    required String attemptType,
    required int timeLimitSeconds,
    required int accuracyScore,
    required int timeBonus,
    required int firstAttemptBonus,
    required int streakBonus,
  }) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Get current attempt number
    final prev = await db.query(
      'quiz_attempts',
      columns: ['attempt_number'],
      where: 'learner_id = ? AND module_id = ?',
      whereArgs: [_uid, moduleId],
      orderBy: 'attempt_number DESC',
      limit: 1,
    );
    final attemptNum = prev.isEmpty
        ? 1
        : ((prev.first['attempt_number'] as int? ?? 0) + 1);

    await db.insert('quiz_attempts', {
      'id': _uuid.v4(),
      'learner_id': _uid,
      'module_id': moduleId,
      'attempt_type': attemptType,
      'attempt_number': attemptNum,
      'started_at': now,
      'submitted_at': now,
      'time_limit_seconds': timeLimitSeconds,
      'time_used_seconds': timeUsedSeconds,
      'accuracy_score': accuracyScore,
      'time_bonus': timeBonus,
      'first_attempt_bonus': firstAttemptBonus,
      'streak_bonus': streakBonus,
      'total_score': totalScore,
      'passed': passed ? 1 : 0,
      'accuracy_pct': accuracyPct,
      'skill_level_achieved': skillLevelAchieved,
    });
  }

  // ── Exam unlock (stored as moduleId + "_exam" in module_unlocks) ─────────

  Future<void> unlockExam(String moduleId) async {
    final db  = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT OR IGNORE INTO module_unlocks
        (id, learner_id, module_id, unlocked_at, unlock_reason)
      VALUES (?, ?, ?, ?, ?)
    ''', [_uuid.v4(), _uid, '${moduleId}_exam', now, 'quiz_passed']);
  }

  Future<bool> isExamUnlocked(String moduleId) async {
    final db   = await AppDatabase.instance.database;
    final rows = await db.query(
      'module_unlocks',
      where: 'learner_id = ? AND module_id = ?',
      whereArgs: [_uid, '${moduleId}_exam'],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  // ── Get full module state for the LearnScreen card ────────────────────────

  Future<ModuleState> getModuleState(
    String moduleId,
    int totalLessons,
  ) async {
    final unlocked = await isModuleUnlocked(moduleId);
    if (!unlocked) return ModuleState.locked;

    final passed = await isQuizPassed(moduleId);
    if (passed) return ModuleState.passed;

    // Count completed lessons
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'lesson_progress',
      where: 'user_id = ? AND module_id = ? AND is_completed = 1',
      whereArgs: [_uid, moduleId],
    );
    final completedCount = rows.length;

    if (completedCount >= totalLessons) return ModuleState.readyForQuiz;
    return ModuleState.inProgress;
  }
}
