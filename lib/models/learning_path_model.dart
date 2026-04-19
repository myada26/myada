// ─────────────────────────────────────────────────────────────────────────────
// learning_path_model.dart
//
// Pure data models for the MyADA learning path result.
// No logic, no UI — just typed data structures.
// ─────────────────────────────────────────────────────────────────────────────

/// The five diagnostic skill categories from the ADA curriculum document.
/// Each maps to one or more curriculum modules.
enum SkillCategory {
  sequencing,
  logicFlow,
  debugging,
  syntax,
  computationalThinking,
}

/// The three possible mastery levels a skill can resolve to after scoring.
///   Developing  → score 0.0 – 1.0
///   Building    → score 1.0 – 2.0
///   Confident   → score 2.0+
enum SkillLevel {
  developing,
  building,
  confident,
}

/// The three aggregate learner profiles derived from skill level distribution.
enum LearnerProfile {
  beginner,
  novice,
  intermediate,
}

/// Represents a single skill's diagnostic result.
class SkillResult {
  final SkillCategory skill;
  final SkillLevel level;

  /// Raw score from the diagnostic (may be negative from skips, but clamped to 0 for display).
  final double rawScore;

  /// True if the user skipped at least one question for this skill.
  final bool wasSkipped;

  const SkillResult({
    required this.skill,
    required this.level,
    required this.rawScore,
    required this.wasSkipped,
  });

  /// Normalized 0.0–1.0 progress value for skill bar display.
  /// Max possible score per skill is 3.0 (Tier 1 = 1pt + Tier 2 = 2pt).
  double get barFraction => (rawScore.clamp(0.0, 3.0) / 3.0);
}

/// The placement status of a module in the learning path.
enum ModuleStatus {
  /// User's skill for this module is Developing — required, must complete.
  required,

  /// User's skill for this module is Building — recommended to review.
  recommended,

  /// User's skill for this module is Confident — mastered, can skip.
  mastered,
}

/// A single curriculum module in the learning path.
/// Based on the 12-module architecture from the ADA Python curriculum document.
class LearningModule {
  final int number;
  final String name;
  final String description;
  final String tagLabel;
  final SkillCategory skill;
  final int estimatedLessons;
  final ModuleStatus status;

  /// True only for the very first required module — shown as the entry point.
  final bool isStartHere;

  const LearningModule({
    required this.number,
    required this.name,
    required this.description,
    required this.tagLabel,
    required this.skill,
    required this.estimatedLessons,
    required this.status,
    this.isStartHere = false,
  });

  /// Convenience: is this module actionable (not mastered)?
  bool get isActionable => status != ModuleStatus.mastered;
}

/// The complete result of the diagnostic assessment, passed from
/// DiagnosticController → LearningPathController → LearningPathScreen.
class DiagnosticResult {
  final List<SkillResult> skillResults;
  final LearnerProfile profile;
  final List<LearningModule> learningPath;

  /// Modules the user must complete (Developing skills).
  List<LearningModule> get requiredModules =>
      learningPath.where((m) => m.status == ModuleStatus.required).toList();

  /// Modules the user should review (Building skills).
  List<LearningModule> get recommendedModules =>
      learningPath.where((m) => m.status == ModuleStatus.recommended).toList();

  /// Modules the user has already mastered (Confident skills).
  List<LearningModule> get masteredModules =>
      learningPath.where((m) => m.status == ModuleStatus.mastered).toList();

  /// The first required module — the user's entry point.
  LearningModule? get startHereModule =>
      learningPath.where((m) => m.isStartHere).firstOrNull;

  const DiagnosticResult({
    required this.skillResults,
    required this.profile,
    required this.learningPath,
  });
}
