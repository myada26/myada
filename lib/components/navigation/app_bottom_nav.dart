import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// AppBottomNav — mirrors App.jsx bottom navigation
/// Animated dot indicator on active tab (equivalent to motion.div layoutId)
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: AppSpacing.md + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.borderHeavy, width: 1.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (i) {
          return _NavTab(
            item: items[i],
            isActive: i == currentIndex,
            onTap: () => onTap(i),
          );
        }),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Active dot indicator (mirrors App.jsx motion.div)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isActive ? 6 : 0,
              height: isActive ? 6 : 0,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
              ),
            ),
            // Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive
                    ? AppColors.primary
                    : AppColors.foreground.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              item.label,
              style: AppTextStyles.caption.copyWith(
                color: isActive
                    ? AppColors.primary
                    : AppColors.foreground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nav item model
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.icon,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Preset nav items matching App.jsx tabs
class AppNavItems {
  static const home = AppNavItem(
    label: 'Home',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
  );
  static const code = AppNavItem(
    label: 'Code',
    icon: Icons.code_outlined,
    activeIcon: Icons.code,
  );
  static const leaderboard = AppNavItem(
    label: 'Ranks',
    icon: Icons.leaderboard_outlined,
    activeIcon: Icons.leaderboard,
  );
  static const profile = AppNavItem(
    label: 'Profile',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
  );

  static const List<AppNavItem> defaults = [home, code, leaderboard, profile];
}
