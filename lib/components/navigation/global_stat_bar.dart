// lib/components/navigation/global_stat_bar.dart
//
// Shared stat bar used on Ranks, Learning Path, and Challenges screens.
// Left side: star icon + total points value.
// Right side: two chips in one pill — leaderboard rank and streak — separated
// by a thin vertical divider. Data comes from PointsService (reactive) and
// LeaderboardService (async, loads on mount).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/leaderboard_service.dart';
import '../../../../core/services/leaderboard_models.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class GlobalStatBar extends StatefulWidget {
  const GlobalStatBar({super.key});

  @override
  State<GlobalStatBar> createState() => _GlobalStatBarState();
}

class _GlobalStatBarState extends State<GlobalStatBar> {
  int _rank   = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadRankData();
  }

  Future<void> _loadRankData() async {
    final RankedStudent? me =
        await LeaderboardService.instance.getCurrentUserRank();
    if (!mounted) return;
    setState(() {
      _rank   = me?.rank          ?? 0;
      _streak = me?.currentStreak ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = context.watch<PointsService>().totalPoints;
    final rankLabel   = _rank > 0 ? '#$_rank' : '—';

    return Row(
      children: [
        // ── Left: star + points ─────────────────────────────────────────────
        const Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          '$totalPoints',
          style: AppTextStyles.labelSm.copyWith(
            fontSize: 15,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          'pts',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),

        const Spacer(),

        // ── Right: rank | streak chips ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rank chip
              Icon(
                Icons.emoji_events_rounded,
                size: 14,
                color: AppColors.mutedForeground,
              ),
              const SizedBox(width: 4),
              Text(
                rankLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Thin vertical divider
              Container(
                width: 1,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                color: AppColors.border,
              ),

              // Streak chip
              Icon(
                Icons.local_fire_department_rounded,
                size: 14,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Text(
                '$_streak',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
