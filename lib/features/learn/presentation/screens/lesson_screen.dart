// lib/features/learn/presentation/screens/lesson_screen.dart
// Deprecated — superseded by ModuleDetailScreen + LessonViewerScreen.
// Kept to avoid removing the named route handler; all navigation now goes
// through AppRoutes.moduleDetail → AppRoutes.lessonViewer.
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart';

class LessonScreen extends StatelessWidget {
  final String lessonId;
  final String moduleId;
  final int lessonNumber;
  final int totalLessonsInModule;

  const LessonScreen({
    super.key,
    required this.lessonId,
    required this.moduleId,
    required this.lessonNumber,
    required this.totalLessonsInModule,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect legacy deep-links to the new module detail screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.moduleDetail,
        arguments: {'moduleId': moduleId},
      );
    });
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
