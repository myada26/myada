// lib/features/learn/presentation/screens/learn_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../components/cards/app_cards.dart'; // For BasicCard or similar
import '../../../../components/buttons/app_button.dart'; // For AppButton
import '../../../../main.dart'; // For AppRoutes
import '../../../../core/data/local_database.dart'; // For resume logic

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  // Module data structure — ready for real content
  static const _modules = [
    (
      moduleId: 'module_01',
      title: 'The Genesis of Execution',
      subtitle: 'Output and Memory',
      tag: 'Sequencing',
      lessons: 5,
      icon: Icons.play_circle_outline_rounded,
    ),
    (
      moduleId: 'module_02',
      title: 'The Data Blueprint',
      subtitle: 'Types and Operations',
      tag: 'Syntax',
      lessons: 6,
      icon: Icons.data_object_rounded,
    ),
    (
      moduleId: 'module_03',
      title: 'Branching Realities',
      subtitle: 'Conditional Logic',
      tag: 'Logic Flow',
      lessons: 7,
      icon: Icons.account_tree_rounded,
    ),
    (
      moduleId: 'module_04',
      title: 'Cycles and Simulations',
      subtitle: 'Iteration and Loops',
      tag: 'Logic Flow',
      lessons: 8,
      icon: Icons.loop_rounded,
    ),
    (
      moduleId: 'module_05',
      title: 'Architects of Abstraction',
      subtitle: 'Functions and Scope',
      tag: 'Comp. Thinking',
      lessons: 8,
      icon: Icons.functions_rounded,
    ),
    (
      moduleId: 'module_06',
      title: 'Textual Forensics',
      subtitle: 'Advanced String Manipulation',
      tag: 'Syntax',
      lessons: 6,
      icon: Icons.text_fields_rounded,
    ),
    (
      moduleId: 'module_07',
      title: 'The Data Arsenal',
      subtitle: 'Lists and Tuples',
      tag: 'Sequencing',
      lessons: 8,
      icon: Icons.list_alt_rounded,
    ),
    (
      moduleId: 'module_08',
      title: 'Associative Architecture',
      subtitle: 'Dictionaries and Sets',
      tag: 'Comp. Thinking',
      lessons: 7,
      icon: Icons.key_rounded,
    ),
    (
      moduleId: 'module_09',
      title: 'Resilience and Resolution',
      subtitle: 'Error Handling',
      tag: 'Debugging',
      lessons: 6,
      icon: Icons.bug_report_rounded,
    ),
    (
      moduleId: 'module_10',
      title: "The Giant's Shoulders",
      subtitle: 'Modules and Libraries',
      tag: 'Comp. Thinking',
      lessons: 5,
      icon: Icons.extension_rounded,
    ),
    (
      moduleId: 'module_11',
      title: 'Persistent Memory',
      subtitle: 'File Input and Output',
      tag: 'Sequencing',
      lessons: 6,
      icon: Icons.save_rounded,
    ),
    (
      moduleId: 'module_12',
      title: 'Paradigms of Objects',
      subtitle: 'Introduction to OOP',
      tag: 'Comp. Thinking',
      lessons: 8,
      icon: Icons.category_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Learning Path', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Complete your diagnostic to unlock personalized modules',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips
            SliverToBoxAdapter(
              child: _FilterChips(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),

            // Diagnostic CTA banner
            SliverToBoxAdapter(
              child: _DiagnosticBanner(),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.md),
            ),

            // Module list
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              sliver: SliverList.separated(
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemCount: _modules.length,
                itemBuilder: (context, i) {
                  final m = _modules[i];
                  return _ModuleCard(
                    number: i + 1,
                    moduleId: m.moduleId,
                    title: m.title,
                    subtitle: m.subtitle,
                    tag: m.tag,
                    lessons: m.lessons,
                    icon: m.icon,
                    isLocked: true, // All locked until diagnostic done
                    isFirst: i == 0,
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
            horizontal: AppSpacing.md, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final selected = _selected == i;
          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Text(
                filters[i], // Using default text style, can be customized
                style: AppTextStyles.label.copyWith(
                  color: selected
                      ? Colors.white
                      : AppColors.mutedForeground,
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
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.diagnostic);
        },
        child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.psychology_rounded,
                color: AppColors.accent, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Take the diagnostic first',
                      style: AppTextStyles.label.copyWith(color: AppColors.accent)),
                  const SizedBox(height: 2),
                  Text(
                    'Your path adapts to your skill level',
                    style: AppTextStyles.bodySm,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.accent, size: 14),
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

  /// Builds the lessonId and lessonNumber from a resume point or defaults to l01.
  void _openLesson(BuildContext context) {
    final db = LocalDatabase();
    final savedLessonId = db.getLastViewedLesson(moduleId);

    // Derive a safe default: moduleId 'module_01' → 'module_01_l01'
    final defaultLessonId = '${moduleId}_l01';
    final lessonId = savedLessonId ?? defaultLessonId;

    // Parse lesson number from id: 'module_01_l03' → 3
    int lessonNumber = 1;
    final parts = lessonId.split('_l');
    if (parts.length == 2) {
      lessonNumber = int.tryParse(parts[1]) ?? 1;
    }

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
      opacity: isLocked && !isFirst ? 0.5 : 1.0,
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
                  color: isLocked && !isFirst
                      ? AppColors.surfaceElevated
                      : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLocked && !isFirst
                    ? const Icon(Icons.lock_rounded,
                        color: AppColors.textMuted, size: 18)
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
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tagColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(
                                AppRadius.full),
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
                        Text('$lessons lessons',
                            style: AppTextStyles.bodySmall),
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
