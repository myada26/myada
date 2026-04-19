// lib/shared/widgets/main_nav_shell.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/learn/presentation/screens/learn_screen.dart';
import '../../features/ranks/presentation/screens/ranks_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  // 0=Home, 1=Ranks, 2=Learn(FAB), 3=Progress, 4=Profile
  int _currentIndex = 0;

  // Pages — FAB (index 2) opens the Learn screen
  static const _pages = [
    HomeScreen(),
    RanksScreen(),
    LearnScreen(), // FAB
    ProgressScreen(),
    ProfileScreen(),
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  void _onFabTap() {
    setState(() => _currentIndex = 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _MyAdaFab(
        isActive: _currentIndex == 2,
        onTap: _onFabTap,
      ),
      bottomNavigationBar: _MyAdaBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}

// ─── FAB ───────────────────────────────────────────────────────────────────

class _MyAdaFab extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _MyAdaFab({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        // FAB size is hardcoded here, consider making it a constant in AppSpacing
        width: 56, // Example size, adjust as needed
        height: 56, // Example size, adjust as needed
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [AppColors.primaryLight, AppColors.primary]
                : [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isActive
                ? AppColors.primaryLight.withOpacity(0.6)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          isActive ? Icons.menu_book_rounded : Icons.menu_book_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ─────────────────────────────────────────────────

class _MyAdaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _MyAdaBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(
      icon: Icons.home_rounded,
      outlinedIcon: Icons.home_outlined,
      label: 'Home',
    ), // Using default icons, can be customized
    _NavItem(
      icon: Icons.bar_chart_rounded,
      outlinedIcon: Icons.bar_chart_outlined,
      label: 'Ranks',
    ),
    null, // FAB placeholder
    _NavItem(
      icon: Icons.assignment_rounded,
      outlinedIcon: Icons.assignment_outlined,
      label: 'Progress',
    ),
    _NavItem(
      icon: Icons.person_rounded,
      outlinedIcon: Icons.person_outlined,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          AppSpacing.bottomNavHeight + MediaQuery.of(context).padding.bottom,
      decoration: BoxDecoration(
        color: AppColors.surface, // Using surface for nav background
        border: const Border(
          // Using border for nav border
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          children: List.generate(_items.length, (i) {
            if (_items[i] == null) {
              // FAB spacer
              return const Expanded(child: SizedBox());
            }
            final item = _items[i]!;
            final isActive = currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isActive ? item.icon : item.outlinedIcon,
                        key: ValueKey(isActive),
                        color: isActive
                            ? AppColors
                                  .primary // Primary for active icon
                            : AppColors
                                  .mutedForeground, // Muted for inactive icon
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: AppTextStyles.caption.copyWith(
                        color: isActive
                            ? AppColors
                                  .primary // Primary for active label
                            : AppColors
                                  .mutedForeground, // Muted for inactive label
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
  });
}
