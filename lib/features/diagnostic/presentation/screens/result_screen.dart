import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../controllers/diagnostic_controller.dart';
import '../../../../models/diagnostic_models.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart'; // For AppRoutes

import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/learning_path_controller.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DiagnosticController>();
    final pathCtrl = context.watch<LearningPathController>();

    if (!pathCtrl.hasResult && !pathCtrl.isBuilding) {
      Future.microtask(() {
        pathCtrl.buildResult(scores: ctrl.scores, skips: ctrl.skips);
      });
    }

    final diagnosticModules = pathCtrl.result?.learningPath.take(3).toList() ?? [];
    final overall = ctrl.getOverallLevel();

    // Overall badge colors
    Color obBg = AppColors.warningLight;
    Color obText = AppColors.warning;
    if (overall == 'Novice') {
      obBg = AppColors.primaryLight;
      obText = AppColors.primary;
    } else if (overall == 'Intermediate') {
      obBg = AppColors.successLight;
      obText = AppColors.success;
    }

    int masteredSkillsCount = 0;
    List<String> masteredSkillNames = [];
    for (int i = 0; i < 5; i++) {
      if (ctrl.getSkillLevel(i) == 'Confident' ||
          ctrl.getSkillLevel(i) == 'Building') {
        masteredSkillsCount++;
        masteredSkillNames.add(diagnosticSkills[i]);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MyADA",
                style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                "Your results",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 24),

              // Overall Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: obBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Starting level: ",
                      style: AppTextStyles.body.copyWith(
                        color: obText,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      overall,
                      style: AppTextStyles.body.copyWith(
                        color: obText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                "Your skill profile",
                style: AppTextStyles.h1.copyWith(fontSize: 24, height: 1.2),
              ),
              const SizedBox(height: 24),

              ...List.generate(5, (index) => _buildSkillRow(index, ctrl)),

              const SizedBox(height: 24),
              Divider(color: AppColors.border, thickness: 0.5),
              const SizedBox(height: 24),

              Text(
                "YOUR PERSONALIZED LEARNING PATH",
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.mutedForeground,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 16),

              if (masteredSkillsCount > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    // Using default text style, can be customized
                    "Your ${masteredSkillNames.take(2).join(' and ')} scores were strong — your path fast-forwards to what you actually need.",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF0F6E56),
                    ),
                  ),
                ),

              ...diagnosticModules.map((mod) => _buildModuleCard(mod, ctrl)),

              const SizedBox(height: 32),
              AppButton(
                label: "Start learning ↗",
                onPressed: () async {
                  final auth = context.read<AuthController>();
                  final level = context
                      .read<DiagnosticController>()
                      .getOverallLevel();
                  await auth.markDiagnosticComplete(level);
                  // AuthGate handles navigation automatically — no pushNamed needed
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillRow(int skillIndex, DiagnosticController ctrl) {
    final skillName = diagnosticSkills[skillIndex];
    final score = ctrl.scores[skillIndex] ?? 0;
    // max score per skill is typically 3 in the diagnostic logic
    final pct = (score / 3.0).clamp(0.0, 1.0);
    final level = ctrl.getSkillLevel(skillIndex);

    Color fill = const Color(0xFFEF9F27); // Developing
    Color badgeBg = AppColors.warningLight;
    Color badgeText = AppColors.warning;

    if (level == 'Building') {
      fill = AppColors.primary;
      badgeBg = AppColors.primaryLight;
      badgeText = AppColors.primary;
    } else if (level == 'Confident') {
      fill = AppColors.success;
      badgeBg = AppColors.successLight;
      badgeText = AppColors.success;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              skillName,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              height: 6, // Fixed height for the progress bar
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  // Inner colored part of the progress bar
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              level,
              style: AppTextStyles.badge.copyWith(color: badgeText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(LearningModule mod, DiagnosticController ctrl) {
    final level = ctrl.getSkillLevel(mod.skill.index);
    final isMastered = level == 'Confident';

    Color tagBg = const Color(0xFFE6F1FB);
    Color tagText = const Color(0xFF185FA5);
    if (mod.tagLabel == 'Sequencing') {
      tagBg = const Color(0xFFEAF3DE);
      tagText = const Color(0xFF3B6D11);
    } else if (mod.tagLabel == 'Logic Flow') {
      tagBg = const Color(0xFFEEEDFE);
      tagText = const Color(0xFF3C3489);
    } else if (mod.tagLabel == 'Computational Thinking') {
      tagBg = const Color(0xFFE1F5EE);
      tagText = const Color(0xFF0F6E56);
    } else if (mod.tagLabel == 'Debugging') {
      tagBg = const Color(0xFFFAECE7);
      tagText = const Color(0xFF993C1D);
    }

    return Opacity(
      opacity: isMastered ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMastered)
              Container(
                width: 3,
                height: 40,
                color: AppColors.primary,
                margin: const EdgeInsets.only(right: 12),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Module ${mod.number}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          mod.tagLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: tagText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isMastered) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "Next up",
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF0F6E56),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mod.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${mod.description} · ${isMastered ? 'Review (mastered)' : 'Required — start here'}",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.foreground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
