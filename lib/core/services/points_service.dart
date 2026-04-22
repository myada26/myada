// lib/core/services/points_service.dart
//
// Central point ledger for the leaderboard system.
// Every point-awarding action flows through this single service.
// Backed by the sqflite `leaderboard_scores` and `point_history` tables.
// UID-scoped — call setUserId() after every auth event.

import 'package:flutter/foundation.dart';
import '../database/app_database.dart';

class PointsService extends ChangeNotifier {
  PointsService._();
  static final PointsService instance = PointsService._();

  String _uid = 'anonymous';
  int _cachedTotal = 0;

  String get currentUserId => _uid;
  int get totalPoints => _cachedTotal;

  void setUserId(String uid) {
    _uid = uid;
    _cachedTotal = 0;
  }

  // ── Point constants from the plan ─────────────────────────────────────────

  static const int dailyLogin           = 2;
  static const int streakBonus7         = 15;
  static const int streakBonus30        = 50;
  static const int quizSubmitted        = 10;  // score ≥ 50%
  static const int quizBonus70          = 5;   // 70–89%
  static const int quizBonus90          = 10;  // 90–99%
  static const int quizBonus100         = 15;  // 100%
  static const int quizRetakeImproved   = 3;
  static const int exerciseComplete     = 5;
  static const int firstTryBonus        = 5;
  static const int timedChallengeBonus  = 8;
  static const int hintPenalty          = -1;
  static const int skipPenalty          = -1;
  static const int badgeEarned          = 10;
  static const int moduleCompleted      = 20;
  static const int certificateEarned    = 30;
  static const int diagnosticCompleted  = 5;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Award (or deduct) points and log the reason.
  Future<void> addPoints(int pts, String reason) async {
    if (_uid == 'anonymous' || pts == 0) return;
    final db = await AppDatabase.instance.database;
    final now = DateTime.now().toIso8601String();

    // Upsert the cumulative total in leaderboard_scores
    await db.rawInsert('''
      INSERT INTO leaderboard_scores (id, learner_id, total_points, modules_completed,
        first_attempt_passes, current_streak, longest_streak, last_updated)
      VALUES (?, ?, ?, 0, 0, 0, 0, ?)
      ON CONFLICT(learner_id) DO UPDATE SET
        total_points = total_points + ?,
        last_updated = ?
    ''', [_uid, _uid, pts, now, pts, now]);

    // Append to audit trail
    final historyId = '${_uid}_${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('point_history', {
      'id': historyId,
      'learner_id': _uid,
      'points': pts,
      'reason': reason,
      'earned_at': now,
    });

    _cachedTotal += pts;
    notifyListeners();
    debugPrint('PointsService: +$pts ($reason) → total=$_cachedTotal');
  }

  /// Calculate quiz points based on the plan's scoring rules.
  Future<int> awardQuizPoints({
    required double scorePct,
    required bool isRetake,
    required bool improved,
  }) async {
    int total = 0;

    if (scorePct < 0.50) return 0; // below 50% — no credit

    if (isRetake) {
      if (improved) {
        await addPoints(quizRetakeImproved, 'quiz_retake_improved');
        total += quizRetakeImproved;
      }
      return total;
    }

    // Base: +10 for submitting
    await addPoints(quizSubmitted, 'quiz_submitted');
    total += quizSubmitted;

    // Accuracy bonus tiers
    if (scorePct >= 1.0) {
      await addPoints(quizBonus100, 'quiz_perfect');
      total += quizBonus100;
    } else if (scorePct >= 0.90) {
      await addPoints(quizBonus90, 'quiz_90_plus');
      total += quizBonus90;
    } else if (scorePct >= 0.70) {
      await addPoints(quizBonus70, 'quiz_70_plus');
      total += quizBonus70;
    }

    return total;
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Load the cached total from the database (call after setUserId).
  Future<void> loadTotal() async {
    if (_uid == 'anonymous') return;
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'leaderboard_scores',
      columns: ['total_points'],
      where: 'learner_id = ?',
      whereArgs: [_uid],
    );
    _cachedTotal = rows.isNotEmpty
        ? (rows.first['total_points'] as int? ?? 0)
        : 0;
    notifyListeners();
  }

  /// Update the streak columns in leaderboard_scores (called by StreakService).
  Future<void> updateStreakColumns(int current, int longest) async {
    if (_uid == 'anonymous') return;
    final db = await AppDatabase.instance.database;
    await db.rawUpdate('''
      UPDATE leaderboard_scores
      SET current_streak = ?, longest_streak = ?, last_updated = ?
      WHERE learner_id = ?
    ''', [current, longest, DateTime.now().toIso8601String(), _uid]);
  }

  /// Increment the modules_completed counter.
  Future<void> incrementModulesCompleted() async {
    if (_uid == 'anonymous') return;
    final db = await AppDatabase.instance.database;
    await db.rawUpdate('''
      UPDATE leaderboard_scores
      SET modules_completed = modules_completed + 1, last_updated = ?
      WHERE learner_id = ?
    ''', [DateTime.now().toIso8601String(), _uid]);
  }
}
