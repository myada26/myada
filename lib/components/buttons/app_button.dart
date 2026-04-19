import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum _ButtonVariant { primary, secondary, text }

/// AppButton — mirrors App.jsx Button component
/// Variants: primary (navy filled), secondary (outlined), text (link)
/// States: default, loading, disabled
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
  }) : _variant = _ButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
  }) : _variant = _ButtonVariant.secondary;

  const AppButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.leadingIcon,
    this.trailingIcon,
    this.size = AppButtonSize.md,
  }) : _variant = _ButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final AppButtonSize size;
  final _ButtonVariant _variant;

  @override
  Widget build(BuildContext context) {
    final bool active = !isDisabled && !isLoading;

    return switch (_variant) {
      _ButtonVariant.primary => _PrimaryButton(button: this, active: active),
      _ButtonVariant.secondary => _SecondaryButton(
        button: this,
        active: active,
      ),
      _ButtonVariant.text => _TextButtonWidget(button: this, active: active),
    };
  }
}

// Size enum
enum AppButtonSize { sm, md, lg }

extension _SizeProps on AppButtonSize {
  double get verticalPadding => switch (this) {
    AppButtonSize.sm => AppSpacing.xs,
    AppButtonSize.md => AppSpacing.md,
    AppButtonSize.lg => AppSpacing.lg,
  };

  double get horizontalPadding => switch (this) {
    AppButtonSize.sm => AppSpacing.md,
    AppButtonSize.md => AppSpacing.xl,
    AppButtonSize.lg => AppSpacing.xl,
  };

  TextStyle get textStyle => switch (this) {
    AppButtonSize.sm => AppTextStyles.buttonSm,
    AppButtonSize.md => AppTextStyles.button,
    AppButtonSize.lg => AppTextStyles.button,
  };

  double get loaderSize => switch (this) {
    AppButtonSize.sm => 14.0,
    AppButtonSize.md => 16.0,
    AppButtonSize.lg => 18.0,
  };
}

// ---------------------------------------------------------------------------
// Internal — Primary
// ---------------------------------------------------------------------------
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.button, required this.active});
  final AppButton button;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: active ? button.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: active
              ? AppColors.primary
              : AppColors.surfaceVariant,
          foregroundColor: active
              ? AppColors.primaryForeground
              : AppColors.mutedForeground,
          padding: EdgeInsets.symmetric(
            horizontal: button.size.horizontalPadding,
            vertical: button.size.verticalPadding,
          ),
        ),
        child: _ButtonContent(
          button: button,
          loaderColor: AppColors.primaryForeground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal — Secondary (outlined)
// ---------------------------------------------------------------------------
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.button, required this.active});
  final AppButton button;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: active ? button.onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: active
              ? AppColors.foreground
              : AppColors.mutedForeground,
          side: BorderSide(
            color: active ? AppColors.borderHeavy : AppColors.border,
            width: 1.5,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: button.size.horizontalPadding,
            vertical: button.size.verticalPadding,
          ),
        ),
        child: _ButtonContent(
          button: button,
          loaderColor: AppColors.foreground,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal — Text / Link
// ---------------------------------------------------------------------------
class _TextButtonWidget extends StatelessWidget {
  const _TextButtonWidget({required this.button, required this.active});
  final AppButton button;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: active ? button.onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: active ? AppColors.primary : AppColors.mutedForeground,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: button.size.verticalPadding,
        ),
      ),
      child: _ButtonContent(button: button, loaderColor: AppColors.primary),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared content row (icon + label + loader)
// ---------------------------------------------------------------------------
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.button, required this.loaderColor});
  final AppButton button;
  final Color loaderColor;

  @override
  Widget build(BuildContext context) {
    if (button.isLoading) {
      return SizedBox(
        height: button.size.loaderSize,
        width: button.size.loaderSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (button.leadingIcon != null) ...[
          button.leadingIcon!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(button.label, style: button.size.textStyle),
        if (button.trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          button.trailingIcon!,
        ],
      ],
    );
  }
}
