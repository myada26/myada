// lib/features/progress/data/services/challenge_service.dart
//
// Provides context-aware challenge and retake selection from the local DB
// plus the static challenges.json pool.

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/services/skill_profile_service.dart';
import '../../../../models/learning_path_model.dart';

class ChallengeModel {
  final String id;
  final String type;
  final String title;
  final String description;
  final String skillTag;
  final int timeLimitSeconds;
  final int pointsReward;

  const ChallengeModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.skillTag,
    required this.timeLimitSeconds,
    required this.pointsReward,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) => ChallengeModel(
    id: json['id'] as String,
    type: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    skillTag: json['skill_tag'] as String,
    timeLimitSeconds: json['time_limit_seconds'] as int,
    pointsReward: json['points_reward'] as int,
  );

  bool get isTimed => timeLimitSeconds > 0;
}

class RetakeItem {
  final String moduleId;
  final String moduleTitle;
  final double lastScore;

  RetakeItem({
    required this.moduleId,
    required this.moduleTitle,
    required this.lastScore,
  });
}

class ChallengeService {
  ChallengeService._();
  static final ChallengeService instance = ChallengeService._();

  String _uid = 'anonymous';
  void setUserId(String uid) => _uid = uid;

  List<ChallengeModel>? _allChallenges;

  Future<List<ChallengeModel>> _loadChallenges() async {
    if (_allChallenges != null) return _allChallenges!;
    final raw = await rootBundle.loadString('assets/data/challenges.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _allChallenges = list
        .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _allChallenges!;
  }

  Future<ChallengeModel?> getDailyMasteryChallenge() async {
    if (_uid == 'anonymous') return null;
    final mastery = (await getAvailableChallenges())
        .where((c) => c.type == 'mastery_challenge')
        .toList();
    if (mastery.isEmpty) return null;
    mastery.shuffle();
    return mastery.first;
  }

  Future<ChallengeModel?> getDailySkillDrill({
    Set<String> preferredSkillTags = const {},
  }) async {
    if (_uid == 'anonymous') return null;
    final drills = (await getAvailableChallenges(
      preferredSkillTags: preferredSkillTags,
    )).where((c) => c.type == 'skill_drill').toList();
    if (drills.isEmpty) return null;
    return drills.first;
  }

  Future<List<RetakeItem>> getRetakeSuggestions() async {
    if (_uid == 'anonymous') return [];
    final db = await AppDatabase.instance.database;

    final rows = await db.rawQuery(
      '''
      SELECT qa.module_id, m.title, qa.accuracy_pct
      FROM quiz_attempts qa
      JOIN modules m ON qa.module_id = m.id
      JOIN (
        SELECT module_id, MAX(attempt_number) AS latest_attempt
        FROM quiz_attempts
        WHERE learner_id = ?
        GROUP BY module_id
      ) latest
        ON latest.module_id = qa.module_id
       AND latest.latest_attempt = qa.attempt_number
      WHERE qa.learner_id = ?
        AND qa.passed = 0
        AND qa.accuracy_pct IS NOT NULL
      ORDER BY qa.accuracy_pct ASC, qa.submitted_at DESC
      LIMIT 3
    ''',
      [_uid, _uid],
    );

    return rows
        .map(
          (r) => RetakeItem(
            moduleId: r['module_id'] as String,
            moduleTitle: r['title'] as String,
            lastScore: (r['accuracy_pct'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<ChallengeModel>> getAvailableChallenges({
    Set<String> preferredSkillTags = const {},
  }) async {
    if (_uid == 'anonymous') return [];

    final db = await AppDatabase.instance.database;
    final all = await _loadChallenges();

    final passedRows = await db.rawQuery(
      '''
      SELECT DISTINCT m.skill_tag
      FROM quiz_attempts qa
      JOIN modules m ON qa.module_id = m.id
      WHERE qa.learner_id = ? AND qa.passed = 1
    ''',
      [_uid],
    );
    final passedTags = passedRows
        .map((r) => (r['skill_tag'] as String? ?? '').toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();

    final unlockedRows = await db.rawQuery(
      '''
      SELECT DISTINCT m.skill_tag
      FROM module_unlocks mu
      JOIN modules m ON mu.module_id = m.id
      WHERE mu.learner_id = ?
    ''',
      [_uid],
    );
    final unlockedTags = unlockedRows
        .map((r) => (r['skill_tag'] as String? ?? '').toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet();

    final weakestTag = _categoryToTag(
      await SkillProfileService.instance.getWeakestSkill(),
    );
    final prioritizedTags = {
      ...preferredSkillTags.map((tag) => tag.toLowerCase()),
      weakestTag,
      ...unlockedTags,
    };

    return all.where((challenge) {
      final skillTag = challenge.skillTag.toLowerCase();
      if (challenge.type == 'mastery_challenge') {
        return passedTags.contains(skillTag);
      }
      if (challenge.type == 'skill_drill') {
        return prioritizedTags.contains(skillTag);
      }
      return false;
    }).toList();
  }

  String _categoryToTag(SkillCategory cat) => switch (cat) {
    SkillCategory.sequencing => 'sequencing',
    SkillCategory.logicFlow => 'logic_flow',
    SkillCategory.debugging => 'debugging',
    SkillCategory.syntax => 'syntax',
    SkillCategory.computationalThinking => 'computational_thinking',
  };
}
