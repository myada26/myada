// lib/features/learn/presentation/widgets/try_it_yourself_cta.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/engine/badge_engine.dart';
import '../../../../main.dart';
import '../controllers/lesson_controller.dart';
import '../../data/models/lesson_data.dart';
import '../../data/services/progress_service.dart';
import '../../../learn/presentation/screens/module_quiz_screen.dart';

class TryItYourselfCta extends StatefulWidget {
  final TryItYourself rules;
  final String moduleId;
  final int lessonNumber;
  final int totalLessonsInModule;

  const TryItYourselfCta({
    super.key,
    required this.rules,
    required this.moduleId,
    required this.lessonNumber,
    required this.totalLessonsInModule,
  });

  @override
  State<TryItYourselfCta> createState() => _TryItYourselfCtaState();
}

class _TryItYourselfCtaState extends State<TryItYourselfCta> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    final initial = context.read<LessonController>().userCode;
    _codeController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // ── Quiz navigation ───────────────────────────────────────────────────────

  Future<void> _navigateToQuiz(BuildContext context) async {
    // Load quiz questions from the module's quiz.json asset
    final folderName = widget.moduleId.replaceAll('_', '');
    List<Map<String, dynamic>> questions = [];
    String nextModuleId = '';

    try {
      final raw = await rootBundle.loadString(
          'assets/content/modules/$folderName/quiz.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rawQuestions = decoded['questions'] as List<dynamic>? ?? [];
      questions = rawQuestions
          .map<Map<String, dynamic>>((q) {
            final m = Map<String, dynamic>.from(q as Map);
            return {
              'id':            m['id'] ?? '',
              'prompt_text':   m['prompt'] ?? m['prompt_text'] ?? '',
              'question_type': m['type']   ?? m['question_type'] ?? 'multiple_choice',
              'content':       m,
              'correct_answer': m['correct_index']?.toString() ?? m['answer'] ?? '',
              'explanation':   m['explanation'] ?? '',
            };
          })
          .toList();

      // Parse nextModuleId for the post-quiz unlock
      final remediation =
          decoded['adaptive_remediation'] as Map<String, dynamic>? ?? {};
      final onPass = remediation['on_pass'] as Map<String, dynamic>? ?? {};
      nextModuleId = onPass['next_module_id'] as String? ?? '';
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load quiz: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ModuleQuizScreen(
          moduleId:       widget.moduleId,
          learnerId:      ProgressService.instance.currentUserId,
          questions:      questions,
          isFirstAttempt: true,
          hasStreak:      false,
          nextModuleId:   nextModuleId,
        ),
      ),
    );
  }

  // ── Submit handler ────────────────────────────────────────────────────────

  Future<void> _handleSubmit(BuildContext context) async {
    final controller = context.read<LessonController>();
    final result     = await controller.submitCode();

    if (!mounted) return;

    if (result == null) {
      // Validation failed — error shown in UI, stay on screen
      return;
    }

    // Award exercise completion points
    await PointsService.instance.addPoints(
      PointsService.exerciseComplete, 'exercise_complete',
    );

    // Check for exercise-related badges
    await BadgeEngine.instance.checkAndAward(
      'exercise_completed',
      context: {
        'isFirstTry': true,  // TODO: track actual first-try status
        'hintsUsed': 0,      // TODO: track actual hints used
        'isDebug': false,
        'isTimed': false,
        'completedInTime': false,
      },
    );

    if (result.isQuiz) {
      // All lessons complete — navigate to the module quiz
      await _navigateToQuiz(context);
    } else if (result.isNextLesson) {
      final nextLessonId = result.nextLessonId!;
      final nextNumber   = widget.lessonNumber + 1;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.lesson,
        arguments: {
          'lessonId':              nextLessonId,
          'moduleId':              widget.moduleId,
          'lessonNumber':          nextNumber,
          'totalLessonsInModule':  widget.totalLessonsInModule,
        },
      );
    }
  }

  // ── Widget ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();

    return Container(
      padding:    const EdgeInsets.all(20),
      margin:     const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color:        AppColors.surface,
        border:       Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.code_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text('Try it yourself', style: AppTextStyles.h2),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.rules.prompt,
            style: AppTextStyles.body.copyWith(color: AppColors.subtleForeground),
          ),

          // Hint
          if (widget.rules.hint.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '💡 ${widget.rules.hint}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Code editor
          Container(
            decoration: BoxDecoration(
              color:        const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _codeController,
              onChanged:  controller.updateUserCode,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                color:      Colors.white,
                fontSize:   14,
              ),
              decoration: const InputDecoration(
                border:         InputBorder.none,
                isDense:        true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Success banner
          if (controller.isSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding:    const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1ABC9C), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    controller.isLastLesson
                        ? '🎉 Module complete! Starting quiz…'
                        : 'Looks good! Moving on…',
                    style: AppTextStyles.caption.copyWith(
                      color:      const Color(0xFF0E6251),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error banner
          if (controller.error != null && !controller.isSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding:    const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.error!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Complete & Continue / Run & Submit button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: controller.isSuccess
                  ? (controller.isLastLesson ? 'Start Module Quiz →' : 'Next Lesson →')
                  : 'Run & Submit',
              onPressed: () => _handleSubmit(context),
            ),
          ),
        ],
      ),
    );
  }
}
