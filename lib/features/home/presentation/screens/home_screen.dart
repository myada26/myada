import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final pathCtrl = context.watch<LearningPathController>();

    final firstName = user?.firstName ?? 'Student';
    final level = user?.startingLevel ?? 'Beginner';

    // The start-here module is the first required module from the diagnostic.
    final startModule = pathCtrl.result?.startHereModule;
    final skillResults = pathCtrl.result?.skillResults ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: AppTextStyles.bodyLg.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                              ),
                              Text(
                                firstName,
                                style: AppTextStyles.h1,
                              ),
                            ],
                          ),
                        ),
                        _LevelBadge(level: level),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ── Continue card (if diagnostic done) ───────────────────────────
            if (startModule != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _ContinueCard(module: startModule),
                ),
              ),

            // ── Skill map (if diagnostic done) ───────────────────────────────
            if (skillResults.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: _SkillMap(skillResults: skillResults),
                ),
              ),

            // ── Placeholder when diagnostic not done ─────────────────────────
            if (startModule == null && skillResults.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.explore_outlined,
                          size: 64,
                          color: AppColors.mutedForeground,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your journey starts here',
                          style: AppTextStyles.h2,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your diagnostic to unlock a personalised learning path.',
                          style: AppTextStyles.bodyLg.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Level badge ────────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  final String level;
  const _LevelBadge({required this.level});

  Color get _bg {
    switch (level) {
      case 'Intermediate':
        return AppColors.successLight;
      case 'Novice':
        return AppColors.primaryLight;
      default:
        return AppColors.warningLight;
    }
  }

  Color get _fg {
    switch (level) {
      case 'Intermediate':
        return AppColors.success;
      case 'Novice':
        return AppColors.primary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Text(
        level,
        style: AppTextStyles.labelSmall.copyWith(
          color: _fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Continue card ──────────────────────────────────────────────────────────────

class _ContinueCard extends StatelessWidget {
  final LearningModule module;
  const _ContinueCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final moduleId =
        'module_${module.number.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.lesson,
          arguments: {
            'lessonId': '${moduleId}_l01',
            'moduleId': moduleId,
            'lessonNumber': 1,
            'totalLessonsInModule': module.estimatedLessons,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius:
              BorderRadius.circular(AppConstants.radiusLG),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE WHERE YOU LEFT OFF',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withAlpha(180),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Module ${module.number}',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    module.name,
                    style: AppTextStyles.bodySm.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skill map ──────────────────────────────────────────────────────────────────

class _SkillMap extends StatelessWidget {
  final List<SkillResult> skillResults;
  const _SkillMap({required this.skillResults});

  static const _skillNames = [
    'Sequencing',
    'Logic Flow',
    'Debugging',
    'Syntax',
    'Comp. Thinking',
  ];

  Color _barColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:
        return AppColors.success;
      case SkillLevel.building:
        return AppColors.primary;
      case SkillLevel.developing:
        return AppColors.warning;
    }
  }

  String _levelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:
        return 'Confident';
      case SkillLevel.building:
        return 'Building';
      case SkillLevel.developing:
        return 'Developing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppColors.navBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Skill Map', style: AppTextStyles.headingSmall),
          const SizedBox(height: 16),
          ...skillResults.asMap().entries.map((entry) {
            final i = entry.key;
            final skill = entry.value;
            final name = i < _skillNames.length ? _skillNames[i] : 'Skill $i';
            final pct = skill.barFraction;
            final color = _barColor(skill.level);
            final label = _levelLabel(skill.level);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: AppTextStyles.bodySm),
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
