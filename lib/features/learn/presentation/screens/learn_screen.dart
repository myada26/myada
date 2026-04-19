// lib/features/learn/presentation/screens/learn_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/data/local_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/learn/data/services/progress_service.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../main.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  void _onDiagnosticTap(BuildContext context) {
    // Use the canonical working diagnostic flow (PreassessScreen → BriefScreen
    // → QuestionScreen → ResultScreen) instead of the legacy local screens.
    Navigator.of(context).pushNamed(AppRoutes.diagnostic);
  }

  @override
  Widget build(BuildContext context) {

    return Consumer<LearningPathController>(
      builder: (context, controller, child) {
        if (controller.isBuilding) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final learningPath = controller.result?.learningPath ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Learning Path',
                          style: AppTextStyles.displayMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.hasResult
                              ? 'Your personalized learning modules'
                              : 'Complete your diagnostic to unlock personalized modules',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _FilterChips()),
                if (!controller.hasResult)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _DiagnosticBanner(
                        onTap: () => _onDiagnosticTap(context),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList.separated(
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemCount: learningPath.length,
                    itemBuilder: (context, i) {
                      final module = learningPath[i];
                      final isUnlocked = module.status != ModuleStatus.locked;

                      return _ModuleCard(
                        number: module.number,
                        moduleId: module.moduleId,
                        title: module.name,
                        subtitle: module.description,
                        tag: module.tagLabel,
                        lessons: module.estimatedLessons,
                        icon: Icons.article_rounded,
                        isLocked: !isUnlocked,
                        isFirst: module.isStartHere,
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterChips extends StatefulWidget {
  @override
  State<_FilterChips> createState() => _FilterChipsState();
}

class _FilterChipsState extends State<_FilterChips> {
  int _selected = 0;
  static const filters = [
    'All',
    'Sequencing',
    'Logic Flow',
    'Syntax',
    'Debugging',
    'Comp. Thinking',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final selected = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                filters[i], // Using default text style, can be customized
                style: AppTextStyles.label.copyWith(
                  color: selected ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiagnosticBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnosticBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.accent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppColors.accent, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take the diagnostic first',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your path adapts to your skill level',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.accent,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final int number;
  final String moduleId;
  final String title;
  final String subtitle;
  final String tag;
  final int lessons;
  final IconData icon;
  final bool isLocked;
  final bool isFirst;

  const _ModuleCard({
    required this.number,
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.lessons,
    required this.icon,
    this.isLocked = true,
    this.isFirst = false,
  });

  /// Opens the module, resuming at the last-viewed lesson (sqflite-backed).
  Future<void> _openLesson(BuildContext context) async {
    // Prefer sqflite ProgressService; fall back to Hive LocalDatabase
    String? savedLessonId = await ProgressService.instance.getLastViewedLesson(
      moduleId,
    );
    savedLessonId ??= LocalDatabase().getLastViewedLesson(moduleId);

    final lessonId = savedLessonId ?? '${moduleId}_l01';
    final parts = lessonId.split('_l');
    final lessonNumber = parts.length == 2 ? (int.tryParse(parts[1]) ?? 1) : 1;

    if (!context.mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.lesson,
      arguments: {
        'lessonId': lessonId,
        'moduleId': moduleId,
        'lessonNumber': lessonNumber,
        'totalLessonsInModule': lessons,
      },
    );
  }

  Color get _tagColor {
    switch (tag) {
      case 'Sequencing':
        return AppColors.success;
      case 'Logic Flow':
        return AppColors.primary;
      case 'Syntax':
        return AppColors.primary; // Using primary for syntax
      case 'Debugging':
        return AppColors.error;
      case 'Comp. Thinking':
        return AppColors.warning;
      default:
        return AppColors.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isFirst ? () => _openLesson(context) : null,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isFirst
                  ? AppColors.primary.withOpacity(0.4)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Module number circle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isLocked
                      ? AppColors.surfaceElevated
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLocked
                    ? const Icon(
                        Icons.lock_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      )
                    : Center(
                        child: Text(
                          number.toString().padLeft(2, '0'),
                          style: AppTextStyles.headingMedium.copyWith(
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.headingSmall),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            tag,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _tagColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$lessons lessons',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                isFirst
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                color: isFirst ? AppColors.primary : AppColors.textMuted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
