// lib/features/diagnostic/presentation/screens/diagnostic_results_review_screen.dart
//
// HCI bias-correction screen shown BETWEEN the diagnostic result screen
// and the home screen. Lets the user confirm or veto the skill-skipping
// logic before their learning path is locked in.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/diagnostic_controller.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/diagnostic_models.dart';

class DiagnosticResultsReviewScreen extends StatefulWidget {
  const DiagnosticResultsReviewScreen({super.key});

  @override
  State<DiagnosticResultsReviewScreen> createState() =>
      _DiagnosticResultsReviewScreenState();
}

class _DiagnosticResultsReviewScreenState
    extends State<DiagnosticResultsReviewScreen> {
  bool _isLoading = false;

  List<String> _masteredSkillNames(DiagnosticController ctrl) {
    final List<String> names = [];
    for (int i = 0; i < 5; i++) {
      final lvl = ctrl.getSkillLevel(i);
      if (lvl == 'Confident' || lvl == 'Building') {
        names.add(diagnosticSkills[i]);
      }
    }
    return names;
  }

  Color _levelColor(String level) => switch (level) {
    'Confident' => AppColors.success,
    'Building' => AppColors.primary,
    _ => AppColors.warning,
  };

  Future<void> _onConfirm() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final diagCtrl = context.read<DiagnosticController>();
    final level = diagCtrl.getOverallLevel();

    try {
      await auth.markDiagnosticComplete(level);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not finish setup. Please try again.'),
        ),
      );
    }
  }

  Future<void> _onVeto() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final pathCtrl = context.read<LearningPathController>();

    try {
      await pathCtrl.resetToBeginnerPath();
      await auth.markDiagnosticComplete('Beginner');
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update your path. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diagCtrl = context.watch<DiagnosticController>();
    final pathCtrl = context.watch<LearningPathController>();
    final level = diagCtrl.getOverallLevel();
    final mastered = _masteredSkillNames(diagCtrl);
    final skippedMods =
        pathCtrl.result?.learningPath
            .where((m) => m.status == ModuleStatus.mastered)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.checklist_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(
                  'Your results are in!',
                  style: AppTextStyles.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(
                  'We\'ve analyzed your diagnostic and built a personalized path, but we want to make sure it feels right.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _LevelBadge(level: level),
              const SizedBox(height: AppSpacing.xl),
              Text('Skill Assessment', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(5, (i) {
                final skillLevel = diagCtrl.getSkillLevel(i);
                return _SkillConfRow(
                  skill: diagnosticSkills[i],
                  level: skillLevel,
                  color: _levelColor(skillLevel),
                );
              }),
              const SizedBox(height: AppSpacing.xl),
              if (mastered.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Fast-tracked modules',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'You seem confident in ${mastered.join(', ')}. We\'ve marked ${skippedMods.length} module(s) as already mastered, so you skip straight to new content.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                      if (skippedMods.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        ...skippedMods.map(
                          (m) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '• Module ${m.number}: ${m.name}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.mutedForeground,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                    child: Text(
                      'Yes, let\'s get started!',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.primaryForeground,
                      ),
                    ),
                  ),
                ),
                if (mastered.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _onVeto,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      child: Text(
                        'No, I\'d like to review these modules',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final isIntermediate = level == 'Intermediate';
    final Color bg = isIntermediate
        ? AppColors.successLight
        : AppColors.primaryLight.withAlpha(40);
    final Color text = isIntermediate ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.military_tech_rounded, color: text, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Starting Level: $level',
            style: AppTextStyles.label.copyWith(color: text),
          ),
        ],
      ),
    );
  }
}

class _SkillConfRow extends StatelessWidget {
  final String skill;
  final String level;
  final Color color;

  const _SkillConfRow({
    required this.skill,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              skill,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              level,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
