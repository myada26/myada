// lib/core/services/skill_profile_service.dart
//
// Aggregates live skill performance from quiz_attempts, keyed by skill_tag.
// Falls back to the diagnostic skill_profiles table if no quiz history exists.
// Call getSkillScores() to get a Map<SkillCategory, double> (0.0 – 1.0).

import '../database/app_database.dart';
import '../../models/learning_path_model.dart';

class SkillProfileService {
  SkillProfileService._();
  static final SkillProfileService instance = SkillProfileService._();

  String _uid = 'anonymous';
  void setUserId(String uid) => _uid = uid;

  /// Maps internal skill_tag strings to [SkillCategory] enum values.
  static const Map<String, SkillCategory> _tagMap = {
    'sequencing':              SkillCategory.sequencing,
    'logic_flow':              SkillCategory.logicFlow,
    'debugging':               SkillCategory.debugging,
    'syntax':                  SkillCategory.syntax,
    'computational_thinking':  SkillCategory.computationalThinking,
  };

  /// Returns a map from each [SkillCategory] to a score in [0.0, 1.0].
  ///
  /// Values come from the average [accuracy_pct] across all passed
  /// quiz_attempts whose questions share the same skill_tag.
  /// Falls back to the diagnostic [skill_profiles] table if no quiz data.
  Future<Map<SkillCategory, double>> getSkillScores() async {
    if (_uid == 'anonymous') return _defaultScores();

    final db = await AppDatabase.instance.database;

    // Aggregate average accuracy per skill_tag from quiz_attempts joined
    // with quiz_questions (which carry skill_tag).
    // We join on module_id as the linking key for the skill_tag.
    final rows = await db.rawQuery('''
      SELECT m.skill_tag, AVG(qa.accuracy_pct) as avg_score
      FROM quiz_attempts qa
      JOIN modules m ON qa.module_id = m.id
      WHERE qa.learner_id = ? AND qa.accuracy_pct IS NOT NULL
      GROUP BY m.skill_tag
    ''', [_uid]);

    // Build result map
    final Map<SkillCategory, double> scores = _defaultScores();
    for (final row in rows) {
      final tag  = (row['skill_tag'] as String?)?.toLowerCase() ?? '';
      final avg  = (row['avg_score'] as num?)?.toDouble() ?? 0.0;
      final cat  = _tagMap[tag];
      if (cat != null) {
        scores[cat] = (avg / 100.0).clamp(0.0, 1.0);
      }
    }

    // If we have no quiz data at all, fall back to diagnostic skill_profiles
    final hasLiveData = rows.isNotEmpty;
    if (!hasLiveData) {
      final diagRows = await db.query(
        'skill_profiles',
        where: 'learner_id = ?',
        whereArgs: [_uid],
      );
      for (final r in diagRows) {
        final tag  = (r['skill_tag'] as String?)?.toLowerCase() ?? '';
        final raw  = (r['raw_score'] as num?)?.toDouble() ?? 0.0;
        final cat  = _tagMap[tag];
        if (cat != null) {
          // raw_score in skill_profiles is stored as a 0–3 scale from diagnostic
          scores[cat] = (raw / 3.0).clamp(0.0, 1.0);
        }
      }
    }

    return scores;
  }

  /// Returns the skill with the lowest score (the "weakest" skill).
  Future<SkillCategory> getWeakestSkill() async {
    final scores = await getSkillScores();
    return scores.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;
  }

  /// Returns the skill with the highest score (the "strongest" skill).
  Future<SkillCategory> getStrongestSkill() async {
    final scores = await getSkillScores();
    return scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  Map<SkillCategory, double> _defaultScores() => {
    for (final cat in SkillCategory.values) cat: 0.0,
  };
}
