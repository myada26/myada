import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../controllers/diagnostic_controller.dart';
import 'package:provider/provider.dart';
import '../../../../main.dart'; // For AppRoutes

class BriefScreen extends StatelessWidget {
  const BriefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                "Diagnostic assessment",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "Here's what to expect",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  _InfoChip(label: "10 questions"),
                  const SizedBox(width: 12),
                  _InfoChip(label: "5 skill areas"),
                  const SizedBox(width: 12),
                  _InfoChip(label: "~8–10 min"),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text.rich(
                  TextSpan(
                    text:
                        "Each question has a ", // Using default text style, can be customized
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.foreground,
                      height: 1.5,
                    ),
                    children: const [
                      TextSpan(
                        text: "90-second",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text:
                            " time limit. You can skip any question — skips are tracked separately from wrong answers, so there's no penalty for being honest.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  "We won't show you right or wrong during the assessment — that way your answers reflect what you actually know, not what you just saw.",
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.foreground,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),
              AppButton(
                label: "Start assessment",
                onPressed: () {
                  context.read<DiagnosticController>().startDiagnostic();
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.diagQuestion,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySm.copyWith(
          fontWeight: FontWeight.w500, // Custom weight
          color: AppColors.foreground.withOpacity(0.8),
        ),
      ),
    );
  }
}
