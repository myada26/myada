import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../components/cards/app_cards.dart';
import '../../../../components/navigation/global_sync_header.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/services/skill_profile_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/leaderboard_service.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../features/progress/data/services/challenge_service.dart';
import '../../../../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _studentRank = 0;
  int _pointsBehind = 0;
  int _totalPoints = 0;
  int _streak = 0;
  int _modulesCompleted = 0;
  Map<SkillCategory, double> _liveSkillScores = {};
  ChallengeModel? _dailyChallenge;
  ChallengeModel? _skillDrill;
  RetakeItem?    _retakeItem;

  @override
  void initState() {
    super.initState();
    _loadRankData();
    _loadLiveData();
  }

  Future<void> _loadRankData() async {
    final all = await LeaderboardService.instance.getRankedStudents();
    if (!mounted) return;
    final me = all.where((s) => s.isCurrentUser).firstOrNull;
    setState(() {
      _studentRank      = me?.rank             ?? 0;
      _pointsBehind     = me != null ? me.gapToAbove(all) : 0;
      _totalPoints      = me?.totalPoints      ?? 0;
      _streak           = me?.currentStreak    ?? 0;
      _modulesCompleted = me?.modulesCompleted ?? 0;
    });
  }

  Future<void> _loadLiveData() async {
    final scores    = await SkillProfileService.instance.getSkillScores();
    final daily     = await ChallengeService.instance.getDailyMasteryChallenge();
    final drill     = await ChallengeService.instance.getDailySkillDrill();
    final retakes   = await ChallengeService.instance.getRetakeSuggestions();
    if (!mounted) return;
    setState(() {
      _liveSkillScores = scores;
      _dailyChallenge  = daily;
      _skillDrill      = drill;
      _retakeItem      = retakes.isNotEmpty ? retakes.first : null;
    });
  }

  static double _moduleProgress(List<SkillResult> results) {
    if (results.isEmpty) return 0.0;
    return results.map((r) => r.barFraction).reduce((a, b) => a + b) /
        results.length;
  }

  void _onContinue(LearningModule? module) {
    if (module == null) return;
    Navigator.of(context).pushNamed(
      AppRoutes.lesson,
      arguments: {
        'lessonId': '${module.moduleId}_l01',
        'moduleId': module.moduleId,
        'lessonNumber': 1,
        'totalLessonsInModule': module.estimatedLessons,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pathCtrl = context.watch<LearningPathController>();
    final skillResults = pathCtrl.result?.skillResults ?? [];
    final startModule = pathCtrl.result?.startHereModule;
    final progress = _moduleProgress(skillResults);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                  vertical: AppSpacing.lg,
                ),
                child: const GlobalSyncHeader(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverToBoxAdapter(
                child: _StreakStrip(streak: _streak),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _HeroModuleCard(
                  module: startModule,
                  progress: progress,
                  onContinue: () => _onContinue(startModule),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xl,
                AppSpacing.screenPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SnapshotGrid(
                  rank: _studentRank,
                  points: _totalPoints,
                  pointsBehind: _pointsBehind,
                  streak: _streak,
                  modulesCompleted: _modulesCompleted,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xl,
                AppSpacing.screenPadding,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SkillBarsSection(liveScores: _liveSkillScores),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xl,
                AppSpacing.screenPadding,
                AppSpacing.xl2,
              ),
              sliver: SliverToBoxAdapter(
                child: _TodaysTasksSection(
                  pointsBehind:   _pointsBehind,
                  rank:           _studentRank,
                  dailyChallenge: _dailyChallenge,
                  skillDrill:     _skillDrill,
                  retakeItem:     _retakeItem,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.subtleForeground,
          letterSpacing: 0.08 * 10, // Approx 0.08em based on font size ~10
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 2 — Streak Strip
// ─────────────────────────────────────────────────────────────────────────────

enum _StreakTileState { done, today, empty }

class _StreakStrip extends StatelessWidget {
  final int streak;

  const _StreakStrip({required this.streak});

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    // Determine the state of each day in the Mon-Sun week.
    // 1 = Monday, 7 = Sunday
    final todayIndex = DateTime.now().weekday - 1; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('THIS WEEK · $streak DAY STREAK'),
        Row(
          children: List.generate(7, (index) {
            _StreakTileState state;
            if (index == todayIndex) {
              state = _StreakTileState.today;
            } else if (index < todayIndex && (todayIndex - index) <= streak) {
              state = _StreakTileState.done;
            } else {
              state = _StreakTileState.empty;
            }

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < 6 ? AppSpacing.xs : 0,
                ),
                child: _StreakTile(
                  label: _dayLabels[index],
                  state: state,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StreakTile extends StatelessWidget {
  final String label;
  final _StreakTileState state;

  const _StreakTile({required this.label, required this.state});

  @override
  Widget build(BuildContext context) {
    final Color bgColor = switch (state) {
      _StreakTileState.done => AppColors.success,
      _StreakTileState.today => AppColors.primary,
      _StreakTileState.empty => AppColors.surfaceVariant,
    };

    final Color textColor = switch (state) {
      _StreakTileState.done => Colors.white,
      _StreakTileState.today => Colors.white,
      _StreakTileState.empty => AppColors.subtleForeground,
    };

    final Color dotColor = switch (state) {
      _StreakTileState.done => AppColors.success,
      _StreakTileState.today => AppColors.primary,
      _StreakTileState.empty => AppColors.border,
    };

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 3 — Hero Module Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroModuleCard extends StatelessWidget {
  final LearningModule? module;
  final double progress;
  final VoidCallback onContinue;

  const _HeroModuleCard({
    required this.module,
    required this.progress,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final moduleName = module?.name ?? 'Loading...';
    // Use tagLabel if available, else fallback
    final tagLabel = module != null
        ? 'Module ${module!.number} · ${module!.tagLabel}'
        : 'Getting Started';

    return GestureDetector(
      onTap: onContinue,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tagLabel.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 0.06 * 10,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const _HeroBadge(label: 'In Progress'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              moduleName,
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primaryForeground,
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Hardcoding "Lesson 4 of X" to match the UI behavior for now.
                // In the future this should wire to ProgressService.
                Text(
                  module != null ? 'Lesson 1 of ${module!.estimatedLessons}' : '',
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: AppTextStyles.bodySm.copyWith(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.85),
                ),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _HeroResumeButton(onTap: onContinue),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _HeroResumeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroResumeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Let the gesture propagate to the card container
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        'Resume lesson 1 →', // Hardcoded number to match HTML's look for now
        style: AppTextStyles.bodySm.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 4 — Snapshot Grid
// ─────────────────────────────────────────────────────────────────────────────

class _SnapshotGrid extends StatelessWidget {
  final int rank;
  final int points;
  final int pointsBehind;
  final int streak;
  final int modulesCompleted;

  const _SnapshotGrid({
    required this.rank,
    required this.points,
    required this.pointsBehind,
    required this.streak,
    required this.modulesCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final rankLabel = rank > 0 ? '#$rank' : '—';
    final pointsSub = rank == 1
        ? "You're #1! 🏆"
        : "$pointsBehind pts from #${rank > 1 ? rank - 1 : 1}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('SNAPSHOT'),
        _SnapshotRow(children: [
          _SnapshotCard(label: 'rank', value: rankLabel, sub: 'of all students'),
          _SnapshotCard(label: 'points', value: '$points', sub: pointsSub),
        ]),
        const SizedBox(height: AppSpacing.sm),
        _SnapshotRow(children: [
          _SnapshotCard(
            label: 'streak',
            value: '$streak',
            sub: streak == 1 ? 'day streak' : 'days streak',
          ),
          _SnapshotCard(
            label: 'modules',
            value: '$modulesCompleted',
            sub: 'completed',
          ),
        ]),
      ],
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  final List<Widget> children;
  const _SnapshotRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: AppSpacing.sm)])
          .toList()
        ..removeLast(),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _SnapshotCard({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.h1.copyWith(fontSize: 26, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.subtleForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 5 — Skill Bars Section
// ─────────────────────────────────────────────────────────────────────────────

class _SkillBarsSection extends StatelessWidget {
  final Map<SkillCategory, double> liveScores;

  const _SkillBarsSection({required this.liveScores});

  static const _orderedSkills = [
    SkillCategory.sequencing,
    SkillCategory.logicFlow,
    SkillCategory.debugging,
    SkillCategory.syntax,
    SkillCategory.computationalThinking,
  ];

  static const _descriptions = {
    SkillCategory.sequencing:
        'Your ability to arrange steps in the correct logical order to solve a problem.',
    SkillCategory.logicFlow:
        'How well you trace and predict branching execution paths in a program.',
    SkillCategory.debugging:
        'Your skill at finding and fixing errors or unexpected behavior in programs.',
    SkillCategory.syntax:
        'Correct use of programming language rules, symbols, and structure.',
    SkillCategory.computationalThinking:
        'Breaking complex problems into smaller, manageable, and solvable steps.',
  };

  Color _colorForSkill(SkillCategory cat) {
    return switch (cat) {
      SkillCategory.sequencing             => AppColors.success,
      SkillCategory.logicFlow              => AppColors.primaryLight,
      SkillCategory.debugging              => AppColors.error,
      SkillCategory.syntax                 => AppColors.primary,
      SkillCategory.computationalThinking  => AppColors.accent,
    };
  }

  String _nameForSkill(SkillCategory cat) {
    return switch (cat) {
      SkillCategory.sequencing            => 'Sequencing',
      SkillCategory.logicFlow             => 'Logic Flow',
      SkillCategory.debugging             => 'Debugging',
      SkillCategory.syntax                => 'Syntax',
      SkillCategory.computationalThinking => 'Comp. Thinking',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('SKILL BREAKDOWN'),
        Column(
          children: _orderedSkills.map((cat) {
            final double pct = liveScores[cat] ?? 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _SkillBar(
                name: _nameForSkill(cat),
                color: _colorForSkill(cat),
                fraction: pct,
                description: _descriptions[cat]!,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SkillBar extends StatelessWidget {
  final String name;
  final Color color;
  final double fraction;
  final String description;

  const _SkillBar({
    required this.name,
    required this.color,
    required this.fraction,
    required this.description,
  });

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name, style: AppTextStyles.label),
        content: Text(description, style: AppTextStyles.bodySm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 90,
          child: Text(
            name,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 28,
          child: Text(
            '${(fraction * 100).round()}%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.subtleForeground,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        GestureDetector(
          onTap: () => _showInfo(context),
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.help_outline_rounded,
              size: 14,
              color: AppColors.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section 6 — Today's Tasks
// ─────────────────────────────────────────────────────────────────────────────

class _TodaysTasksSection extends StatelessWidget {
  final int pointsBehind;
  final int rank;
  final ChallengeModel? dailyChallenge;
  final ChallengeModel? skillDrill;
  final RetakeItem?    retakeItem;

  const _TodaysTasksSection({
    required this.pointsBehind,
    required this.rank,
    this.dailyChallenge,
    this.skillDrill,
    this.retakeItem,
  });

  @override
  Widget build(BuildContext context) {
    final leaderGapSub = rank > 1
        ? '$pointsBehind pts from rank #${rank - 1}'
        : 'You are leading!';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel("TODAY'S TASKS"),

        // ── Daily Mastery Challenge ─────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListCard(
              leading: const _TaskIcon(
                bgColor: AppColors.successLight,
                iconColor: AppColors.success,
                iconData: Icons.assignment_outlined,
              ),
              title: dailyChallenge?.title ?? 'Daily Challenge',
              subtitle: dailyChallenge != null
                  ? '${dailyChallenge!.description.split('.').first} · ${dailyChallenge!.timeLimitSeconds ~/ 60} min'
                  : 'No challenge available yet',
              trailing: dailyChallenge != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${dailyChallenge!.pointsReward} pts',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            const _CompleteItButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Skill Drill ─────────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListCard(
              leading: const _TaskIcon(
                bgColor: AppColors.surfaceVariant,
                iconColor: AppColors.primaryLight,
                iconData: Icons.fitness_center_rounded,
              ),
              title: skillDrill?.title ?? 'Skill Drill',
              subtitle: skillDrill?.description.split('.').first ??
                  'Practice your weakest skill',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.surfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            const _CompleteItButton(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Review / Leaderboard Gap ────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (retakeItem != null)
              ListCard(
                leading: const _TaskIcon(
                  bgColor: AppColors.accentSubtle,
                  iconColor: AppColors.accent,
                  iconData: Icons.replay_rounded,
                ),
                title: 'Review: ${retakeItem!.moduleTitle}',
                subtitle:
                    'Last score ${retakeItem!.lastScore.round()}% · Retake recommended',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surfaceVariant,
                ),
              )
            else
              ListCard(
                leading: const _TaskIcon(
                  bgColor: AppColors.surfaceVariant,
                  iconColor: AppColors.primaryLight,
                  iconData: Icons.leaderboard_rounded,
                ),
                title: 'Leaderboard gap',
                subtitle: leaderGapSub,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surfaceVariant,
                ),
              ),
            const SizedBox(height: 6),
            const _CompleteItButton(),
          ],
        ),
      ],
    );
  }
}

class _TaskIcon extends StatelessWidget {
  final Color bgColor;
  final Color iconColor;
  final IconData? iconData;

  const _TaskIcon({
    required this.bgColor,
    required this.iconColor,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Center(
        child: Icon(iconData, color: iconColor, size: 18),
      ),
    );
  }
}

class _CompleteItButton extends StatelessWidget {
  const _CompleteItButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      alignment: Alignment.center,
      child: Text(
        'Complete it',
        style: AppTextStyles.buttonSm.copyWith(color: Colors.white),
      ),
    );
  }
}
