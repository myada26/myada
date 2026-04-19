import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../controllers/diagnostic_controller.dart';
import 'package:provider/provider.dart';

class PreassessScreen extends StatefulWidget {
  const PreassessScreen({super.key});

  @override
  State<PreassessScreen> createState() => _PreassessScreenState();
}

class _PreassessScreenState extends State<PreassessScreen> {
  int _selectedIndex = -1;

  void _handleContinue(BuildContext context) {
    if (_selectedIndex == 0) {
      // Complete beginner
      context.read<DiagnosticController>().startCompleteBeginnerRoute();
      Navigator.pushReplacementNamed(context, '/diagnostic/result');
    } else {
      Navigator.pushReplacementNamed(context, '/diagnostic/brief');
    }
  }

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
                "Before we begin",
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                "How would you describe yourself?",
                style: AppTextStyles.h1,
              ),
              const SizedBox(height: 8),
              const Text(
                "We'll use this to set the right starting point for you.",
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 32),

              _buildOption(
                context,
                0,
                "A",
                "I've never written a line of code",
              ),
              _buildOption(context, 1, "B", "I've tried a little on my own"),
              _buildOption(
                context,
                2,
                "C",
                "I've taken a class or course before",
              ),

              const Spacer(),
              AppButton(
                label: "Continue",
                onPressed: _selectedIndex != -1
                    ? () => _handleContinue(context)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context,
    int index,
    String keyLabel,
    String text,
  ) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.background,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.muted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                keyLabel,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryForeground
                      : AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
