// lib/features/learn/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../components/navigation/app_top_bar.dart';
import '../../../../core/data/local_database.dart';
import '../../../../main.dart';
import '../controllers/lesson_controller.dart';
import '../../data/services/lesson_completion_service.dart';
import '../../data/services/progress_service.dart';
import '../widgets/concept_block.dart';
import '../widgets/analogy_card.dart';
import '../widgets/annotated_code_block.dart';
import '../widgets/code_output_block.dart';
import '../widgets/key_rule_banner.dart';
import '../widgets/try_it_yourself_cta.dart';

class LessonScreen extends StatefulWidget {
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
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LocalDatabase           _db;
  late final LessonCompletionService _completionService;
  late final LessonController        _controller;

  @override
  void initState() {
    super.initState();
    _db                = LocalDatabase();
    _completionService = LessonCompletionService(_db);
    _controller        = LessonController(_completionService);
    _controller.loadLesson(widget.moduleId, widget.lessonId);

    // Auto-save "last viewed" the moment the user opens this lesson.
    ProgressService.instance.saveLastViewed(widget.moduleId, widget.lessonId);
  }

  @override
  void dispose() {
    // Auto-save again when the user navigates away for any reason.
    if (_controller.currentLessonId != null &&
        _controller.currentModuleId != null) {
      ProgressService.instance.saveLastViewed(
        _controller.currentModuleId!,
        _controller.currentLessonId!,
      );
    }
    _completionService.saveProgress(widget.moduleId, widget.lessonId);
    _controller.dispose();
    super.dispose();
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigateToLesson(String lessonId, int lessonNumber) {
    // Save last viewed before leaving
    ProgressService.instance.saveLastViewed(widget.moduleId, lessonId);

    Navigator.of(context).pushReplacementNamed(
      AppRoutes.lesson,
      arguments: {
        'lessonId': lessonId,
        'moduleId': widget.moduleId,
        'lessonNumber': lessonNumber,
        'totalLessonsInModule': _controller.totalLessons,
      },
    );
  }

  void _goPrevious() {
    if (!_controller.hasPreviousLesson) return;
    final prevNum = widget.lessonNumber - 1;
    final prevId  = '${widget.moduleId}_l${prevNum.toString().padLeft(2, '0')}';
    _navigateToLesson(prevId, prevNum);
  }

  void _goNext() {
    if (!_controller.hasNextLesson) return;
    final nextNum = widget.lessonNumber + 1;
    final nextId  = '${widget.moduleId}_l${nextNum.toString().padLeft(2, '0')}';
    _navigateToLesson(nextId, nextNum);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar.title(
          title: 'Lesson ${widget.lessonNumber}',
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark_border_rounded),
              color: AppColors.primaryForeground,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lesson bookmarked for offline study.')),
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            // ── Step-dot progress bar ──────────────────────────────────────
            Consumer<LessonController>(
              builder: (_, ctrl, __) => _buildStepDots(ctrl),
            ),

            // ── Main scrollable content ────────────────────────────────────
            Expanded(
              child: Consumer<LessonController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (controller.error != null && controller.lessonData == null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error loading lesson:\n${controller.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }

                  final data = controller.lessonData!;

                  return CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 24.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            ConceptBlock(
                              heading: data.concept['heading'] ?? '',
                              body:    data.concept['body']    ?? '',
                            ),
                            AnalogyCard(
                              heading: data.analogy['heading'] ?? '',
                              body:    data.analogy['body']    ?? '',
                            ),
                            const SizedBox(height: 24),
                            AnnotatedCodeBlock(codeExample: data.codeExample),
                            CodeOutputBlock(output: data.expectedOutput),
                            KeyRuleBanner(ruleText: data.keyRule),
                            TryItYourselfCta(
                              rules:                 data.tryItYourself,
                              moduleId:              widget.moduleId,
                              lessonNumber:          widget.lessonNumber,
                              totalLessonsInModule:  controller.totalLessons,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Back / Next navigation footer ──────────────────────────────
            Consumer<LessonController>(
              builder: (_, ctrl, __) => _buildNavFooter(ctrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDots(LessonController controller) {
    final total = controller.isLoading
        ? widget.totalLessonsInModule
        : controller.totalLessons;

    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final stepNum    = index + 1;
          final isComplete = stepNum < widget.lessonNumber;
          final isCurrent  = stepNum == widget.lessonNumber;

          final dotColor = isComplete
              ? AppColors.success
              : isCurrent
                  ? AppColors.primary
                  : AppColors.surfaceVariant;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width:  isCurrent ? 12 : 8,
            height: isCurrent ? 12 : 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          );
        }),
      ),
    );
  }

  Widget _buildNavFooter(LessonController controller) {
    if (controller.isLoading) return const SizedBox.shrink();

    return Container(
      color:   AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ← Back
            Expanded(
              child: controller.hasPreviousLesson
                  ? OutlinedButton.icon(
                      onPressed: _goPrevious,
                      icon:  const Icon(Icons.chevron_left_rounded, size: 20),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            if (controller.hasPreviousLesson && controller.hasNextLesson)
              const SizedBox(width: 12),

            // Next →  (review only — does NOT mark as complete)
            Expanded(
              child: controller.hasNextLesson
                  ? ElevatedButton.icon(
                      onPressed: _goNext,
                      icon:  const Text('Next'),
                      label: const Icon(Icons.chevron_right_rounded, size: 20),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
