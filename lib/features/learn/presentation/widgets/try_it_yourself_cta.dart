// lib/features/learn/presentation/widgets/try_it_yourself_cta.dart
// Deprecated — the interactive coding exercise is no longer part of the lesson
// flow. Completion is now driven by the embedded 3-question quiz in
// LessonViewerScreen. This stub is kept so imports in lesson_screen.dart
// (also deprecated) continue to compile.
import 'package:flutter/material.dart';

class TryItYourselfCta extends StatelessWidget {
  final String moduleId;
  final int lessonNumber;
  final int totalLessonsInModule;

  const TryItYourselfCta({
    super.key,
    required this.moduleId,
    required this.lessonNumber,
    required this.totalLessonsInModule,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
