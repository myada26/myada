// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import '../../../../components/navigation/global_sync_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ChallengeData {
  final String title;
  final String subtitle;
  final double progress;
  final String status;
  final Color accentColor;
  final Color iconBg;
  final Color iconFg;
  final Color pillBg;
  final Color pillFg;
  final String pointsLabel;
  const _ChallengeData({
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.status,
    required this.accentColor,
    required this.iconBg,
    required this.iconFg,
    required this.pillBg,
    required this.pillFg,
    required this.pointsLabel,
  });
}

class _RetakeData {
  final String title;
  final String score;
  final Color scoreColor;
  final String reason;
  final String buttonLabel;
  const _RetakeData({
    required this.title,
    required this.score,
    required this.scoreColor,
    required this.reason,
    required this.buttonLabel,
  });
}

class _NextExamData {
  final String comingUpLabel;
  final String title;
  final String subtitle;
  final double readinessPercent;
  final String ctaLabel;
  const _NextExamData({
    required this.comingUpLabel,
    required this.title,
    required this.subtitle,
    required this.readinessPercent,
    required this.ctaLabel,
  });
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  static const _challenges = [
    _ChallengeData(
      title: 'Functions & Scope',
      subtitle: 'Module 2 · Timed · 15 min',
      progress: 0.6,
      status: 'In Progress',
      accentColor: AppColors.success,
      iconBg: AppColors.successLight,
      iconFg: AppColors.success,
      pillBg: AppColors.successLight,
      pillFg: AppColors.success,
      pointsLabel: '+120 pts',
    ),
    _ChallengeData(
      title: 'Logic Flow',
      subtitle: 'Module 1 · Timed · 10 min',
      progress: 0.0,
      status: 'Pending',
      accentColor: AppColors.primary,
      iconBg: AppColors.primaryLight,
      iconFg: AppColors.primary,
      pillBg: AppColors.primaryLight,
      pillFg: AppColors.primary,
      pointsLabel: '+80 pts',
    ),
    _ChallengeData(
      title: 'Debugging',
      subtitle: 'Module 2 · Timed · 20 min',
      progress: 0.0,
      status: 'Pending',
      accentColor: AppColors.error,
      iconBg: AppColors.errorLight,
      iconFg: AppColors.error,
      pillBg: AppColors.errorLight,
      pillFg: AppColors.error,
      pointsLabel: '+100 pts',
    ),
  ];

  static const _retakes = [
    _RetakeData(
      title: 'Conditionals Quiz',
      score: '42%',
      scoreColor: AppColors.error,
      reason: 'You scored below 50% — a retake is recommended.',
      buttonLabel: 'Retake Quiz',
    ),
    _RetakeData(
      title: 'Variables & Types',
      score: '61%',
      scoreColor: AppColors.warning,
      reason: 'Improve your score to unlock the next module.',
      buttonLabel: 'Retake Quiz',
    ),
  ];

  static const _nextExam = _NextExamData(
    comingUpLabel: 'Coming up',
    title: 'Module 3 Exam',
    subtitle: 'Branching Realities · 30 questions',
    readinessPercent: 0.72,
    ctaLabel: 'Start Early',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ChallengeHeader()),
            SliverToBoxAdapter(child: _StatsRow()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: 'Timed challenges', count: '3 pending'),
                  const SizedBox(height: AppSpacing.sm),
                  ..._challenges.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ChallengeCard(data: c),
                      )),
                  const _HorizontalDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(title: 'Retake suggestions', count: '2 quizzes'),
                  const SizedBox(height: AppSpacing.sm),
                  ..._retakes.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RetakeCard(data: r),
                      )),
                  const _HorizontalDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(title: 'Next exam', count: 'Module 3'),
                  const SizedBox(height: AppSpacing.sm),
                  _NextExamCard(data: _nextExam),
                  const SizedBox(height: AppSpacing.xl2),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ChallengeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlobalSyncHeader(),
          const SizedBox(height: AppSpacing.md),
          Text('Challenges', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Track your timed challenges and exam readiness',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.popover,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5),
        ),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _StatBox(
              label: 'Completed',
              value: '4',
              valueColor: AppColors.success,
              subLabel: 'challenges',
            ),
          ),
          Expanded(
            child: _StatBox(
              label: 'Retakes',
              value: '2',
              valueColor: AppColors.error,
              subLabel: 'suggested',
            ),
          ),
          Expanded(
            child: _StatBox(
              label: 'Points',
              value: '360',
              valueColor: AppColors.primary,
              subLabel: 'earned',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String subLabel;

  const _StatBox({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.subtleForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.headingMedium),
        const Spacer(),
        Text(
          count,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}

// ── Challenge Card ────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final _ChallengeData data;

  const _ChallengeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.popover,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: data.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.timer_rounded, color: data.iconFg, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 2),
                Text(
                  data.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ProgressBar(
                  value: data.progress,
                  color: data.accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(
                label: data.status,
                bg: data.pillBg,
                fg: data.pillFg,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data.pointsLabel,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _StatusPill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Progress Bar ──────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double value;
  final Color color;

  const _ProgressBar({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 3,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Retake Card ───────────────────────────────────────────────────────────────

class _RetakeCard extends StatelessWidget {
  final _RetakeData data;

  const _RetakeCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.popover,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(data.title, style: AppTextStyles.headingSmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                data.score,
                style: AppTextStyles.headingSmall.copyWith(
                  color: data.scoreColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.reason,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.challengePurple,
                side: const BorderSide(color: AppColors.challengePurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(data.buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Next Exam Card ────────────────────────────────────────────────────────────

class _NextExamCard extends StatelessWidget {
  final _NextExamData data;

  const _NextExamCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.comingUpLabel.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryForeground.withAlpha(180),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.title,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.primaryForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryForeground.withAlpha(180),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text(
                'Readiness',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryForeground.withAlpha(180),
                ),
              ),
              const Spacer(),
              Text(
                '${(data.readinessPercent * 100).round()}%',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primaryForeground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ProgressBar(
            value: data.readinessPercent,
            color: AppColors.primaryForeground,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryForeground,
                foregroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(data.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Horizontal Divider ────────────────────────────────────────────────────────

class _HorizontalDivider extends StatelessWidget {
  const _HorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(thickness: 0.5, color: Color(0xFFEEEEEE)),
    );
  }
}
