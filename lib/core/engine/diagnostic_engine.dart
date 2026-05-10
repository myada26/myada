import '../../models/diagnostic_models.dart';

class DiagnosticEngine {
  static const double _tier1Correct  =  1.0;
  static const double _tier2Correct  =  2.0;
  static const double _skippedPen    = -0.5;
  static const double _buildingMin   =  1.5;
  static const double _confidentMin  =  2.5;

  static const Map<SkillTag, List<String>> _skillModuleMap = {
    SkillTag.sequencing:             ['module_01', 'module_07', 'module_11'],
    SkillTag.syntax:                 ['module_02', 'module_06'],
    SkillTag.logicFlow:              ['module_03', 'module_04'],
    SkillTag.computationalThinking:  ['module_05', 'module_08', 'module_12'],
    SkillTag.debugging:              ['module_09'],
  };

  static double _calcRaw({
    required bool t1Correct, required bool t1Skipped,
    required bool t2Correct, required bool t2Skipped,
  }) {
    double s = 0;
    s += t1Skipped ? _skippedPen : (t1Correct ? _tier1Correct : 0);
    s += t2Skipped ? _skippedPen : (t2Correct ? _tier2Correct : 0);
    return s.clamp(0, 3.0);
  }

  static SkillLevel _level(double raw) {
    if (raw >= _confidentMin) return SkillLevel.confident;
    if (raw >= _buildingMin)  return SkillLevel.building;
    return SkillLevel.developing;
  }

  static String _overallLevel(List<SkillScore> scores) {
    final n         = scores.length;
    final confident = scores.where((s) => s.level == SkillLevel.confident).length;
    final building  = scores.where((s) => s.level == SkillLevel.building).length;
    if (confident / n >= 0.6) return 'intermediate';
    if ((confident + building) / n >= 0.4) return 'novice';
    return 'beginner';
  }

  /// Main entry point. Pass all 10 diagnostic responses.
  static EngineDiagnosticResult calculate(List<DiagnosticResponse> responses) {
    DiagnosticResponse find(SkillTag tag, int tier) =>
        responses.firstWhere(
          (r) => r.skillTag == tag && r.tier == tier,
          orElse: () => DiagnosticResponse.skipped(tag, tier),
        );

    final scores = SkillTag.values.map((tag) {
      final t1  = find(tag, 1);
      final t2  = find(tag, 2);
      final raw = _calcRaw(
        t1Correct: t1.isCorrect, t1Skipped: t1.wasSkipped,
        t2Correct: t2.isCorrect, t2Skipped: t2.wasSkipped,
      );
      return SkillScore(skillTag: tag, rawScore: raw, level: _level(raw));
    }).toList();

    final toSkip        = <String>[];  // confident
    final toRecommended = <String>[];  // building
    final toRequired    = <String>[];  // developing

    for (final score in scores) {
      final gated = _skillModuleMap[score.skillTag] ?? [];
      if (score.level == SkillLevel.confident) {
        toSkip.addAll(gated);
      } else if (score.level == SkillLevel.building) {
        toRecommended.addAll(gated);
      } else {
        toRequired.addAll(gated);
      }
    }

    // Required wins over recommended wins over skip
    final reqSet  = toRequired.toSet();
    final recSet  = toRecommended.toSet().difference(reqSet);
    final skipSet = toSkip.toSet().difference(reqSet).difference(recSet);

    return EngineDiagnosticResult(
      skillScores:        scores,
      overallLevel:       _overallLevel(scores),
      modulesToSkip:      skipSet.toList(),
      modulesRecommended: recSet.toList(),
      modulesRequired:    reqSet.toList(),
    );
  }

  /// After Tier 1 answer — should next question come from hard pool?
  static bool shouldUpgradeTier(bool tier1WasCorrect) => tier1WasCorrect;
}
