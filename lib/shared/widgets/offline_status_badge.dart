// lib/shared/widgets/offline_status_badge.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class OfflineStatusBadge extends StatelessWidget {
  final bool isOffline;

  const OfflineStatusBadge({super.key, this.isOffline = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        // Using AppSpacing for padding
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: isOffline
            ? AppColors.warning.withOpacity(0.15)
            : AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: isOffline
              ? AppColors.warning.withOpacity(0.4)
              : AppColors.accent.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOffline ? AppColors.warning : AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            isOffline ? 'Offline mode' : 'Offline-ready',
            style: AppTextStyles.labelSm.copyWith(
              color: isOffline ? AppColors.warning : AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
