// lib/core/services/leaderboard_service.dart
//
// Query layer for the Ranks screen.
// Reads from sqflite `leaderboard_scores` table and returns ranked students.
// For the prototype, provides seedTestData() to populate demo students.

import '../database/app_database.dart';
import 'leaderboard_models.dart';
import 'points_service.dart';

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService instance = LeaderboardService._();

  /// Get all students ranked by total points (descending).
  Future<List<RankedStudent>> getRankedStudents() async {
    final db = await AppDatabase.instance.database;
    final currentUid = PointsService.instance.currentUserId;

    final rows = await db.query(
      'leaderboard_scores',
      orderBy: 'total_points DESC',
    );

    final List<RankedStudent> ranked = [];
    for (int i = 0; i < rows.length; i++) {
      final r = rows[i];
      final learnerId = r['learner_id'] as String;

      // Try to get a display name from the learners table
      String name = learnerId;
      final learnerRows = await db.query(
        'learners',
        columns: ['first_name', 'last_name'],
        where: 'id = ?',
        whereArgs: [learnerId],
      );
      if (learnerRows.isNotEmpty) {
        final first = learnerRows.first['first_name'] as String? ?? '';
        final last = learnerRows.first['last_name'] as String? ?? '';
        name = '$first $last'.trim();
        if (name.isEmpty) name = learnerId;
      }

      ranked.add(RankedStudent(
        id: learnerId,
        name: name,
        rank: i + 1,
        totalPoints: r['total_points'] as int? ?? 0,
        isCurrentUser: learnerId == currentUid,
        currentStreak: r['current_streak'] as int? ?? 0,
        modulesCompleted: r['modules_completed'] as int? ?? 0,
      ));
    }

    return ranked;
  }

  /// Get only the current user's rank entry.
  Future<RankedStudent?> getCurrentUserRank() async {
    final all = await getRankedStudents();
    try {
      return all.firstWhere((s) => s.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  /// Seed demo students for the prototype evaluation.
  /// Called once during first app init (guarded by app_meta flag).
  Future<void> seedTestData() async {
    final db = await AppDatabase.instance.database;

    // Check if already seeded
    final meta = await db.query('app_meta',
        where: "key = 'leaderboard_seeded'");
    if (meta.isNotEmpty) return;

    const demoStudents = [
      {'id': 'demo_01', 'first': 'Maria',  'last': 'Santos',    'pts': 285, 'streak': 12, 'modules': 3},
      {'id': 'demo_02', 'first': 'Juan',   'last': 'Dela Cruz', 'pts': 240, 'streak': 8,  'modules': 2},
      {'id': 'demo_03', 'first': 'Ana',    'last': 'Reyes',     'pts': 210, 'streak': 15, 'modules': 2},
      {'id': 'demo_04', 'first': 'Pedro',  'last': 'Garcia',    'pts': 175, 'streak': 5,  'modules': 2},
      {'id': 'demo_05', 'first': 'Rosa',   'last': 'Mendoza',   'pts': 150, 'streak': 3,  'modules': 1},
      {'id': 'demo_06', 'first': 'Carlo',  'last': 'Lim',       'pts': 120, 'streak': 7,  'modules': 1},
      {'id': 'demo_07', 'first': 'Grace',  'last': 'Tan',       'pts': 95,  'streak': 2,  'modules': 1},
      {'id': 'demo_08', 'first': 'Mark',   'last': 'Villanueva','pts': 60,  'streak': 1,  'modules': 0},
    ];

    final now = DateTime.now().toIso8601String();

    for (final s in demoStudents) {
      // Insert into learners table for name lookup
      await db.rawInsert('''
        INSERT OR IGNORE INTO learners (id, first_name, last_name, email, created_at, last_active)
        VALUES (?, ?, ?, ?, ?, ?)
      ''', [s['id'], s['first'], s['last'], '${s['id']}@demo.myada', now, now]);

      // Insert leaderboard score
      await db.rawInsert('''
        INSERT OR IGNORE INTO leaderboard_scores
          (id, learner_id, total_points, modules_completed,
           first_attempt_passes, current_streak, longest_streak, last_updated)
        VALUES (?, ?, ?, ?, 0, ?, ?, ?)
      ''', [s['id'], s['id'], s['pts'], s['modules'], s['streak'], s['streak'], now]);
    }

    // Mark as seeded
    await db.insert('app_meta', {'key': 'leaderboard_seeded', 'value': 'true'});
    print('LeaderboardService: seeded ${demoStudents.length} demo students');
  }
}
