// lib/shared/models/skill_profile_model.dart

/// The three learner bands per skill, as defined in the diagnostic spec.
enum SkillBand {
  developing, // 0 – 1 pts
  building,   // 1.5 – 2 pts
  confident,  // 2.5 – 3 pts
}

extension SkillBandLabel on SkillBand {
  String get label {
    switch (this) {
      case SkillBand.developing:
        return 'Developing';
      case SkillBand.building:
        return 'Building';
      case SkillBand.confident:
        return 'Confident';
    }
  }
}

/// Per-skill scoring result from the diagnostic.
class SkillScore {
  final String skillName;
  final double points;   // 0 – 3 (tier 1 = +1, tier 2 = +2, skip = -0.5)
  final SkillBand band;

  const SkillScore({
    required this.skillName,
    required this.points,
    required this.band,
  });

  factory SkillScore.fromPoints(String skillName, double points) {
    final clamped = points.clamp(0.0, 3.0);
    SkillBand band;
    if (clamped <= 1.0) {
      band = SkillBand.developing;
    } else if (clamped <= 2.0) {
      band = SkillBand.building;
    } else {
      band = SkillBand.confident;
    }
    return SkillScore(skillName: skillName, points: clamped, band: band);
  }
}

/// The full skill profile generated after the diagnostic assessment.
class SkillProfileModel {
  final SkillScore sequencing;
  final SkillScore logicFlow;
  final SkillScore debugging;
  final SkillScore syntax;
  final SkillScore computationalThinking;

  /// The badge awarded based on the majority band.
  /// 'beginner' | 'novice' | 'intermediate'
  final String overallLevel;

  final DateTime assessedAt;

  const SkillProfileModel({
    required this.sequencing,
    required this.logicFlow,
    required this.debugging,
    required this.syntax,
    required this.computationalThinking,
    required this.overallLevel,
    required this.assessedAt,
  });

  List<SkillScore> get allSkills => [
        sequencing,
        logicFlow,
        debugging,
        syntax,
        computationalThinking,
      ];

  /// Returns true if a module's skill tag should be marked "Mastered"
  /// (Building or Confident → skip intro module).
  bool shouldSkipIntroFor(String skillName) {
    final score = allSkills.firstWhere(
      (s) => s.skillName == skillName,
      orElse: () => SkillScore.fromPoints(skillName, 0),
    );
    return score.band != SkillBand.developing;
  }

  Map<String, dynamic> toMap() => {
        'sequencing_pts': sequencing.points,
        'logicFlow_pts': logicFlow.points,
        'debugging_pts': debugging.points,
        'syntax_pts': syntax.points,
        'computationalThinking_pts': computationalThinking.points,
        'overallLevel': overallLevel,
        'assessedAt': assessedAt.toIso8601String(),
      };

  factory SkillProfileModel.fromMap(Map<String, dynamic> map) {
    return SkillProfileModel(
      sequencing:
          SkillScore.fromPoints('Sequencing', map['sequencing_pts'] as double),
      logicFlow:
          SkillScore.fromPoints('Logic Flow', map['logicFlow_pts'] as double),
      debugging:
          SkillScore.fromPoints('Debugging', map['debugging_pts'] as double),
      syntax: SkillScore.fromPoints('Syntax', map['syntax_pts'] as double),
      computationalThinking: SkillScore.fromPoints(
          'Comp. Thinking', map['computationalThinking_pts'] as double),
      overallLevel: map['overallLevel'] as String,
      assessedAt: DateTime.parse(map['assessedAt'] as String),
    );
  }
}
