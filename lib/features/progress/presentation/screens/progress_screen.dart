// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const _skills = [
    ('Sequencing', AppColors.accent),
    ('Logic Flow', AppColors.primary),
    ('Syntax', Color(0xFF4FC3F7)),
    ('Debugging', AppColors.error),
    ('Comp. Thinking', AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingMD,
                  AppConstants.spacingMD,
                  AppConstants.spacingMD,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Your skill development over time',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingLG)),

            // Overall stats
            SliverToBoxAdapter(child: _OverallStatsRow()),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingMD)),

            // Skill mastery
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMD),
                child: Text('Skill Mastery',
                    style: AppTextStyles.headingMedium),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingSM)),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMD),
              sliver: SliverList.separated(
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppConstants.spacingSM),
                itemCount: _skills.length,
                itemBuilder: (context, i) {
                  return _SkillMasteryRow(
                    skill: _skills[i].$1,
                    color: _skills[i].$2,
                    percent: 0.0,
                    level: 'Not assessed',
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingMD)),

            // Module completion
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMD),
                child:
                    Text('Modules', style: AppTextStyles.headingMedium),
              ),
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingSM)),
            SliverToBoxAdapter(child: _ModuleProgressList()),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingMD)),

            // Quiz history placeholder
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacingMD),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quiz History',
                        style: AppTextStyles.headingMedium),
                    const SizedBox(height: AppConstants.spacingSM),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                            AppConstants.radiusLG),
                        border: Border.all(color: AppColors.navBorder),
                      ),
                      child: Center(
                        child: Text(
                          'No quizzes taken yet',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
                child: SizedBox(height: AppConstants.spacingXXL)),
          ],
        ),
      ),
    );
  }
}

class _OverallStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const stats = [
      (label: 'Modules', value: '0/12'),
      (label: 'Lessons', value: '0/86'),
      (label: 'Quizzes', value: '0'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD),
      child: Row(
        children: stats.map((s) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: AppConstants.spacingSM),
              padding: const EdgeInsets.all(AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLG),
                border: Border.all(color: AppColors.navBorder),
              ),
              child: Column(
                children: [
                  Text(s.value,
                      style: AppTextStyles.headingLarge
                          .copyWith(color: AppColors.primary)),
                  const SizedBox(height: 2),
                  Text(s.label, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SkillMasteryRow extends StatelessWidget {
  final String skill;
  final Color color;
  final double percent;
  final String level;

  const _SkillMasteryRow({
    required this.skill,
    required this.color,
    required this.percent,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMD),
        border: Border.all(color: AppColors.navBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(skill, style: AppTextStyles.headingSmall),
                    const Spacer(),
                    Text(level, style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleProgressList extends StatelessWidget {
  static const _modules = [
    'The Genesis of Execution',
    'The Data Blueprint',
    'Branching Realities',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD),
      child: Column(
        children: _modules.map((m) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusMD),
              border: Border.all(color: AppColors.navBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: AppColors.textMuted, size: 16),
                const SizedBox(width: AppConstants.spacingMD),
                Expanded(
                  child: Text(m, style: AppTextStyles.headingSmall),
                ),
                Text('0%',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
