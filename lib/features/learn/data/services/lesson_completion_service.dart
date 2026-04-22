// lib/features/learn/data/services/lesson_completion_service.dart
//
// All unlock state goes through sqflite (ModuleUnlockService).
// Hive / LocalDatabase is no longer used here.

import '../../../../core/data/models/result_models.dart';
import 'progress_service.dart';

class LessonCompletionService {
  final ProgressService _progressService = ProgressService.instance;

  LessonCompletionService();

  /// Mark [lessonId] complete, check if the module is finished,
  /// and return what the UI should do next.
  ///
  /// [moduleId] and [lessonId] must be canonical controller IDs
  /// (e.g. "module_01", "module_01_l05").
  /// [totalLessons] is read from meta.json by [LessonController].
  Future<LessonCompletionResult> completeLesson(
    String moduleId,
    String lessonId, {
    required int totalLessons,
  }) async {
    // Count how many lessons are completed in sqflite for this module.
    // ProgressService.markLessonComplete() was already called by the
    // controller before this method — so the current lesson is included.
    final completedCount = await _progressService.getCompletedLessonCount(
      moduleId,
    );

    final isLastLesson = completedCount >= totalLessons;

    if (isLastLesson) {
      // No Hive call — state is readable from lesson_progress row count.
      // The LearnScreen will detect readyForQuiz via ModuleUnlockService.
      return LessonCompletionResult.triggerQuiz;
    }

    // Build the next lesson ID.
    final parts   = lessonId.split('_l');
    final nextNum = ((int.tryParse(parts.last) ?? 1) + 1)
        .toString()
        .padLeft(2, '0');
    final nextLessonId = '${moduleId}_l$nextNum';
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
