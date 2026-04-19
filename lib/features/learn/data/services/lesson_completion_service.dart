// lib/features/learn/data/services/lesson_completion_service.dart
import '../../../../core/data/local_database.dart';
import '../../../../core/data/models/result_models.dart';

class LessonCompletionService {
  final LocalDatabase _db;

  LessonCompletionService(this._db);

  Future<LessonCompletionResult> completeLesson(String lessonId) async {
    // 1. Mark lesson complete in local DB
    await _db.markLessonComplete(lessonId, completedAt: DateTime.now());

    // 2. Update module progress
    final moduleId = _moduleIdFromLesson(lessonId);
    final progress = await _db.getModuleProgress(moduleId);

    // 3. Check if this was the last lesson
    final module = await _db.getModule(moduleId);
    final isLastLesson = progress.completedLessons >= module.lessonCount;

    if (isLastLesson) {
      // 4. Unlock the quiz for this module
      await _db.unlockQuiz('${moduleId}_quiz');
      return LessonCompletionResult.triggerQuiz;
    }

    // 5. Unlock the next lesson
    final nextLessonId = _getNextLessonId(lessonId);
    await _db.unlockLesson(nextLessonId);
    return LessonCompletionResult.nextLesson(nextLessonId);
  }

  // ── Progress auto-save / resume ──────────────────────────────────────────

  /// Save the current position so we can resume from here later.
  Future<void> saveProgress(String moduleId, String lessonId) async {
    await _db.saveLastViewedLesson(moduleId, lessonId);
  }

  /// Returns the lessonId to resume from, or null to start from the beginning.
  String? getResumeLesson(String moduleId) {
    return _db.getLastViewedLesson(moduleId);
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Derives the moduleId from a lessonId like 'module_01_l03' → 'module_01'
  String _moduleIdFromLesson(String lessonId) =>
      lessonId.split('_l').first;

  /// Derives the next sequential lessonId.
  /// e.g. 'module_01_l02' → 'module_01_l03'
  String _getNextLessonId(String lessonId) {
    final parts = lessonId.split('_l');
    if (parts.length != 2) return lessonId;
    final moduleId = parts[0];
    final lessonNum = int.tryParse(parts[1]) ?? 1;
    final nextNum = (lessonNum + 1).toString().padLeft(2, '0');
    return '${moduleId}_l$nextNum';
  }
}