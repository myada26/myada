// ─────────────────────────────────────────────────────────────────────────────
// learning_path_controller.dart
//
// Pure logic controller for building and exposing the learning path result.
// No UI code — consumed by LearningPathScreen via Provider/ChangeNotifier.
//
// Responsibilities:
//   1. Receive raw scores + skip data from DiagnosticController
//   2. Resolve each skill to a SkillLevel
//   3. Determine the aggregate LearnerProfile
//   4. Map skill levels to module statuses across all 12 curriculum modules
//   5. Mark the first required module as "start here"
//   6. Expose the final DiagnosticResult for the UI to render
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import '../models/diagnostic_models.dart';
import '../core/data/local_database.dart';
import '../core/database/app_database.dart';
import '../features/learn/data/services/module_unlock_service.dart';

class LearningPathController extends ChangeNotifier {
  // ─────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────

  /// The computed result after [buildResult] is called.
  /// Null until [buildResult] has been called at least once.
  DiagnosticResult? _result;

  /// True while the result is being computed (for loading UI states).
  bool _isBuilding = false;

  // ─────────────────────────────────────────────────────
  // Public getters
  // ─────────────────────────────────────────────────────

  DiagnosticResult? get result => _result;
  bool get isBuilding => _isBuilding;
  bool get hasResult => _result != null;

  // ─────────────────────────────────────────────────────
  // Entry point — called when DiagnosticController completes
  // ─────────────────────────────────────────────────────

  /// Builds the full [DiagnosticResult] from raw diagnostic output.
  ///
  /// Parameters:
  ///   [scores]  — Map<skillIndex, rawScore> from DiagnosticController.scores
  ///   [skips]   — List<skillIndex> from DiagnosticController.skips
  ///
  /// Usage (in your router or screen transition):
  ///   learningPathController.buildResult(
  ///     scores: diagnosticController.scores,
  ///     skips:  diagnosticController.skips,
  ///   );
  Future<void> buildResult({
    required Map<int, double> scores,
    required List<int> skips,
    bool saveToDb = true,
  }) async {
    _isBuilding = true;
    notifyListeners();

    // ── Step 1: Resolve each skill to a SkillResult ──────────────────────────
    final skillResults = _buildSkillResults(scores: scores, skips: skips);

    // ── Step 2: Determine aggregate learner profile ──────────────────────────
    final profile = _resolveProfile(skillResults);

    // ── Step 3: Map skills to module statuses and build ordered path ─────────
    final learningPath = _buildLearningPath(skillResults);

    // ── Step 4: Assemble final result ─────────────────────────────────────────
    _result = DiagnosticResult(
      skillResults: skillResults,
      profile: profile,
      learningPath: learningPath,
    );

    // ── Step 5: Auto-unlock recommended & mastered modules in DB ─────────────
    for (final module in learningPath) {
      if (module.status == ModuleStatus.mastered ||
          module.status == ModuleStatus.recommended) {
        await ModuleUnlockService.instance.unlockModule(
          module.moduleId,
          reason: 'diagnostic_${module.status.name}',
        );
      }
    }

    if (saveToDb) {
      // IMPORTANT: await the write so data is not lost if the app closes
      // immediately after the diagnostic result screen is shown.
      await LocalDatabase().saveDiagnosticProgress(scores, skips);
    }

    _isBuilding = false;
    notifyListeners();
  }

  /// Attempts to load and build the result from persisted data.
  /// Call this after the UID is set (i.e. after AuthController.init completes).
  Future<void> loadResultFromDb() async {
    final data = LocalDatabase().getDiagnosticProgress();
    if (data == null) {
      debugPrint('LearningPathController: no saved diagnostic data found.');
      return;
    }
    try {
      // getDiagnosticProgress already parses keys to int/double for us.
      final scores = Map<int, double>.from(data['scores'] as Map);
      final skips  = List<int>.from(data['skips']  as List);
      debugPrint('LearningPathController: restoring diagnostic — '
          'scores=$scores skips=$skips');
      // await so we know the result is fully built before the UI reads it.
      await buildResult(scores: scores, skips: skips, saveToDb: false);
    } catch (e, st) {
      debugPrint('LearningPathController: failed to restore diagnostic: $e\n$st');
    }
  }

