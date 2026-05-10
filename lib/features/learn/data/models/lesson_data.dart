// lib/features/learn/data/models/lesson_data.dart

// ─── Shared ───────────────────────────────────────────────────────────────────

class CodeAnnotation {
  final int line;
  final String note;

  const CodeAnnotation({required this.line, required this.note});

  factory CodeAnnotation.fromJson(Map<String, dynamic> json) =>
      CodeAnnotation(line: json['line'], note: json['note']);
}

class CodeExample {
  final String language;
  final String code;
  final List<CodeAnnotation> annotations;

  const CodeExample({
    required this.language,
    required this.code,
    required this.annotations,
  });

  factory CodeExample.fromJson(Map<String, dynamic> json) => CodeExample(
        language: json['language'],
        code: json['code'],
        annotations: (json['annotations'] as List)
            .map((a) => CodeAnnotation.fromJson(a))
            .toList(),
      );
}

// ─── Slide types ──────────────────────────────────────────────────────────────

class SlideData {
  final String slideId;
  final String slideType; // 'concept' | 'analogy' | 'code_example'
  final String? heading;
  final String? body;
  final String? language;
  final String? code;
  final List<CodeAnnotation> annotations;

  const SlideData({
    required this.slideId,
    required this.slideType,
    this.heading,
    this.body,
    this.language,
    this.code,
    this.annotations = const [],
  });

  factory SlideData.fromJson(Map<String, dynamic> json) => SlideData(
        slideId: json['slide_id'] as String,
        slideType: json['slide_type'] as String,
        heading: json['heading'] as String?,
        body: json['body'] as String?,
        language: json['language'] as String?,
        code: json['code'] as String?,
        annotations: json['annotations'] != null
            ? (json['annotations'] as List)
                .map((a) => CodeAnnotation.fromJson(a))
                .toList()
            : const [],
      );
}

// ─── Lesson-embedded quiz ─────────────────────────────────────────────────────

class LessonQuizQuestion {
  final String questionId;
  final String questionType; // 'multiple_choice' | 'fill_in_blank' | 'spot_bug'
  final String promptText;
  final Map<String, dynamic> content;
  final String correctAnswer;
  final int? correctIndex;
  final List<String>? options;
  final String explanation;

  const LessonQuizQuestion({
    required this.questionId,
    required this.questionType,
    required this.promptText,
    required this.content,
    required this.correctAnswer,
    this.correctIndex,
    this.options,
    required this.explanation,
  });

  factory LessonQuizQuestion.fromJson(Map<String, dynamic> json) {
    final type = json['question_type'] as String;
    final content = Map<String, dynamic>.from(json['content'] as Map);
    return LessonQuizQuestion(
      questionId: json['question_id'] as String,
      questionType: type,
      promptText: json['prompt_text'] as String,
      content: content,
      correctAnswer: (json['correct_answer'] ?? '').toString(),
      correctIndex: type == 'multiple_choice'
          ? content['correct_index'] as int?
          : null,
      options: type == 'multiple_choice' && content['options'] != null
          ? List<String>.from(content['options'] as List)
          : null,
      explanation: json['explanation'] as String,
    );
  }

  bool checkAnswer(dynamic userAnswer) {
    switch (questionType) {
      case 'multiple_choice':
        return userAnswer == correctIndex;
      case 'fill_in_blank':
      case 'spot_bug':
        return (userAnswer as String).trim().toLowerCase() ==
            correctAnswer.trim().toLowerCase();
      case 'parsons':
        return (userAnswer as String).trim() == correctAnswer.trim();
      case 'coding':
        return (userAnswer as String).trim().isNotEmpty;
      default:
        return false;
    }
  }
}

// ─── Lesson ───────────────────────────────────────────────────────────────────

class LessonData {
  final String lessonId;
  final String moduleId;
  final String lessonNumber; // "1.1", "1.2", etc.
  final String title;
  final String skillTag;
  final int estimatedMinutes;
  final List<SlideData> slides;
  final List<LessonQuizQuestion> quiz;
  final int completionXp;
  final bool isModuleCloser;

  const LessonData({
    required this.lessonId,
    required this.moduleId,
    required this.lessonNumber,
    required this.title,
    required this.skillTag,
    required this.estimatedMinutes,
    required this.slides,
    required this.quiz,
    required this.completionXp,
    required this.isModuleCloser,
  });

