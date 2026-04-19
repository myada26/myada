// lib/shared/models/module_model.dart

/// Skill category tags — mirrors the diagnostic engine categories.
enum SkillTag {
  sequencing,
  logicFlow,
  debugging,
  syntax,
  computationalThinking,
}

extension SkillTagLabel on SkillTag {
  String get label {
    switch (this) {
      case SkillTag.sequencing:
        return 'Sequencing';
      case SkillTag.logicFlow:
        return 'Logic Flow';
      case SkillTag.debugging:
        return 'Debugging';
      case SkillTag.syntax:
        return 'Syntax';
      case SkillTag.computationalThinking:
        return 'Comp. Thinking';
    }
  }
}

/// Module completion status
enum ModuleStatus {
  locked,
  available,
  inProgress,
  completed,
  mastered, // Skipped via diagnostic — already proven
}

/// A single learning module (one of the 12 in the curriculum).
class ModuleModel {
  final String id;
  final int number; // 1–12
  final String title;
  final String subtitle;
  final SkillTag skillTag;
  final List<LessonModel> lessons;
  final ModuleStatus status;

  /// Score earned on the module quiz (0–100), null if not taken
  final int? quizScore;

  const ModuleModel({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.skillTag,
    required this.lessons,
    this.status = ModuleStatus.locked,
    this.quizScore,
  });

  int get totalLessons => lessons.length;

  int get completedLessons =>
      lessons.where((l) => l.isCompleted).length;

  double get progressPercent =>
      totalLessons == 0 ? 0 : completedLessons / totalLessons;

  bool get isUnlocked =>
      status == ModuleStatus.available ||
      status == ModuleStatus.inProgress ||
      status == ModuleStatus.completed ||
      status == ModuleStatus.mastered;

  ModuleModel copyWith({
    ModuleStatus? status,
    int? quizScore,
    List<LessonModel>? lessons,
  }) {
    return ModuleModel(
      id: id,
      number: number,
      title: title,
      subtitle: subtitle,
      skillTag: skillTag,
      lessons: lessons ?? this.lessons,
      status: status ?? this.status,
      quizScore: quizScore ?? this.quizScore,
    );
  }
}

/// A single lesson within a module.
class LessonModel {
  final String id;
  final int order;
  final String title;
  final LessonType type;
  final bool isCompleted;
  final bool isBookmarked;

  const LessonModel({
    required this.id,
    required this.order,
    required this.title,
    required this.type,
    this.isCompleted = false,
    this.isBookmarked = false,
  });

  LessonModel copyWith({
    bool? isCompleted,
    bool? isBookmarked,
  }) {
    return LessonModel(
      id: id,
      order: order,
      title: title,
      type: type,
      isCompleted: isCompleted ?? this.isCompleted,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}

enum LessonType {
  reading,    // Text + code blocks
  coding,     // Interactive code editor
  quiz,       // Multiple choice / Parson's / fill-in
  challenge,  // Timed programming challenge
}
