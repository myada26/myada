// lib/features/learn/data/models/lesson_data.dart

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

class TryItYourself {
  final String prompt;
  final String starterCode;
  final String hint;
  final String validationType;
  final Map<String, dynamic> validationRules;

  const TryItYourself({
    required this.prompt,
    required this.starterCode,
    required this.hint,
    required this.validationType,
    required this.validationRules,
  });

  factory TryItYourself.fromJson(Map<String, dynamic> json) => TryItYourself(
        prompt: json['prompt'],
        starterCode: json['starter_code'],
        hint: json['hint'],
        validationType: json['validation_type'],
        validationRules: json['validation_rules'] ?? {},
      );
}

class LessonData {
  final String lessonId;
  final String moduleId;
  final int lessonNumber;
  final String title;
  final String skillTag;
  final int estimatedMinutes;
  final Map<String, String> concept;       // {heading, body}
  final Map<String, String> analogy;       // {heading, body}
  final CodeExample codeExample;
  final String expectedOutput;
  final String keyRule;
  final TryItYourself tryItYourself;
  final int completionXp;
  final bool isBookmarkable;
  final bool isModuleCloser;

  const LessonData({
    required this.lessonId,
    required this.moduleId,
    required this.lessonNumber,
    required this.title,
    required this.skillTag,
    required this.estimatedMinutes,
    required this.concept,
    required this.analogy,
    required this.codeExample,
    required this.expectedOutput,
    required this.keyRule,
    required this.tryItYourself,
    required this.completionXp,
    required this.isBookmarkable,
    required this.isModuleCloser,
  });

  factory LessonData.fromJson(Map<String, dynamic> json) => LessonData(
        lessonId: json['lesson_id'],
        moduleId: json['module_id'],
        lessonNumber: json['lesson_number'],
        title: json['title'],
        skillTag: json['skill_tag'],
        estimatedMinutes: json['estimated_minutes'],
        concept: Map<String, String>.from(json['concept']),
        analogy: Map<String, String>.from(json['analogy']),
        codeExample: CodeExample.fromJson(json['code_example']),
        expectedOutput: json['expected_output'],
        keyRule: json['key_rule'],
        tryItYourself: TryItYourself.fromJson(json['try_it_yourself']),
        completionXp: json['completion_xp'],
        isBookmarkable: json['is_bookmarkable'] ?? true,
        isModuleCloser: json['is_module_closer'] ?? false,
      );
}

// ─────────────────────────────────────────────────────────────
// lib/features/quiz/data/models/quiz_data.dart

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