  factory LessonData.fromJson(Map<String, dynamic> json) => LessonData(
        lessonId: json['lesson_id'] as String,
        moduleId: json['module_id'] as String,
        lessonNumber: (json['lesson_number'] ?? '').toString(),
        title: json['title'] as String,
        skillTag: json['skill_tag'] as String,
        estimatedMinutes: json['estimated_minutes'] as int,
        slides: (json['slides'] as List)
            .map((s) => SlideData.fromJson(s as Map<String, dynamic>))
            .toList(),
        quiz: (json['quiz'] as List)
            .map((q) => LessonQuizQuestion.fromJson(q as Map<String, dynamic>))
            .toList(),
        completionXp: json['completion_xp'] as int,
        isModuleCloser: (json['is_module_closer'] ?? false) as bool,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Module-level quiz models (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

enum QuestionType { multipleChoice, parsons, fillBlank }

class ParsonsBlock {
  final String id;
  final String code;

  const ParsonsBlock({required this.id, required this.code});

  factory ParsonsBlock.fromJson(Map<String, dynamic> json) =>
      ParsonsBlock(id: json['id'], code: json['code']);
}

class QuizQuestion {
  final String id;
  final QuestionType type;
  final String skillTag;
  final int difficulty;
  final String prompt;
  final String explanation;

  // Multiple choice fields
  final List<String>? options;
  final int? correctIndex;

  // Parsons fields
  final List<ParsonsBlock>? blocks;
  final List<String>? correctOrder;

  // Fill blank fields
  final String? answer;

  const QuizQuestion({
    required this.id,
    required this.type,
    required this.skillTag,
    required this.difficulty,
    required this.prompt,
    required this.explanation,
    this.options,
    this.correctIndex,
    this.blocks,
    this.correctOrder,
    this.answer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = switch (typeStr) {
      'multiple_choice' => QuestionType.multipleChoice,
      'parsons' => QuestionType.parsons,
      'fill_blank' => QuestionType.fillBlank,
      _ => QuestionType.multipleChoice,
    };

    return QuizQuestion(
      id: json['id'],
      type: type,
      skillTag: json['skill_tag'],
      difficulty: json['difficulty'],
      prompt: json['prompt'],
      explanation: json['explanation'],
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
      correctIndex: json['correct_index'],
      blocks: json['blocks'] != null
          ? (json['blocks'] as List)
              .map((b) => ParsonsBlock.fromJson(b))
              .toList()
          : null,
      correctOrder: json['correct_order'] != null
          ? List<String>.from(json['correct_order'])
          : null,
      answer: json['answer'],
    );
  }

  bool checkAnswer(dynamic userAnswer) {
    return switch (type) {
      QuestionType.multipleChoice => userAnswer == correctIndex,
      QuestionType.fillBlank =>
        (userAnswer as String).trim().toLowerCase() ==
            answer!.trim().toLowerCase(),
      QuestionType.parsons =>
        listEquals(userAnswer as List<String>, correctOrder!),
    };
  }
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class QuizRemediationConfig {
  final String nextModuleId;
  final String? awardBadge;
  final int xpReward;
  final String message;
  final String? remediationModuleId;
  final bool retryAllowed;
  final int maxRetries;
  final String forceUnlockAfterRetries;

  const QuizRemediationConfig({
    required this.nextModuleId,
    this.awardBadge,
    required this.xpReward,
    required this.message,
    this.remediationModuleId,
    this.retryAllowed = true,
    this.maxRetries = 2,
    required this.forceUnlockAfterRetries,
  });
}

class QuizData {
  final String quizId;
  final String moduleId;
  final String title;
  final int timeLimitSeconds;
  final int passingScorePercent;
  final List<QuizQuestion> questions;

  // Adaptive routing on pass
  final String onPassNextModuleId;
  final String? onPassBadgeId;
  final int onPassXp;

  // Adaptive routing on fail
  final String onFailRemediationModuleId;
  final int maxRetries;
  final String forceUnlockAfterRetries;

  const QuizData({
    required this.quizId,
    required this.moduleId,
    required this.title,
    required this.timeLimitSeconds,
    required this.passingScorePercent,
    required this.questions,
    required this.onPassNextModuleId,
    this.onPassBadgeId,
    required this.onPassXp,
    required this.onFailRemediationModuleId,
    required this.maxRetries,
    required this.forceUnlockAfterRetries,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    final remediation = json['adaptive_remediation'];
    final onPass = remediation['on_pass'];
    final onFail = remediation['on_fail'];

    return QuizData(
      quizId: json['quiz_id'],
      moduleId: json['module_id'],
      title: json['title'],
      timeLimitSeconds: json['time_limit_seconds'],
      passingScorePercent: json['passing_score_percent'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      onPassNextModuleId: onPass['next_module_id'],
      onPassBadgeId: onPass['award_badge'],
      onPassXp: onPass['xp_reward'],
      onFailRemediationModuleId: onFail['remediation_module_id'],
      maxRetries: onFail['max_retries'] ?? 2,
      forceUnlockAfterRetries: onFail['force_unlock_after_retries'],
    );
  }
}
