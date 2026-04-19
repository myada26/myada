// lib/features/learn/presentation/widgets/try_it_yourself_cta.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../main.dart';
import '../../../../core/data/models/result_models.dart';
import '../controllers/lesson_controller.dart';
import '../../data/models/lesson_data.dart';

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

  Future<void> _handleSubmit(BuildContext context) async {
    final controller = context.read<LessonController>();
    final result = await controller.submitCode();

    if (!mounted) return;

    if (result == null) {
      // Validation failed — error is shown in the UI, stay on screen
      return;
    }

    if (result.isQuiz) {
      // Last lesson done — celebrate then push to quiz when it's built
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Module complete! Quiz coming soon.'),
          backgroundColor: Color(0xFF1ABC9C),
          duration: Duration(seconds: 3),
        ),
      );
      // TODO: replace with Navigator.pushNamed(context, AppRoutes.quiz, ...)
      // when the quiz screen is built.
    } else if (result.isNextLesson) {
      // Push the next lesson — same module, incremented number
      final nextLessonId = result.nextLessonId!;
      final nextNumber = widget.lessonNumber + 1;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.lesson,
        arguments: {
          'lessonId': nextLessonId,
          'moduleId': widget.moduleId,
          'lessonNumber': nextNumber,
          'totalLessonsInModule': widget.totalLessonsInModule,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LessonController>();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _codeController,
              onChanged: controller.updateUserCode,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // Success banner
          if (controller.isSuccess) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF1ABC9C), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Looks good! Moving on…',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF0E6251),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.error!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: controller.isSuccess ? 'Next Lesson →' : 'Run & Submit',
              onPressed: () => _handleSubmit(context),
            ),
          ),
        ],
      ),
    );
  }
}

