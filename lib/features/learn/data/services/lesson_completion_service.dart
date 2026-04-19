// lib/features/learn/data/services/lesson_completion_service.dart
import '../../../../core/data/local_database.dart';
import '../../../../core/data/models/result_models.dart';
import 'progress_service.dart';

class LessonCompletionService {
  final LocalDatabase _db;
  final ProgressService _progressService = ProgressService.instance;

  LessonCompletionService(this._db);

  /// Mark [lessonId] complete, check if the module is finished,
  /// and return what happens next.
  ///
  /// [moduleId] and [lessonId] must be the canonical controller IDs
  /// (e.g. "module_01", "module_01_l05") — not the JSON-internal IDs.
  /// [totalLessons] is read from meta.json by [LessonController].
  Future<LessonCompletionResult> completeLesson(
    String moduleId,
    String lessonId, {
    required int totalLessons,
  }) async {
    // 1. Count how many lessons are completed in sqflite for this module.
    //    ProgressService.markLessonComplete() was already called by the
    //    controller before this method — so the current lesson is included.
    final completedCount = await _progressService.getCompletedLessonCount(
      moduleId,
    );

    // 2. Check using the authoritative count from meta.json (passed in).
    final isLastLesson = completedCount >= totalLessons;

    if (isLastLesson) {
      // 3. Unlock the quiz for this module (Hive, for backwards compat).
      await _db.unlockQuiz('${moduleId}_quiz');
      return LessonCompletionResult.triggerQuiz;
    }

    // 4. Build and unlock the next lesson.
    final parts   = lessonId.split('_l');
    final nextNum = ((int.tryParse(parts.last) ?? 1) + 1)
        .toString()
        .padLeft(2, '0');
    final nextLessonId = '${moduleId}_l$nextNum';
    await _db.unlockLesson(nextLessonId);
    return LessonCompletionResult.nextLesson(nextLessonId);
  }

  /// Save the current position so we can resume from here later.
  Future<void> saveProgress(String moduleId, String lessonId) async {
    await _progressService.saveLastViewed(moduleId, lessonId);
  }

  /// Returns the lessonId to resume from, or null to start from the beginning.
  Future<String?> getResumeLesson(String moduleId) async {
    return _progressService.getLastViewedLesson(moduleId);
  }

}

