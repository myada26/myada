import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// StreakBar — 7-dot weekly streak tracker (referenced in Home Dashboard doc)
class StreakBar extends StatelessWidget {
  const StreakBar({
    super.key,
    required this.streakCount,
    required this.completedDays, // list of weekday indices 0=Mon … 6=Sun
    this.todayIndex = -1,
  });

  final int streakCount;
  final List<int> completedDays;
  final int todayIndex;

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Flame + count
        const Icon(
          Icons.local_fire_department,
          color: AppColors.accent,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$streakCount day streak',
          style: AppTextStyles.label.copyWith(color: AppColors.accent),
        ),
        const Spacer(),
        // 7 dots
        Row(
          children: List.generate(7, (i) {
            final done = completedDays.contains(i);
            final isToday = i == todayIndex;
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? AppColors.success
                          : isToday
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                      border: isToday && !done
                          ? Border.all(color: AppColors.accent, width: 1.5)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _days[i],
                    style: AppTextStyles.bodySm.copyWith(fontSize: 9),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Linear progress bar with label
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value, // 0.0 – 1.0
    this.label,
    this.color = AppColors.primary,
    this.height = 6.0,
  });

  final double value;
  final String? label;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label!, style: AppTextStyles.bodySm),
              Text(
                '${(value * 100).round()}%',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: AppColors.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

/// Section header row ("Your Progress" + optional action link)
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: AppTextStyles.h3),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
