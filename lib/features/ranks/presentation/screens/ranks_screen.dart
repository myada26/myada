// lib/features/ranks/presentation/screens/ranks_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({super.key});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spacingMD,
                AppConstants.spacingMD,
                AppConstants.spacingMD,
                AppConstants.spacingMD,
              ),
              child: Text('Recognition', style: AppTextStyles.displayMedium),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLG),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMD),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: AppTextStyles.labelMedium
                    .copyWith(color: Colors.white),
                unselectedLabelStyle: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary),
                tabs: const [
                  Tab(text: 'Leaderboard'),
                  Tab(text: 'Badges'),
                  Tab(text: 'Certificates'),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacingMD),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LeaderboardTab(),
                  _BadgesTab(),
                  _CertificatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leaderboard Tab ───────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD),
      child: Column(
        children: [
          // Podium placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusLG),
              border: Border.all(color: AppColors.navBorder),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events_rounded,
                      color: AppColors.textMuted.withOpacity(0.3),
                      size: 48),
                  const SizedBox(height: AppConstants.spacingSM),
                  Text('No rankings yet',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Complete modules to appear on the leaderboard',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingMD),
          // Rank list placeholder
          ...List.generate(
              5,
              (i) => Container(
                    margin: const EdgeInsets.only(
                        bottom: AppConstants.spacingSM),
                    padding:
                        const EdgeInsets.all(AppConstants.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(
                          AppConstants.radiusMD),
                      border:
                          Border.all(color: AppColors.navBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '#${i + 1}',
                              style: AppTextStyles.labelMedium
                                  .copyWith(
                                      color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: AppConstants.spacingMD),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: AppColors.textMuted, size: 16),
                        ),
                        const SizedBox(
                            width: AppConstants.spacingSM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 12,
                                width: 80 + (i * 15.0),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusFull),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 8,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(
                                      AppConstants.radiusFull),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 12,
                          width: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(
                                AppConstants.radiusFull),
                          ),
                        ),
                      ],
                    ),
                  )),
          const SizedBox(height: AppConstants.spacingXXL),
        ],
      ),
    );
  }
}

// ─── Badges Tab ────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  static const _badgeData = [
    ('First Step', Icons.directions_walk_rounded, 'Complete your first lesson', false),
    ('Bug Hunter', Icons.bug_report_rounded, 'Find 5 bugs in Debugging module', false),
    ('Streak Starter', Icons.local_fire_department_rounded, '3-day learning streak', false),
    ('Logic Master', Icons.account_tree_rounded, 'Ace Logic Flow module', false),
    ('Perfect Score', Icons.star_rounded, 'Score 100% on any quiz', false),
    ('Code Warrior', Icons.shield_rounded, 'Complete 5 coding exercises', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary strip
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  BorderRadius.circular(AppConstants.radiusLG),
              border: Border.all(color: AppColors.navBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(value: '0', label: 'Earned'),
                _VertDivider(),
                _SummaryStat(value: '${_badgeData.length}', label: 'Locked'),
                _VertDivider(),
                _SummaryStat(value: '0%', label: 'Collected'),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.spacingMD),
          Text('All Badges', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppConstants.spacingSM),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppConstants.spacingSM,
              mainAxisSpacing: AppConstants.spacingSM,
              childAspectRatio: 0.85,
            ),
            itemCount: _badgeData.length,
            itemBuilder: (context, i) {
              final b = _badgeData[i];
              return Container(
                padding: const EdgeInsets.all(AppConstants.spacingSM),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMD),
                  border: Border.all(color: AppColors.navBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.locked,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(b.$2,
                          color: AppColors.textMuted.withOpacity(0.4),
                          size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.$1,
                      style: AppTextStyles.labelSmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppConstants.spacingXXL),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String value;
  final String label;
  const _SummaryStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headingLarge),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.navBorder,
    );
  }
}

// ─── Certificates Tab ──────────────────────────────────────────────────────

class _CertificatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusXL),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 40,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppConstants.spacingLG),
            Text('No certificates yet',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: AppConstants.spacingSM),
            Text(
              'Complete a module to earn your first certificate',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