  /// Clears the current result. Call before starting a new diagnostic session.
  void reset() {
    _result = null;
    _isBuilding = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Step 1 — Skill result resolution
  // ─────────────────────────────────────────────────────

  List<SkillResult> _buildSkillResults({
    required Map<int, double> scores,
    required List<int> skips,
  }) {
    // Skill index → SkillCategory mapping (matches DiagnosticController order)
    const indexToCategory = {
      0: SkillCategory.sequencing,
      1: SkillCategory.logicFlow,
      2: SkillCategory.debugging,
      3: SkillCategory.syntax,
      4: SkillCategory.computationalThinking,
    };

    return List.generate(5, (i) {
      final raw = scores[i] ?? 0.0;
      final category = indexToCategory[i]!;
      final level = _resolveSkillLevel(raw);
      final skipped = skips.contains(i);

      return SkillResult(
        skill: category,
        level: level,
        rawScore: raw,
        wasSkipped: skipped,
      );
    });
  }

  /// Resolves a raw score to a SkillLevel.
  ///   < 1.5  → Developing  (0.0–1.4)
  ///   < 2.5  → Building    (1.5–2.4)
  ///   ≥ 2.5  → Confident   (2.5–3.0)
  /// Matches DiagnosticEngine thresholds (_buildingMin=1.5, _confidentMin=2.5).
  SkillLevel _resolveSkillLevel(double raw) {
    if (raw >= 2.5) return SkillLevel.confident;
    if (raw >= 1.5) return SkillLevel.building;
    return SkillLevel.developing;
  }

  // ─────────────────────────────────────────────────────
  // Step 2 — Learner profile
  // ─────────────────────────────────────────────────────

  /// Derives the aggregate profile from the distribution of skill levels.
  ///   ≥ 3 Confident                         → Intermediate
  ///   ≥ 1 Confident  AND  ≤ 2 Developing    → Novice
  ///   Anything else                          → Beginner
  LearnerProfile _resolveProfile(List<SkillResult> skillResults) {
    final confCount = skillResults
        .where((r) => r.level == SkillLevel.confident)
        .length;
    final devCount = skillResults
        .where((r) => r.level == SkillLevel.developing)
        .length;

    if (confCount >= 3) return LearnerProfile.intermediate;
    if (confCount >= 1 && devCount <= 2) return LearnerProfile.novice;
    return LearnerProfile.beginner;
  }

  // ─────────────────────────────────────────────────────
  // Step 3 — Learning path builder
  // ─────────────────────────────────────────────────────

  /// Builds the full 12-module learning path with statuses assigned.
  ///
  /// Module status rules:
  ///   Skill = Confident  → ModuleStatus.mastered    (grey, can skip)
  ///   Skill = Building   → ModuleStatus.recommended (blue, review)
  ///   Skill = Developing → ModuleStatus.required    (green, must do)
  ///
  /// The first required module is additionally marked [isStartHere = true].
  List<LearningModule> _buildLearningPath(List<SkillResult> skillResults) {
    // Helper: look up a skill's level by SkillCategory
    SkillLevel levelFor(SkillCategory cat) =>
        skillResults.firstWhere((r) => r.skill == cat).level;

    // Helper: convert SkillLevel to ModuleStatus
    ModuleStatus statusFor(SkillCategory cat) {
      switch (levelFor(cat)) {
        case SkillLevel.confident:
          return ModuleStatus.mastered;
        case SkillLevel.building:
          return ModuleStatus.recommended;
        case SkillLevel.developing:
          return ModuleStatus.required;
      }
    }

    // ── 12-module curriculum (from ADA Python curriculum document) ────────────
    // Order is intentional: follows the pedagogical sequence defined in the doc.
    final rawModules = [
      _module(
        'module_01',
        1,
        'The genesis of execution',
        'Output, variables, sequential execution, memory states',
        'Sequencing',
        SkillCategory.sequencing,
        5,
        statusFor(SkillCategory.sequencing),
      ),
      _module(
        'module_02',
        2,
        'The data blueprint',
        'Data types, arithmetic operators, user input, type casting',
        'Syntax',
        SkillCategory.syntax,
        6,
        statusFor(SkillCategory.syntax),
      ),
      _module(
        'module_03',
        3,
        'Branching realities',
        'Conditionals, relational & logical operators, if/elif/else',
        'Logic Flow',
        SkillCategory.logicFlow,
        7,
        statusFor(SkillCategory.logicFlow),
      ),
      _module(
        'module_04',
        4,
        'Cycles and simulations',
        'For loops, while loops, range(), break, continue, pass',
        'Logic Flow',
        SkillCategory.logicFlow,
        8,
        statusFor(SkillCategory.logicFlow),
      ),
      _module(
        'module_05',
        5,
        'Architects of abstraction',
        'Functions, parameters, return values, local vs global scope',
        'Computational Thinking',
        SkillCategory.computationalThinking,
        8,
        statusFor(SkillCategory.computationalThinking),
      ),
      _module(
        'module_06',
        6,
        'Textual forensics',
        'String methods, indexing, slicing, immutability, escape chars',
        'Syntax',
        SkillCategory.syntax,
        6,
        statusFor(SkillCategory.syntax),
      ),
      _module(
        'module_07',
        7,
        'The data arsenal',
        'Lists, tuples, indexing, list methods, iteration',
        'Sequencing',
        SkillCategory.sequencing,
        8,
        statusFor(SkillCategory.sequencing),
      ),
      _module(
        'module_08',
        8,
        'Associative architecture',
        'Dictionaries, sets, key-value pairs, .keys()/.values()/.items()',
        'Computational Thinking',
        SkillCategory.computationalThinking,
        7,
        statusFor(SkillCategory.computationalThinking),
      ),
      _module(
        'module_09',
        9,
        'Resilience and resolution',
        'try/except/else/finally, error types, reading tracebacks',
        'Debugging',
        SkillCategory.debugging,
        6,
        statusFor(SkillCategory.debugging),
      ),
      _module(
        'module_10',
        10,
        'The giant\'s shoulders',
        'import, math/random/datetime modules, reading documentation',
        'Computational Thinking',
        SkillCategory.computationalThinking,
        5,
        statusFor(SkillCategory.computationalThinking),
      ),
      _module(
        'module_11',
        11,
        'Persistent memory',
        'File I/O, open(), read/write/append, context managers (with)',
        'Sequencing',
        SkillCategory.sequencing,
        6,
        statusFor(SkillCategory.sequencing),
      ),
      _module(
        'module_12',
        12,
        'Paradigms of objects',
        'Classes, __init__, instance attributes, methods, instantiation',
        'Computational Thinking',
        SkillCategory.computationalThinking,
        8,
        statusFor(SkillCategory.computationalThinking),
      ),
    ];

    // ── Mark the first required module as the entry point ─────────────────────
    final firstRequiredIndex = rawModules.indexWhere(
      (m) => m.status == ModuleStatus.required,
    );

    if (firstRequiredIndex == -1) {
      // Edge case: user is Confident in all skills — mark M1 as start anyway
      rawModules[0] = _copyWithStartHere(rawModules[0]);
    } else {
      rawModules[firstRequiredIndex] = _copyWithStartHere(
        rawModules[firstRequiredIndex],
      );
    }

    return rawModules;
  }

  // ─────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────

  /// Factory shorthand for building a [LearningModule].
  LearningModule _module(
    String moduleId,
    int number,
    String name,
    String description,
    String tagLabel,
    SkillCategory skill,
    int lessons,
    ModuleStatus status,
  ) {
    return LearningModule(
      moduleId: moduleId,
      number: number,
      name: name,
      description: description,
      tagLabel: tagLabel,
      skill: skill,
      estimatedLessons: lessons,
      status: status,
    );
  }

  /// Returns a copy of [module] with [isStartHere] set to true.
  /// LearningModule is const so we rebuild it manually.
  LearningModule _copyWithStartHere(LearningModule module) {
    return LearningModule(
      moduleId: module.moduleId,
      number: module.number,
      name: module.name,
      description: module.description,
      tagLabel: module.tagLabel,
      skill: module.skill,
      estimatedLessons: module.estimatedLessons,
      status: module.status,
      isStartHere: true,
    );
  }

  // ─────────────────────────────────────────────────────
  // Convenience display helpers (used directly by the UI)
  // ─────────────────────────────────────────────────────

  /// Human-readable label for a [SkillLevel].
  static String skillLevelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.developing:
        return 'Developing';
      case SkillLevel.building:
        return 'Building';
      case SkillLevel.confident:
        return 'Confident';
    }
  }

  /// Human-readable label for a [LearnerProfile].
  static String profileLabel(LearnerProfile profile) {
    switch (profile) {
      case LearnerProfile.beginner:
        return 'Beginner';
      case LearnerProfile.novice:
        return 'Novice';
      case LearnerProfile.intermediate:
        return 'Intermediate';
    }
  }

  /// Subtitle shown on the result card per profile.
  static String profileSubtitle(LearnerProfile profile) {
    switch (profile) {
      case LearnerProfile.beginner:
        return 'Your path starts from the fundamentals — a solid foundation awaits.';
      case LearnerProfile.novice:
        return 'You have partial foundations — some modules are fast-forwarded.';
      case LearnerProfile.intermediate:
        return 'Strong foundations — your path skips several intro modules.';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Veto: Reset to beginner path ─────────────────────────────────────────

  /// Clears all auto-unlocked modules (except module_01) so the user
  /// starts from Day 1. Called when user taps "No, I'd like to review" on
  /// the DiagnosticResultsReviewScreen.
  Future<void> resetToBeginnerPath() async {
    final uid = ModuleUnlockService.instance.currentUserId;
    if (uid == 'anonymous') return;

    final db = await AppDatabase.instance.database;

    // Remove all auto-unlocked entries (keep any manually unlocked via quiz_pass)
    await db.delete(
      'module_unlocks',
      where: 'learner_id = ? AND unlock_reason != ?',
      whereArgs: [uid, 'quiz_passed'],
    );

    // Ensure module_01 is unlocked as the entry point
    await ModuleUnlockService.instance.unlockModule(
      'module_01',
      reason: 'beginner_reset',
    );

    // Update the in-memory result to reflect beginner profile
      final updatedPath = _result!.learningPath.map((m) {
        final isFirst = m.moduleId == 'module_01';
        return LearningModule(
          moduleId: m.moduleId,
          number: m.number,
          name: m.name,
          description: m.description,
          tagLabel: m.tagLabel,
          skill: m.skill,
          estimatedLessons: m.estimatedLessons,
          status: isFirst ? ModuleStatus.required : ModuleStatus.locked,
          isStartHere: isFirst,
        );
      }).toList();
      _result = DiagnosticResult(
        profile: LearnerProfile.beginner,
        learningPath: updatedPath,
        skillResults: _result!.skillResults,
      );

    notifyListeners();
    debugPrint('LearningPathController: Reset to beginner path');
  }
}
