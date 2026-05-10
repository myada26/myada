// lib/core/data/models/result_models.dart
// ─────────────────────────────────────────────────────────────
// These are the routing result types returned by LessonCompletionService
// and QuizResultService. They tell the UI *what to do next*.
// ─────────────────────────────────────────────────────────────

/// Returned by LessonCompletionService.completeLesson()
class LessonCompletionResult {
  final LessonCompletionAction action;
  final String? nextLessonId;

  const LessonCompletionResult._({
    required this.action,
    this.nextLessonId,
  });

  /// The user completed the last lesson — push them to the quiz now.
  static const triggerQuiz = LessonCompletionResult._(
    action: LessonCompletionAction.triggerQuiz,
  );

  /// There is a next lesson to unlock — go there.
  factory LessonCompletionResult.nextLesson(String nextLessonId) =>
      LessonCompletionResult._(
        action: LessonCompletionAction.nextLesson,
        nextLessonId: nextLessonId,
      );

  bool get isQuiz => action == LessonCompletionAction.triggerQuiz;
  bool get isNextLesson => action == LessonCompletionAction.nextLesson;
}

enum LessonCompletionAction { nextLesson, triggerQuiz }

// ─────────────────────────────────────────────────────────────

/// Returned by QuizResultService.processResult()
class QuizRoutingResult {
  final QuizRoutingAction action;
  final String? nextModuleId;
  final String? remediationModuleId;
  final List<String> failedTags;

  const QuizRoutingResult._({
    required this.action,
    this.nextModuleId,
    this.remediationModuleId,
    this.failedTags = const [],
  });

  factory QuizRoutingResult.pass({required String nextModuleId}) =>
      QuizRoutingResult._(
        action: QuizRoutingAction.pass,
        nextModuleId: nextModuleId,
      );

  factory QuizRoutingResult.remediation({
    required String remediationModuleId,
    required List<String> failedTags,
  }) =>
      QuizRoutingResult._(
        action: QuizRoutingAction.remediation,
        remediationModuleId: remediationModuleId,
        failedTags: failedTags,
      );

  bool get isPassed => action == QuizRoutingAction.pass;
  bool get isRemediation => action == QuizRoutingAction.remediation;
}

enum QuizRoutingAction { pass, remediation }

// ─────────────────────────────────────────────────────────────

/// A single question result used by QuizResultService._calculateScore
class QuestionResult {
  final String questionId;
  final String skillTag;
  final bool isCorrect;

  const QuestionResult({
    required this.questionId,
    required this.skillTag,
    required this.isCorrect,
  });
}
