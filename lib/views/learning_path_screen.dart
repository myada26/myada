// ─────────────────────────────────────────────────────────────────────────────
// learning_path_screen.dart
//
// Pure UI for the learning path result screen.
// Contains NO logic — reads from LearningPathController via Provider and
// renders the result. All business decisions live in the controller.
//
// Widget tree overview:
//   LearningPathScreen (uses AppTopBar, AppButton)
//     └─ _LoadingView (uses AppColors, AppTextStyles)
//     └─ _ResultView (uses AppColors, AppTextStyles, AppSpacing, AppButton)
//           ├─ _OverallProfileCard (uses AppColors, AppTextStyles)
//           ├─ _SkillProfileSection (uses AppColors, AppTextStyles)
//           ├─ _FastForwardNotice (uses AppColors, AppTextStyles, AppSpacing)
//           ├─ _ModuleSection (uses AppColors, AppTextStyles, AppSpacing)
//           └─ _BeginButton (uses AppButton)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../components/buttons/app_button.dart';
import '../../components/navigation/app_top_bar.dart'; // For AppTopBar
import '../../main.dart'; // For AppRoutes
import '../../models/diagnostic_models.dart'; // For DiagnosticResult, LearningModule, SkillCategory, SkillLevel
import '../../controllers/learning_path_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen — entry point from navigator
// ─────────────────────────────────────────────────────────────────────────────
class LearningPathScreen extends StatelessWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar.title(title: 'Learning Path'),
      body: Consumer<LearningPathController>(
        builder: (context, controller, _) {
          // Show spinner while controller is computing the result
          if (controller.isBuilding || !controller.hasResult) {
            return const _LoadingView();
          }
          return _ResultView(result: controller.result!);
        },
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Loading state
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(color: AppColors.success),
          const SizedBox(height: 20),
          Text(
            'Building your learning path…',
            style: AppTextStyles.body.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main result view — assembles all sections
// ─────────────────────────────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final DiagnosticResult result;
  const _ResultView({required this.result});

  @override
  Widget build(BuildContext context) {
    final hasRecommended = result.recommendedModules.isNotEmpty;
    final hasMastered = result.masteredModules.isNotEmpty;
    final hasFastForward = hasMastered || hasRecommended;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      children: [
        // Overall profile card (green card at top)
        _OverallProfileCard(result: result),
        const SizedBox(height: 20),

        // Per-skill bar chart
        _SkillProfileSection(skillResults: result.skillResults),
        const SizedBox(height: 4),

        // Fast-forward notice (only if any skills were Building or Confident)
        if (hasFastForward) ...[
          _FastForwardNotice(result: result),
          const SizedBox(height: 16),
        ],

        const _Divider(),
        const SizedBox(height: 16),

        // Section intro
        const _SectionLabel(text: 'Your personalized learning path'),
        const SizedBox(height: 4),
        Text(
          'Required modules are where you start. Review modules can be skimmed or revisited.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground, height: 1.6),
        ),
        const SizedBox(height: 16),

        // Required modules (must-do)
        if (result.requiredModules.isNotEmpty)
          _ModuleSection(
            badgeLabel:
                'Required — ${result.requiredModules.length} module${result.requiredModules.length != 1 ? "s" : ""}',
            badgeColor: AppColors.success,
            modules: result.requiredModules,
          ),

        // Recommended modules (building-level skills)
        if (hasRecommended) ...[
          const SizedBox(height: 16),
          _ModuleSection(
            badgeLabel:
                'Recommended review — ${result.recommendedModules.length} module${result.recommendedModules.length != 1 ? "s" : ""}',
            badgeColor: AppColors.primary, // Using primary for building/recommended
            modules: result.recommendedModules,
          ),
        ],

        // Mastered modules (confident-level skills)
        if (hasMastered) ...[
          const SizedBox(height: 16),
          _ModuleSection(
            badgeLabel:
                'Mastered — ${result.masteredModules.length} module${result.masteredModules.length != 1 ? "s" : ""}',
            badgeColor: AppColors.subtleForeground, // Using subtleForeground for mastered
            modules: result.masteredModules,
            dimmed: true,
          ),
        ],

        const SizedBox(height: 28),

        // CTA button
        _BeginButton(startModule: result.startHereModule),
        const SizedBox(height: 12),

        // Retake link
        Center(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.settings.name == AppRoutes.diagnostic);
            },
            child: Text(
              'Retake diagnostic',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overall profile card
// ─────────────────────────────────────────────────────────────────────────────
class _OverallProfileCard extends StatelessWidget {
  final DiagnosticResult result;
  const _OverallProfileCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -16,
            right: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.successLight.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR STARTING LEVEL',
                style: AppTextStyles.caption.copyWith(color: AppColors.primaryForeground.withOpacity(0.7)),
              ),
              const SizedBox(height: 4),
              Text(
                LearningPathController.profileLabel(result.profile),
                style: AppTextStyles.h1.copyWith(
                  fontSize: 28, // Custom size for this specific text
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                LearningPathController.profileSubtitle(result.profile),
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primaryForeground.withOpacity(0.7), height: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-skill bar section
// ─────────────────────────────────────────────────────────────────────────────
class _SkillProfileSection extends StatelessWidget {
  final List<SkillResult> skillResults;
  const _SkillProfileSection({required this.skillResults});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel(text: 'Your skill profile'),
        const SizedBox(height: 10),
        ...skillResults.map((r) => _SkillRow(result: r)),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  final SkillResult result;
  const _SkillRow({required this.result});

  String get _skillName {
    switch (result.skill) {
      case SkillCategory.sequencing:
        return 'Sequencing';
      case SkillCategory.logicFlow:
        return 'Logic Flow';
      case SkillCategory.debugging:
        return 'Debugging';
      case SkillCategory.syntax:
        return 'Syntax';
      case SkillCategory.computationalThinking:
        return 'Computational Thinking';
    }
  }

  Color get _barColor {
    switch (result.level) {
      case SkillLevel.developing:
        return AppColors.warning;
      case SkillLevel.building:
        return AppColors.primary;
      case SkillLevel.confident:
        return AppColors.success;
    }
  }

  Color get _badgeBg {
    switch (result.level) {
      case SkillLevel.developing:
        return AppColors.warningLight;
      case SkillLevel.building:
        return AppColors.primaryLight;
      case SkillLevel.confident:
        return AppColors.successLight;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final label = LearningPathController.skillLevelLabel(result.level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Skill name
          SizedBox(
            width: 140,
            child: Text( // Using default text style, can be customized with AppTextStyles
              _skillName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          // Bar
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: result.barFraction,
                minHeight: 6,
                backgroundColor: AppColors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: _badgeBg.withOpacity(0.5), // Adjust opacity for badge background
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              label,
              style: AppTextStyles.badge.copyWith(
                fontSize: 11, // Custom size for badge
                fontWeight: FontWeight.w600, // Custom weight for badge
                color: _barColor,
              ),
            ),
          ),
          // Skipped indicator
          if (result.wasSkipped) ...[
            const SizedBox(width: 6),
            const Tooltip(
              message: 'Question was skipped',
              child: Icon(
                Icons.info_outline, // Using default icon, can be customized
                size: 14,
                color: AppColors.subtleForeground,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fast-forward notice
// ─────────────────────────────────────────────────────────────────────────────
class _FastForwardNotice extends StatelessWidget {
  final DiagnosticResult result;
  const _FastForwardNotice({required this.result});

  @override
  Widget build(BuildContext context) {
    // Collect skill names that are Building or Confident
    final advancedSkills = result.skillResults
        .where((r) => r.level != SkillLevel.developing)
        .map(
          (r) => LearningPathController.skillLevelLabel(r.level) == 'Confident'
              ? _skillName(r.skill)
              : null,
        )
        .whereType<String>()
        .toList();

    final skillText = advancedSkills.isEmpty
        ? 'Some modules are'
        : '${advancedSkills.take(2).join(' and ')} scores were strong — related modules are';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text( // Using default text style, can be customized
              '$skillText marked as review-only. Your path fast-forwards to where you actually need to start.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.success,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _skillName(SkillCategory cat) {
    switch (cat) {
      case SkillCategory.sequencing:
        return 'Sequencing';
      case SkillCategory.logicFlow:
        return 'Logic Flow';
      case SkillCategory.debugging:
        return 'Debugging';
      case SkillCategory.syntax:
        return 'Syntax';
      case SkillCategory.computationalThinking:
        return 'Computational Thinking';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Module section (required / recommended / mastered)
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleSection extends StatelessWidget {
  final String badgeLabel;
  final Color badgeColor;
  final List<LearningModule> modules;
  final bool dimmed;

  const _ModuleSection({
    required this.badgeLabel,
    required this.badgeColor,
    required this.modules,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor, // Badge color is passed in
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            badgeLabel,
            style: AppTextStyles.badge.copyWith(
              fontSize: 11, // Custom size for badge
              fontWeight: FontWeight.w600, // Custom weight for badge
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Module cards
        ...modules.map((m) => _ModuleCard(module: m, dimmed: dimmed)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual module card
// ─────────────────────────────────────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final LearningModule module;
  final bool dimmed;
  const _ModuleCard({required this.module, this.dimmed = false});

  /// Left border colour by status
  Color get _borderAccent {
    switch (module.status) {
      case ModuleStatus.required:
        return AppColors.success;
      case ModuleStatus.recommended:
        return AppColors.primary;
      case ModuleStatus.mastered:
        return Colors.transparent;
      case ModuleStatus.inProgress:
        return AppColors.warning;
      case ModuleStatus.locked:
        return AppColors.border;
      case ModuleStatus.completed:
        return AppColors.success;
    }
  }

  /// Tag colours by skill category
  ({Color bg, Color text}) _tagColors(SkillCategory skill) {
    switch (module.skill) {
      case SkillCategory.sequencing:
        return (bg: AppColors.successLight, text: AppColors.success); // Using success for sequencing
      case SkillCategory.logicFlow:
        return (bg: AppColors.primaryLight, text: AppColors.primary); // Using primary for logic flow
      case SkillCategory.debugging:
        return (bg: AppColors.errorLight, text: AppColors.error); // Using error for debugging
      case SkillCategory.syntax:
        return (bg: AppColors.primaryLight, text: AppColors.primary); // Using primary for syntax
      case SkillCategory.computationalThinking:
        return (bg: AppColors.accentLight, text: AppColors.accent); // Using accent for computational thinking
    }
  }

  String get _statusIcon {
    switch (module.status) {
      case ModuleStatus.required:
        return '›';
      case ModuleStatus.recommended:
        return '~';
      case ModuleStatus.mastered:
        return '✓';
      case ModuleStatus.inProgress:
        return '…';
      case ModuleStatus.locked:
        return '🔒';
      case ModuleStatus.completed:
        return '✓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = _tagColors(module.skill);

    return Opacity(
      opacity: dimmed ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final moduleId = 'module_${module.number.toString().padLeft(2, '0')}';
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
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: module.isStartHere ? AppColors.successLight : AppColors.surface,
              border: Border(
                left: BorderSide(color: _borderAccent, width: 3),
                top: BorderSide(color: AppColors.border, width: 0.5),
                right: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Module number
                  SizedBox(
                    width: 28,
                    child: Text(
                      'M${module.number}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.subtleForeground,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  // Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + "Start here" badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _capitalize(module.name),
                                style: AppTextStyles.label.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (module.isStartHere)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '↳ Start here',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.success),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module.description,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.subtleForeground,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: tag.bg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                module.tagLabel,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: tag.text,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${module.estimatedLessons} lessons',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.subtleForeground,
                              ),
                            ),
                            if (module.status == ModuleStatus.mastered) ...[
                              const SizedBox(width: 6),
                              const Text(
                                '✓ Mastered',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3B6D11),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status icon
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 1),
                    child: Text(
                      _statusIcon,
                      style: TextStyle(
                        fontSize: 16,
                        color: module.status == ModuleStatus.required
                            ? AppColors.success
                            : AppColors.subtleForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Begin button
// ─────────────────────────────────────────────────────────────────────────────
class _BeginButton extends StatelessWidget {
  final LearningModule? startModule;
  const _BeginButton({this.startModule});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Begin your first lesson →',
      onPressed: () {
        if (startModule == null) return;
        final moduleId = 'module_${startModule!.number.toString().padLeft(2, '0')}';
        Navigator.of(context).pushNamed(
          AppRoutes.lesson,
          arguments: {
            'lessonId': '${moduleId}_l01',
            'moduleId': moduleId,
            'lessonNumber': 1,
            'totalLessonsInModule': startModule!.estimatedLessons,
          },
        );
      },
      size: AppButtonSize.md, // Using medium size for consistency
      leadingIcon: const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.primaryForeground),
      // You can add a trailing icon if needed, e.g., Icons.arrow_forward
      // trailingIcon: const Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.primaryForeground),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.subtleForeground, letterSpacing: 0.8,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.border, height: 1, thickness: 0.5);
  }
}
