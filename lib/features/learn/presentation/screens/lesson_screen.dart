// lib/features/learn/presentation/screens/lesson_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../components/navigation/app_top_bar.dart';
import '../../../../core/data/local_database.dart';
import '../controllers/lesson_controller.dart';
import '../../data/services/lesson_completion_service.dart';
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
  late final LocalDatabase _db;
  late final LessonCompletionService _completionService;
  late final LessonController _controller;

  @override
  void initState() {
    super.initState();
    _db = LocalDatabase();
    _completionService = LessonCompletionService(_db);
    _controller = LessonController(_completionService);
    _controller.loadLesson(widget.moduleId, widget.lessonId);

    // Mark this lesson as the last viewed immediately on open.
    _completionService.saveProgress(widget.moduleId, widget.lessonId);
  }

  @override
  void dispose() {
    // Auto-save progress when the user navigates away (back, tab switch, etc.)
    _completionService.saveProgress(widget.moduleId, widget.lessonId);
    _controller.dispose();
    super.dispose();
  }

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
        body: Consumer<LessonController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary));
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
                SliverToBoxAdapter(child: _buildStepDots()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      ConceptBlock(
                        heading: data.concept['heading'] ?? '',
                        body: data.concept['body'] ?? '',
                      ),
                      AnalogyCard(
                        heading: data.analogy['heading'] ?? '',
                        body: data.analogy['body'] ?? '',
                      ),
                      const SizedBox(height: 24),
                      AnnotatedCodeBlock(codeExample: data.codeExample),
                      CodeOutputBlock(output: data.expectedOutput),
                      KeyRuleBanner(ruleText: data.keyRule),
                      TryItYourselfCta(
                        rules: data.tryItYourself,
                        moduleId: widget.moduleId,
                        lessonNumber: widget.lessonNumber,
                        totalLessonsInModule: widget.totalLessonsInModule,
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStepDots() {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(widget.totalLessonsInModule, (index) {
          final stepNum = index + 1;
          final isCompleted = stepNum < widget.lessonNumber;
          final isCurrent = stepNum == widget.lessonNumber;

          Color dotColor;
          if (isCompleted) {
            dotColor = AppColors.success;
          } else if (isCurrent) {
            dotColor = AppColors.primary;
          } else {
            dotColor = AppColors.surfaceVariant;
          }

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isCurrent ? 12 : 8,
            height: isCurrent ? 12 : 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
