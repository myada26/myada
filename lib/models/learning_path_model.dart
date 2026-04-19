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

  inProgress,  // Currently active
  completed,   // Quiz passed
  locked,      // Not yet unlocked
}

/// A single curriculum module in the learning path.
/// Based on the 12-module architecture from the ADA Python curriculum document.
class LearningModule {
  /// Canonical string ID, e.g. "module_01". Used for navigation and DB lookups.
  final String moduleId;
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
    required this.moduleId,
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

class ModulePath {
  final String moduleId;
  final ModuleStatus status;
  final String? unlockedAt;
  final String? unlockReason;
  final SkillLevel? currentSkillLevel;

  const ModulePath({
    required this.moduleId,
    required this.status,
    this.unlockedAt,
    this.unlockReason,
    this.currentSkillLevel,
  });

  ModulePath copyWith({ModuleStatus? status, SkillLevel? currentSkillLevel}) =>
      ModulePath(
        moduleId: moduleId,
        status: status ?? this.status,
        unlockedAt: unlockedAt,
        unlockReason: unlockReason,
        currentSkillLevel: currentSkillLevel ?? this.currentSkillLevel,
      );
}

class QuizAttemptModel {
  final String id;
  final String learnerId;
  final String moduleId;
  final String attemptType; // 'module_quiz' | 'retry_quiz'
  final int attemptNumber;
  final int timeLimitSeconds;
  final int? timeUsedSeconds;
  final int accuracyScore;
  final int timeBonus;
  final int firstAttemptBonus;
  final int streakBonus;
  final int totalScore;
  final bool? passed;
  final double? accuracyPct;
  final String? skillLevelAchieved;

  const QuizAttemptModel({
    required this.id,
    required this.learnerId,
    required this.moduleId,
    required this.attemptType,
    required this.attemptNumber,
    required this.timeLimitSeconds,
    this.timeUsedSeconds,
    this.accuracyScore = 0,
    this.timeBonus = 0,
    this.firstAttemptBonus = 0,
    this.streakBonus = 0,
    this.totalScore = 0,
    this.passed,
    this.accuracyPct,
    this.skillLevelAchieved,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'learner_id': learnerId,
    'module_id': moduleId,
    'attempt_type': attemptType,
    'attempt_number': attemptNumber,
    'time_limit_seconds': timeLimitSeconds,
    'time_used_seconds': timeUsedSeconds,
    'accuracy_score': accuracyScore,
    'time_bonus': timeBonus,
    'first_attempt_bonus': firstAttemptBonus,
    'streak_bonus': streakBonus,
    'total_score': totalScore,
    'passed': passed == null ? null : (passed! ? 1 : 0),
    'accuracy_pct': accuracyPct,
    'skill_level_achieved': skillLevelAchieved,
    'started_at': DateTime.now().toIso8601String(),
  };
}
