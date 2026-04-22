// lib/features/ranks/presentation/screens/ranks_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/services/leaderboard_service.dart';
import '../../../../core/services/leaderboard_models.dart';
import '../../../../core/engine/badge_engine.dart';
import '../../../../core/engine/badge_definitions.dart';
import '../../../../components/navigation/global_sync_header.dart';

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
                AppSpacing.screenPadding,
                AppConstants.spacingMD,
                AppSpacing.screenPadding,
                AppConstants.spacingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GlobalSyncHeader(),
                  const SizedBox(height: AppConstants.spacingMD),
                  Text('Recognition', style: AppTextStyles.displayMedium),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusLG),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(vertical: 4),
                labelStyle: AppTextStyles.label.copyWith(color: Colors.white),
                unselectedLabelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
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
                  const _BadgesTab(),
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
    // Rebuild whenever points change
    context.watch<PointsService>();

    return FutureBuilder<List<RankedStudent>>(
      future: LeaderboardService.instance.getRankedStudents(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final students = snap.data!;
        if (students.isEmpty) {
          return _emptyLeaderboard();
        }

        final currentUser = students.where((s) => s.isCurrentUser).firstOrNull;
        final top3 = students.take(3).toList();
        final rest = students.length > 3 ? students.sublist(3) : <RankedStudent>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              // Your card — pinned at top
              if (currentUser != null)
                _YourCard(student: currentUser, allStudents: students),

              const SizedBox(height: AppConstants.spacingMD),

              // Top 3 podium
              if (top3.isNotEmpty) _Podium(top3: top3),

              const SizedBox(height: AppConstants.spacingMD),

              // Rank list (4+)
              ...rest.map((s) => _RankRow(student: s)),

              // Last updated
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Updated just now',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.mutedForeground),
                ),
              ),

              const SizedBox(height: AppConstants.spacingXXL),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyLeaderboard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded,
              color: AppColors.textMuted.withAlpha(60), size: 48),
          const SizedBox(height: AppConstants.spacingSM),
          Text('No rankings yet', style: AppTextStyles.headingSmall),
          const SizedBox(height: 4),
          Text(
            'Complete modules to appear on the leaderboard',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Your Card (pinned) ─────────────────────────────────────────────────────

class _YourCard extends StatelessWidget {
  final RankedStudent student;
  final List<RankedStudent> allStudents;
  const _YourCard({required this.student, required this.allStudents});

  @override
  Widget build(BuildContext context) {
    final gap = student.gapToAbove(allStudents);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2B4CB5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: AppTextStyles.label.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white.withAlpha(180)),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '#${student.rank}',
                      style: AppTextStyles.h2.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${student.totalPoints} pts',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.accentLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (gap > 0)
                  Text(
                    '$gap pts behind rank ${student.rank - 1}',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white.withAlpha(140)),
                  ),
              ],
            ),
          ),
          // Streak indicator
          Column(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              Text(
                '${student.currentStreak}',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Podium (Top 3) ─────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<RankedStudent> top3;
  const _Podium({required this.top3});

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          if (second != null)
            _PodiumSpot(student: second, height: 70, medal: '🥈', rank: 2)
          else
            const Expanded(child: SizedBox()),

          // 1st place — elevated
          if (first != null)
            _PodiumSpot(student: first, height: 95, medal: '🥇', rank: 1)
          else
            const Expanded(child: SizedBox()),

          // 3rd place
          if (third != null)
            _PodiumSpot(student: third, height: 55, medal: '🥉', rank: 3)
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  final RankedStudent student;
  final double height;
  final String medal;
  final int rank;
  const _PodiumSpot({
    required this.student,
    required this.height,
    required this.medal,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseColor;
    switch (rank) {
      case 1:  baseColor = AppColors.accent; break;
      case 2:  baseColor = AppColors.primary; break;
      default: baseColor = AppColors.success; break;
    }

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(medal, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: baseColor.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: baseColor.withAlpha(80), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: AppTextStyles.label.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            student.name.split(' ').first,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${student.totalPoints} pts',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.mutedForeground, fontSize: 11),
          ),
          const SizedBox(height: 8),
          // Podium bar
          Container(
            width: double.infinity,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [baseColor.withAlpha(40), baseColor.withAlpha(20)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(
                top: BorderSide(color: baseColor.withAlpha(60)),
                left: BorderSide(color: baseColor.withAlpha(40)),
                right: BorderSide(color: baseColor.withAlpha(40)),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: AppTextStyles.label.copyWith(
                color: baseColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rank Row (4th+) ────────────────────────────────────────────────────────

class _RankRow extends StatelessWidget {
  final RankedStudent student;
  const _RankRow({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: student.isCurrentUser
            ? AppColors.primaryLight // Keeps current user row distinct but consistent
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(
          color: student.isCurrentUser
              ? AppColors.primary.withAlpha(60)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '#${student.rank}',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              student.initials,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingSM),
          // Name
          Expanded(
            child: Text(
              student.name,
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: student.isCurrentUser
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points
          Text(
            '${student.totalPoints} pts',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Badges Tab ────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, DateTime>>(
      future: BadgeEngine.instance.getEarnedBadgesWithDates(),
      builder: (context, snap) {
        final earned = snap.data ?? {};
        final allBadges = BadgeRegistry.all;
        final earnedCount = earned.length;
        final totalCount = allBadges.length;
        final pct = totalCount > 0
            ? ((earnedCount / totalCount) * 100).round()
            : 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding),
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
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(value: '$earnedCount', label: 'Earned'),
                    _VertDivider(),
                    _SummaryStat(
                        value: '${totalCount - earnedCount}',
                        label: 'Locked'),
                    _VertDivider(),
                    _SummaryStat(value: '$pct%', label: 'Collected'),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.spacingMD),

              Text('All Badges', style: AppTextStyles.headingSmall),
              const SizedBox(height: AppConstants.spacingSM),

              // Badge grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppConstants.spacingSM,
                  mainAxisSpacing: AppConstants.spacingSM,
                  childAspectRatio: 0.75,
                ),
                itemCount: allBadges.length,
                itemBuilder: (context, i) {
                  final badge = allBadges[i];
                  final isEarned = earned.containsKey(badge.id);
                  final earnedDate = earned[badge.id];

                  return _BadgeTile(
                    badge: badge,
                    isEarned: isEarned,
                    earnedDate: earnedDate,
                  );
                },
              ),

              const SizedBox(height: AppConstants.spacingXXL),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeDef badge;
  final bool isEarned;
  final DateTime? earnedDate;
  const _BadgeTile({
    required this.badge,
    required this.isEarned,
    this.earnedDate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingSM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusMD),
          border: Border.all(
            color: isEarned
                ? badge.categoryColor.withAlpha(80)
                : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEarned
                    ? badge.categoryBgColor
                    : AppColors.locked,
                shape: BoxShape.circle,
                border: isEarned
                    ? Border.all(
                        color: badge.categoryColor.withAlpha(60), width: 2)
                    : null,
              ),
              child: Icon(
                badge.icon,
                color: isEarned
                    ? badge.categoryColor
                    : AppColors.textMuted.withAlpha(80),
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            // Name
            Text(
              badge.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: isEarned
                    ? AppColors.foreground
                    : AppColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Category pill
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isEarned
                    ? badge.categoryBgColor
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                badge.categoryLabel,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isEarned
                      ? badge.categoryColor
                      : AppColors.mutedForeground,
                ),
              ),
            ),
            if (badge.isRare && isEarned) ...[
              const SizedBox(height: 2),
              Text(
                '✦ RARE',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isEarned ? badge.categoryBgColor : AppColors.locked,
                shape: BoxShape.circle,
              ),
              child: Icon(badge.icon,
                  size: 30,
                  color: isEarned
                      ? badge.categoryColor
                      : AppColors.mutedForeground),
            ),
            const SizedBox(height: 14),
            Text(badge.name, style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badge.categoryBgColor,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    badge.categoryLabel,
                    style: AppTextStyles.caption.copyWith(
                      color: badge.categoryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (badge.isRare) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAECE7),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                    ),
                    child: Text(
                      'Rare',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF712B13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              style: AppTextStyles.bodySm
                  .copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
            if (isEarned && earnedDate != null) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  'Earned on ${earnedDate!.day}/${earnedDate!.month}/${earnedDate!.year}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (!isEarned) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  '🔒 Not yet earned',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
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
      color: AppColors.border,
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
                color: AppColors.primary.withAlpha(20),
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusXL),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                size: 40,
                color: AppColors.primary.withAlpha(120),
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
