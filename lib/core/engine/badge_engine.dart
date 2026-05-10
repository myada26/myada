// lib/core/engine/badge_engine.dart
//
// After every scoring event, call checkAndAward() to see if any badges
// should be awarded. This engine:
//   1. Filters badges relevant to the event type
//   2. Checks if each badge is already earned (learner_badges table)
//   3. Evaluates the badge condition using the provided context
//   4. Awards earned badges: inserts into DB + adds +10 points
//   5. Returns the list of newly earned badge IDs for UI reveal

import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../services/points_service.dart';
import '../services/streak_service.dart';
import 'badge_definitions.dart';

class BadgeEngine {
  BadgeEngine._();
  static final BadgeEngine instance = BadgeEngine._();

  String _uid = 'anonymous';

  void setUserId(String uid) => _uid = uid;

  /// Check all badges relevant to [eventType] and award any that are newly earned.
  ///
  /// [context] carries event-specific data:
  ///   - quiz_submitted:     {scorePct: double, isRetake: bool, previouslyFailed: bool}
  ///   - exercise_completed: {isFirstTry: bool, hintsUsed: int, isDebug: bool, isTimed: bool, completedInTime: bool}
  ///   - diagnostic_completed: {}
  ///   - learning_path_generated: {}
  ///   - daily_checkin:      {currentStreak: int}
  ///   - module_completed:   {modulesCompleted: int, totalModules: int}
  Future<List<String>> checkAndAward(
    String eventType, {
    Map<String, dynamic>? context,
  }) async {
    if (_uid == 'anonymous') return [];

    final ctx = context ?? {};
    final candidates = BadgeRegistry.forEvent(eventType);
    if (candidates.isEmpty) return [];

    final db = await AppDatabase.instance.database;
    final earnedIds = <String>[];

    for (final badge in candidates) {
      // Skip if already earned
      final existing = await db.query(
        'learner_badges',
        where: 'learner_id = ? AND badge_id = ?',
        whereArgs: [_uid, badge.id],
      );
      if (existing.isNotEmpty) continue;

      // Evaluate the condition
      final earned = _evaluate(badge, eventType, ctx);
      if (!earned) continue;

      // Award the badge
      final badgeRowId = '${_uid}_${badge.id}';
      await db.insert('learner_badges', {
        'id': badgeRowId,
        'learner_id': _uid,
        'badge_id': badge.id,
        'earned_at': DateTime.now().toIso8601String(),
      });

      // +10 points for earning a badge
      await PointsService.instance.addPoints(
        PointsService.badgeEarned,
        'badge_earned_${badge.id}',
      );

      earnedIds.add(badge.id);
      debugPrint('BadgeEngine: 🏅 awarded "${badge.name}" to $_uid');
    }

    return earnedIds;
  }

  // ── Condition evaluators ──────────────────────────────────────────────────

  bool _evaluate(BadgeDef badge, String event, Map<String, dynamic> ctx) {
    switch (badge.id) {
      // ── Beginner ──────────────────────────────────────────────────────────
      case 'first_step':
        return event == 'diagnostic_completed';
      case 'path_found':
        return event == 'learning_path_generated';

      // ── Streak ────────────────────────────────────────────────────────────
      case 'showing_up':
        return (StreakService.instance.currentStreak) >= 3;
      case 'week_warrior':
        return (StreakService.instance.currentStreak) >= 7;
      case 'unstoppable':
        return (StreakService.instance.currentStreak) >= 30;

      // ── Quiz ──────────────────────────────────────────────────────────────
      case 'quiz_taker':
        return event == 'quiz_submitted';
      case 'perfect_score':
        return (ctx['scorePct'] as double? ?? 0) >= 1.0;
      case 'quiz_streak':
        return (ctx['consecutivePasses'] as int? ?? 0) >= 5;
      case 'comeback':
        return (ctx['isRetake'] == true) && (ctx['previouslyFailed'] == true) &&
            (ctx['scorePct'] as double? ?? 0) >= 0.50;

      // ── Coding ────────────────────────────────────────────────────────────
      case 'first_code':
        return event == 'exercise_completed';
      case 'clean_shot':
        return (ctx['isFirstTry'] == true) && ((ctx['hintsUsed'] as int? ?? 1) == 0);
      case 'bug_hunter':
        return (ctx['totalDebugExercises'] as int? ?? 0) >= 5;
      case 'speed_coder':
        return (ctx['isTimed'] == true) && (ctx['completedInTime'] == true);

      // ── Progress ──────────────────────────────────────────────────────────
      case 'module_complete':
        return event == 'module_completed';
      case 'halfway_there':
        final done = ctx['modulesCompleted'] as int? ?? 0;
        final total = ctx['totalModules'] as int? ?? 1;
        return total > 0 && done >= (total / 2).ceil();
      case 'path_completed':
        final done = ctx['modulesCompleted'] as int? ?? 0;
        final total = ctx['totalModules'] as int? ?? 1;
        return total > 0 && done >= total;

      // ── Rare Mastery ──────────────────────────────────────────────────────
      case 'clean_sweep':
        return event == 'module_completed' &&
            (ctx['totalHintsUsed'] as int? ?? 1) == 0;

      case 'comeback_kid':
        return (ctx['isRetake'] == true) &&
            (ctx['previouslyFailed'] == true) &&
            (ctx['scorePct'] as double? ?? 0) >= 0.90;

      case 'night_owl':
        return (ctx['nightLessonsCompleted'] as int? ?? 0) >= 5;

      case 'early_bird':
        return (ctx['earlyLessonsCompleted'] as int? ?? 0) >= 5;

      case 'speed_demon':
        return event == 'timed_challenge_completed' &&
            (ctx['timeRemainingPct'] as double? ?? 0) > 0.5;

      case 'silent_solver':
        return (ctx['noHintExerciseCount'] as int? ?? 0) >= 10;

      case 'perfectionist':
        return (ctx['perfectQuizCount'] as int? ?? 0) >= 3;

      default:
        return false;
    }
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  /// Get all badge IDs that the current user has earned.
  Future<Set<String>> getEarnedBadgeIds() async {
    if (_uid == 'anonymous') return {};
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'learner_badges',
      columns: ['badge_id'],
      where: 'learner_id = ?',
      whereArgs: [_uid],
    );
    return rows.map((r) => r['badge_id'] as String).toSet();
  }

  /// Get all earned badges with their earned dates.
  Future<Map<String, DateTime>> getEarnedBadgesWithDates() async {
    if (_uid == 'anonymous') return {};
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'learner_badges',
      where: 'learner_id = ?',
      whereArgs: [_uid],
    );
    return {
      for (final r in rows)
        r['badge_id'] as String:
            DateTime.parse(r['earned_at'] as String),
    };
  }

  /// Count of earned badges.
  Future<int> getEarnedCount() async {
    return (await getEarnedBadgeIds()).length;
  }
}
