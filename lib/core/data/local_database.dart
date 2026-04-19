// lib/core/data/local_database.dart
// ─────────────────────────────────────────────────────────────────────────────
// Hive-backed local progress store.
// All keys are UID-scoped so multiple users on the same device stay isolated.
// Call LocalDatabase.setUserId(uid) after every successful auth event.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:hive_flutter/hive_flutter.dart';

// ── Plain data classes (no Hive adapters needed) ─────────────────────────────

class ModuleProgress {
  final String moduleId;
  final int completedLessons;
  const ModuleProgress({required this.moduleId, required this.completedLessons});
}

class ModuleMeta {
  final String moduleId;
  final int lessonCount;
  const ModuleMeta({required this.moduleId, required this.lessonCount});
}

// ── LocalDatabase ─────────────────────────────────────────────────────────────

class LocalDatabase {
  static const _progressBox   = 'lesson_progress';
  static const _quizBox       = 'quiz_results';
  static const _unlocksBox    = 'unlock_state';
  static const _diagnosticBox = 'diagnostic_data';

  /// Current user UID — set this immediately after every successful auth.
  static String _uid = 'anonymous';

  static void setUserId(String uid) {
    _uid = uid;
  }

  /// Prefix every key with the user's UID so data is fully isolated.
  String _k(String key) => '${_uid}_$key';

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.openBox<Map>(_progressBox);
    await Hive.openBox<Map>(_quizBox);
    await Hive.openBox<bool>(_unlocksBox);
    await Hive.openBox<Map>(_diagnosticBox);
  }

  Box<Map>  get _progress   => Hive.box<Map>(_progressBox);
  Box<Map>  get _quiz       => Hive.box<Map>(_quizBox);
  Box<bool> get _unlocks    => Hive.box<bool>(_unlocksBox);
  Box<Map>  get _diagnostic => Hive.box<Map>(_diagnosticBox);

  // ── Wipe all data for the current user ────────────────────────────────────
  // Called from AuthController.logout() to clear progress on sign-out.

  Future<void> clearAllUserData() async {
    // Remove every key that belongs to the current UID.
    final prefix = '${_uid}_';

    final progressKeys = _progress.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    await _progress.deleteAll(progressKeys);

    final quizKeys = _quiz.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    await _quiz.deleteAll(quizKeys);

    final unlockKeys = _unlocks.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    await _unlocks.deleteAll(unlockKeys);

    final diagKeys = _diagnostic.keys
        .where((k) => k.toString().startsWith(prefix))
        .toList();
    await _diagnostic.deleteAll(diagKeys);
  }

  // ── Diagnostic Progress ───────────────────────────────────────────────────

  Future<void> saveDiagnosticProgress(Map<int, double> scores, List<int> skips) async {
    await _diagnostic.put(_k('results'), {
      'scores': scores,
      'skips': skips,
    });
  }

  Map? getDiagnosticProgress() {
    return _diagnostic.get(_k('results'));
  }

  // ── Lesson progress ────────────────────────────────────────────────────────

  Future<void> markLessonComplete(
    String lessonId, {
    required DateTime completedAt,
  }) async {
    final moduleId = _moduleIdFromLesson(lessonId);
    final key = _k('module_$moduleId');
    final existing = _progress.get(key) ?? {};
    final data = Map<String, dynamic>.from(existing);
    final lessons = List<String>.from(data['lessons'] as List? ?? []);
    if (!lessons.contains(lessonId)) lessons.add(lessonId);
    data['lessons'] = lessons;
    // Also update last viewed when completing
    data['last_lesson'] = lessonId;
    await _progress.put(key, data);
  }

  Future<ModuleProgress> getModuleProgress(String moduleId) async {
    final key = _k('module_$moduleId');
    final data = _progress.get(key) ?? {};
    final lessons = List<String>.from(data['lessons'] as List? ?? []);
    return ModuleProgress(moduleId: moduleId, completedLessons: lessons.length);
  }

  /// Returns a stub ModuleMeta — extend the map as new modules are added.
  Future<ModuleMeta> getModule(String moduleId) async {
    const counts = <String, int>{
      'module_01': 5,
    };
    return ModuleMeta(
      moduleId: moduleId,
      lessonCount: counts[moduleId] ?? 5,
    );
  }

  // ── Lesson resume tracking ─────────────────────────────────────────────────

  /// Persists the last lesson the user had open in a module.
  /// Called from LessonScreen.dispose() and on navigation away.
  Future<void> saveLastViewedLesson(String moduleId, String lessonId) async {
    final key = _k('module_$moduleId');
    final existing = _progress.get(key) ?? {};
    final data = Map<String, dynamic>.from(existing);
    data['last_lesson'] = lessonId;
    await _progress.put(key, data);
  }

  /// Returns the last lessonId the user opened in this module, or null if none.
  String? getLastViewedLesson(String moduleId) {
    final key = _k('module_$moduleId');
    final data = _progress.get(key);
    if (data == null) return null;
    return data['last_lesson'] as String?;
  }

  // ── Quiz & unlock state ────────────────────────────────────────────────────

  Future<void> unlockQuiz(String quizId) async {
    await _unlocks.put(_k('quiz_$quizId'), true);
  }

  Future<void> unlockLesson(String lessonId) async {
    await _unlocks.put(_k('lesson_$lessonId'), true);
  }

  Future<void> unlockModule(String moduleId) async {
    await _unlocks.put(_k('module_$moduleId'), true);
  }

  Future<void> unlockRemediationModule(
    String moduleId, {
    List<String> failedSkillTags = const [],
  }) async {
    await _unlocks.put(_k('remediation_$moduleId'), true);
  }

  bool isQuizUnlocked(String quizId)    => _unlocks.get(_k('quiz_$quizId'))    ?? false;
  bool isLessonUnlocked(String lessonId) => _unlocks.get(_k('lesson_$lessonId')) ?? true;
  bool isModuleUnlocked(String moduleId) => _unlocks.get(_k('module_$moduleId')) ?? false;

  // ── Quiz results ───────────────────────────────────────────────────────────

  Future<void> saveQuizResult(
    String quizId,
    double score,
    List<String> failedTags,
  ) async {
    await _quiz.put(_k(quizId), {
      'score': score,
      'failedTags': failedTags,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> awardBadge(String? badgeId) async {
    if (badgeId == null) return;
    await _unlocks.put(_k('badge_$badgeId'), true);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Derives moduleId from a lessonId: 'module_01_l03' → 'module_01'
  String _moduleIdFromLesson(String lessonId) =>
      lessonId.split('_l').first;
}
