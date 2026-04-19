// lib/features/home/presentation/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../main.dart';

// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user     = context.watch<AuthController>().currentUser;
    final pathCtrl = context.watch<LearningPathController>();

    final firstName    = user?.firstName ?? 'Student';
    final level        = user?.startingLevel ?? 'Beginner';
    final startModule  = pathCtrl.result?.startHereModule;
    final skillResults = pathCtrl.result?.skillResults ?? [];
    final hasResult    = pathCtrl.hasResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day 5 of your learning streak',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Welcome back, $firstName',
                            style: AppTextStyles.h2,
                          ),
                        ],
                      ),
                    ),
                    _AvatarCircle(name: firstName, level: level),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Offline banner ───────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _OfflineBanner(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Streak card ──────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _StreakCard(streak: 5, activeDays: [true, true, true, true, true, false, false]),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Continue card ────────────────────────────────────────────────
            if (hasResult) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Continue Where You Left Off',
                      style: AppTextStyles.headingSmall),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: startModule != null
                      ? _ContinueCard(module: startModule)
                      : _EmptyContinueCard(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ── Skill map ────────────────────────────────────────────────────
            if (skillResults.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Your Skill Map',
                      style: AppTextStyles.headingSmall),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SkillMapGrid(skillResults: skillResults),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],

            // ── Quick actions ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Quick Actions', style: AppTextStyles.headingSmall),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _QuickActionsRow(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Badges ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Badges Earned', style: AppTextStyles.headingSmall),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SliverToBoxAdapter(child: _BadgesRow()),

            // ── Empty placeholder (no diagnostic yet) ────────────────────────
            if (!hasResult && !pathCtrl.isBuilding)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.explore_outlined,
                            size: 64, color: AppColors.mutedForeground),
                        const SizedBox(height: 16),
                        Text('Your journey starts here',
                            style: AppTextStyles.h2,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your diagnostic to unlock a personalised learning path.',
                          style: AppTextStyles.bodyLg
                              .copyWith(color: AppColors.mutedForeground),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Avatar circle ──────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  final String name;
  final String level;
  const _AvatarCircle({required this.name, required this.level});

  Color get _bg {
    switch (level) {
      case 'Intermediate': return AppColors.successLight;
      case 'Novice':       return AppColors.primaryLight;
      default:             return AppColors.warningLight;
    }
  }

  Color get _fg {
    switch (level) {
      case 'Intermediate': return AppColors.success;
      case 'Novice':       return AppColors.primary;
      default:             return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: _bg,
        shape: BoxShape.circle,
        border: Border.all(color: _fg.withAlpha(60), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.label.copyWith(
          color: _fg,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ── Offline banner ──────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.foreground,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline-ready — your progress saves automatically.',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withAlpha(220),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Streak card ────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  final List<bool> activeDays; // 7 entries: Mon-Sun
  const _StreakCard({required this.streak, required this.activeDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: icon + text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '$streak-day streak',
                      style: AppTextStyles.h2.copyWith(fontSize: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep it going — you\'re on a roll!',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          // Right: dot row
          Row(
            children: List.generate(activeDays.length, (i) {
              final active = activeDays[i];
              return Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.warning : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Continue card ──────────────────────────────────────────────────────────────

class _ContinueCard extends StatelessWidget {
  final LearningModule module;
  const _ContinueCard({required this.module});

  @override
  Widget build(BuildContext context) {
    final moduleId = module.moduleId;
    const completedLessons = 0; // TODO: read from ProgressService
    final totalLessons     = module.estimatedLessons;
    final pct = totalLessons > 0 ? completedLessons / totalLessons : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.foreground,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module tag chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(80),
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
            child: Text(
              '${module.tagLabel} · Module ${module.number}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Lesson title
          Text(
            module.name,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),

          // Meta
          const SizedBox(height: 4),
          Text(
            '$totalLessons lessons · ~20 min',
            style: AppTextStyles.bodySm.copyWith(
              color: Colors.white.withAlpha(160),
            ),
          ),

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).round()}%',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$totalLessons lessons left',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withAlpha(140),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Resume button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.lesson,
                  arguments: {
                    'lessonId': '${moduleId}_l01',
                    'moduleId': moduleId,
                    'lessonNumber': 1,
                    'totalLessonsInModule': totalLessons,
                  },
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusMD),
                ),
              ),
              child: const Text('Resume lesson →'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyContinueCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No active module yet — head to the Learning Path to start.',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground),
      ),
    );
  }
}

// ── Skill map 2×n grid ─────────────────────────────────────────────────────────

class _SkillMapGrid extends StatelessWidget {
  final List<SkillResult> skillResults;
  const _SkillMapGrid({required this.skillResults});

  static const _skillNames = [
    'Sequencing', 'Logic Flow', 'Debugging', 'Syntax', 'Comp. Thinking',
  ];
  static const _skillIcons = [
    Icons.swap_vert_rounded,
    Icons.account_tree_rounded,
    Icons.bug_report_rounded,
    Icons.code_rounded,
    Icons.psychology_rounded,
  ];

  Color _barColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:  return AppColors.success;
      case SkillLevel.building:   return AppColors.primary;
      case SkillLevel.developing: return AppColors.warning;
    }
  }

  String _levelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:  return 'Confident';
      case SkillLevel.building:   return 'Building';
      case SkillLevel.developing: return 'Developing';
    }
  }

  Color _badgeBg(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:  return AppColors.successLight;
      case SkillLevel.building:   return AppColors.primaryLight;
      case SkillLevel.developing: return AppColors.warningLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2-column grid
    final rows = <Widget>[];
    for (int i = 0; i < skillResults.length; i += 2) {
      final left  = _buildCard(i);
      final right = i + 1 < skillResults.length ? _buildCard(i + 1) : const SizedBox.expand();
      rows.add(Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ));
      if (i + 2 < skillResults.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  Widget _buildCard(int i) {
    final skill = skillResults[i];
    final name  = i < _skillNames.length ? _skillNames[i] : 'Skill $i';
    final icon  = i < _skillIcons.length ? _skillIcons[i] : Icons.star;
    final color = _barColor(skill.level);
    final label = _levelLabel(skill.level);
    final bg    = _badgeBg(skill.level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level badge top-right + icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(name, style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: skill.barFraction,
              minHeight: 5,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions row ──────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ActionCard(icon: Icons.bolt_rounded, label: 'Daily Challenge', color: AppColors.accent)),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(icon: Icons.bar_chart_rounded, label: 'My Progress', color: AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _ActionCard(icon: Icons.leaderboard_rounded, label: 'Leaderboard', color: AppColors.success)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ActionCard({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tinted icon container — matches the module number circle on LearnScreen
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(26), // ~10% tint
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

// ── Badges row ────────────────────────────────────────────────────────────────

class _BadgesRow extends StatelessWidget {
  const _BadgesRow();

  static const _badges = [
    _BadgeDef(
      icon: Icons.play_lesson_rounded,
      name: 'First Lesson',
      color: AppColors.primary,
      earned: true,
    ),
    _BadgeDef(
      icon: Icons.local_fire_department_rounded,
      name: '5-Day Streak',
      color: AppColors.warning,
      earned: true,
    ),
    _BadgeDef(
      icon: Icons.speed_rounded,
      name: 'Speed Run',
      color: AppColors.success,
      earned: false,
    ),
    _BadgeDef(
      icon: Icons.workspace_premium_rounded,
      name: 'Module 1',
      color: AppColors.accent,
      earned: false,
    ),
    _BadgeDef(
      icon: Icons.military_tech_rounded,
      name: 'Quiz Ace',
      color: AppColors.primary,
      earned: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _BadgeCard(badge: _badges[i]),
      ),
    );
  }
}

@immutable
class _BadgeDef {
  final IconData icon;
  final String name;
  final Color color;
  final bool earned;
  const _BadgeDef({
    required this.icon,
    required this.name,
    required this.color,
    required this.earned,
  });
}

class _BadgeCard extends StatelessWidget {
  final _BadgeDef badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final iconColor = badge.earned ? badge.color : AppColors.mutedForeground;
    final bgColor   = badge.earned ? badge.color.withAlpha(26) : AppColors.surfaceVariant;
    final borderColor = badge.earned
        ? badge.color.withAlpha(70)
        : AppColors.border;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusLG),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Tinted icon container — same pattern as _ActionCard
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
            child: Icon(badge.icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badge.earned
                  ? AppColors.foreground
                  : AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
