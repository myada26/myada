import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ---------------------------------------------------------------------------
// 1. Highlight Card — App.jsx "Your Progress" hero card
// ---------------------------------------------------------------------------
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    this.onAction,
    this.decorationWidget,
    this.backgroundColor = AppColors.surface,
    this.titleColor = AppColors.primary,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onAction;
  final Widget? decorationWidget;
  final Color backgroundColor;
  final Color titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.h2.copyWith(color: titleColor)),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: MediaQuery.sizeOf(context).width * 0.5,
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodyMuted.copyWith(
                    color: (subtitleColor ?? titleColor).withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SmallPrimaryButton(label: actionLabel, onPressed: onAction),
            ],
          ),
          // Decorative widget — top-right
          if (decorationWidget != null)
            Positioned(
              right: -8,
              bottom: -8,
              child: SizedBox(
                width: 100,
                height: 100,
                child: decorationWidget!,
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallPrimaryButton extends StatelessWidget {
  const _SmallPrimaryButton({required this.label, this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonSm.copyWith(
            color: AppColors.primaryForeground,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Basic Card — App.jsx grid "Explore" cards
// ---------------------------------------------------------------------------
class BasicCard extends StatelessWidget {
  const BasicCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. List Card — App.jsx "Recent Activity" rows
// ---------------------------------------------------------------------------
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDisabled = false,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.7 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.label),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Quiz Card — for lesson/quiz list
// ---------------------------------------------------------------------------
class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.title,
    required this.description,
    required this.questionCount,
    this.durationMinutes,
    this.badgeLabel,
    this.badgeColor,
    this.onTap,
    this.isCompleted = false,
    this.score,
  });

  final String title;
  final String description;
  final int questionCount;
  final int? durationMinutes;
  final String? badgeLabel;
  final Color? badgeColor;
  final VoidCallback? onTap;
  final bool isCompleted;
  final int? score; // 0–100

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.4)
                : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: title + badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: AppTextStyles.h4)),
                if (badgeLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _Badge(
                    label: badgeLabel!,
                    color: badgeColor ?? AppColors.accent,
                  ),
                ],
                if (isCompleted) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 18,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: AppTextStyles.bodyMuted),
            const SizedBox(height: AppSpacing.md),
            // Meta row
            Row(
              children: [
                _MetaChip(
                  icon: Icons.help_outline,
                  label: '$questionCount questions',
                ),
                if (durationMinutes != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _MetaChip(
                    icon: Icons.timer_outlined,
                    label: '$durationMinutes min',
                  ),
                ],
                if (score != null) ...[
                  const Spacer(),
                  Text(
                    '$score%',
                    style: AppTextStyles.label.copyWith(
                      color: score! >= 80
                          ? AppColors.success
                          : score! >= 60
                          ? AppColors.warning
                          : AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3), width: 1.0),
      ),
      child: Text(label, style: AppTextStyles.badge.copyWith(color: color)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.mutedForeground),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Horizontal Scroll Card Row — wraps any card list
// ---------------------------------------------------------------------------
class HorizontalCardRow extends StatelessWidget {
  const HorizontalCardRow({
    super.key,
    required this.children,
    this.cardWidth = 200.0,
    this.height = 160.0,
  });

  final List<Widget> children;
  final double cardWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: children.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => SizedBox(width: cardWidth, child: children[i]),
      ),
    );
  }
}
