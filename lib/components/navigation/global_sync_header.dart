import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class GlobalSyncHeader extends StatelessWidget {
  const GlobalSyncHeader({super.key});

  static String _initials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    final combined = '$f$l';
    return combined.isEmpty ? '?' : combined;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final firstName = user?.firstName ?? '';
    final lastName = user?.lastName ?? '';
    final initials = _initials(firstName, lastName);
    
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');
    final displayName = fullName.isNotEmpty ? fullName : 'Student';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.challengeTealLight,
          child: Text(
            initials,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.challengeTeal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTextStyles.labelSm.copyWith(
                  fontSize: 15,
                  color: AppColors.foreground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'BSIT 3A · MyADA',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(
              Icons.sync_rounded,
              size: 16,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}
