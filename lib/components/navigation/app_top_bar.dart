import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// AppTopBar — mirrors App.jsx sticky header
/// Variants: default (greeting + avatar), simple (title + back), transparent
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  // Greeting variant — App.jsx "Good morning, Maker"
  const AppTopBar.greeting({
    super.key,
    required this.greeting,
    required this.name,
    this.avatarUrl,
    this.avatarFallback,
    this.onAvatarTap,
    this.onSettingsTap,
    this.actions,
  }) : _variant = _AppBarVariant.greeting,
       title = null,
       showBackButton = false;

  // Simple title variant
  const AppTopBar.title({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.onSettingsTap,
  }) : _variant = _AppBarVariant.simple,
       greeting = null,
       name = null,
       avatarUrl = null,
       avatarFallback = null,
       onAvatarTap = null;

  final _AppBarVariant _variant;
  final String? greeting;
  final String? name;
  final String? title;
  final String? avatarUrl;
  final String? avatarFallback;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSettingsTap;
  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Size get preferredSize => const Size.fromHeight(72.0);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        color: AppColors.background.withOpacity(0.92),
        padding: EdgeInsets.only(
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          top: MediaQuery.of(context).padding.top + AppSpacing.sm,
          bottom: AppSpacing.md,
        ),
        child: switch (_variant) {
          _AppBarVariant.greeting => _GreetingBar(bar: this),
          _AppBarVariant.simple => _SimpleBar(bar: this, context: context),
        },
      ),
    );
  }
}

enum _AppBarVariant { greeting, simple }

// ---------------------------------------------------------------------------
// Greeting bar
// ---------------------------------------------------------------------------
class _GreetingBar extends StatelessWidget {
  const _GreetingBar({required this.bar});
  final AppTopBar bar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: bar.onAvatarTap,
          child: _Avatar(
            url: bar.avatarUrl,
            fallback:
                bar.avatarFallback ??
                (bar.name?.isNotEmpty == true
                    ? bar.name![0].toUpperCase()
                    : 'U'),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Greeting text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bar.greeting ?? 'Good morning,',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.foreground.withOpacity(0.6),
                ),
              ),
              Text(bar.name ?? '', style: AppTextStyles.h2),
            ],
          ),
        ),
        // Actions
        if (bar.actions != null) ...bar.actions!,
        // Settings button — App.jsx circular button
        if (bar.onSettingsTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _CircleIconButton(
            icon: Icons.settings_outlined,
            onTap: bar.onSettingsTap!,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Simple bar
// ---------------------------------------------------------------------------
class _SimpleBar extends StatelessWidget {
  const _SimpleBar({required this.bar, required this.context});
  final AppTopBar bar;
  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        if (bar.showBackButton)
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(ctx).maybePop(),
          ),
        if (bar.showBackButton) const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(bar.title ?? '', style: AppTextStyles.h2)),
        if (bar.actions != null) ...bar.actions!,
        if (bar.onSettingsTap != null)
          _CircleIconButton(
            icon: Icons.settings_outlined,
            onTap: bar.onSettingsTap!,
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar widget — circle with border (App.jsx style)
// ---------------------------------------------------------------------------
class _Avatar extends StatelessWidget {
  const _Avatar({this.url, required this.fallback});
  final String? url;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderHeavy, width: 1.5),
        color: AppColors.primaryLight,
      ),
      child: ClipOval(
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Fallback(text: fallback),
              )
            : _Fallback(text: fallback),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Circular icon button — App.jsx settings button
// ---------------------------------------------------------------------------
class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: AppColors.foreground),
      ),
    );
  }
}

/// Reusable circle icon button (public)
class AppCircleButton extends StatelessWidget {
  const AppCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1.5),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: iconSize, color: color ?? AppColors.foreground),
      ),
    );
  }
}
