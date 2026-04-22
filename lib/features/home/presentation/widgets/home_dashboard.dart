import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../models/learning_path_model.dart';

class HomeDashboard extends StatelessWidget {
  final double moduleProgress;
  final String currentModuleName;
  final int studentRank;
  final int pointsBehind;
  final String bestSkill;
  final String weakestSkill;
  final String? userAvatarUrl;
  final String userInitials;
  final bool isOnline;

  final String lastLessonTitle;
  final String lastModuleName;
  final double lastLessonProgress;
  final VoidCallback onContinuePressed;

  final List<SkillResult> skillResults;

  const HomeDashboard({
    super.key,
    required this.moduleProgress,
    required this.currentModuleName,
    required this.studentRank,
    required this.pointsBehind,
    required this.bestSkill,
    required this.weakestSkill,
    required this.userInitials,
    required this.isOnline,
    required this.lastLessonTitle,
    required this.lastModuleName,
    required this.lastLessonProgress,
    required this.onContinuePressed,
    required this.skillResults,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _HubSection(
            moduleProgress: moduleProgress,
            currentModuleName: currentModuleName,
            studentRank: studentRank,
            pointsBehind: pointsBehind,
            bestSkill: bestSkill,
            weakestSkill: weakestSkill,
            userInitials: userInitials,
            userAvatarUrl: userAvatarUrl,
            isOnline: isOnline,
          ),
          _ContinueLearningSection(
            lastLessonTitle: lastLessonTitle,
            lastModuleName: lastModuleName,
            lastLessonProgress: lastLessonProgress,
            onPressed: onContinuePressed,
          ),
          _SkillMapSection(skillResults: skillResults),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hub Section
// ---------------------------------------------------------------------------

class _HubSection extends StatelessWidget {
  final double moduleProgress;
  final String currentModuleName;
  final int studentRank;
  final int pointsBehind;
  final String bestSkill;
  final String weakestSkill;
  final String userInitials;
  final String? userAvatarUrl;
  final bool isOnline;

  const _HubSection({
    required this.moduleProgress,
    required this.currentModuleName,
    required this.studentRank,
    required this.pointsBehind,
    required this.bestSkill,
    required this.weakestSkill,
    required this.userInitials,
    required this.isOnline,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double baseWidth = 390;
        const double hubHeight = 480;
        final double scale = constraints.maxWidth / baseWidth;

        return Container(
          width: constraints.maxWidth,
          height: hubHeight * scale,
          color: AppColors.background,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildGradients(scale),

              // Module Progress — top left
              Positioned(
                left: 20 * scale,
                top: 40 * scale,
                child: _StatCard(
                  title: 'MODULE PROGRESS',
                  value: '${(moduleProgress * 100).toInt()}%',
                  subtext: currentModuleName,
                  icon: Icons.bar_chart_rounded,
                  color: AppColors.challengeTeal,
                  backgroundColor: AppColors.challengeTealLight,
                  progress: moduleProgress,
                  valueFontSize: 38,
                  scale: scale,
                ),
              ),

              // Your Rank — top right
              Positioned(
                right: 20 * scale,
                top: 20 * scale,
                child: _StatCard(
                  title: 'YOUR RANK',
                  value: '#$studentRank',
                  subtext: studentRank <= 1
                      ? 'You are ranked #1!'
                      : '$pointsBehind pts behind #${studentRank - 1}',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.challengePurple,
                  backgroundColor: AppColors.challengePurpleLight,
                  valueFontSize: 44,
                  scale: scale,
                ),
              ),

              // Best Skill — mid right
              Positioned(
                right: 15 * scale,
                top: 220 * scale,
                child: _StatCard(
                  title: 'BEST SKILL',
                  value: bestSkill,
                  subtext: 'Keep it sharp',
                  icon: Icons.lightbulb_rounded,
                  color: AppColors.challengeAmber,
                  backgroundColor: AppColors.challengeAmberLight,
                  valueFontSize: 26,
                  scale: scale,
                ),
              ),

              // Weakest Skill — mid left
              Positioned(
                left: 15 * scale,
                top: 250 * scale,
                child: _StatCard(
                  title: 'WEAKEST SKILL',
                  value: weakestSkill,
                  subtext: 'Needs practice',
                  icon: Icons.flash_on_rounded,
                  color: AppColors.challengeCoral,
                  backgroundColor: AppColors.challengeCoralLight,
                  valueFontSize: 22,
                  scale: scale,
                ),
              ),

              // Center avatar
              Align(
                alignment: Alignment.center,
                child: _AvatarHub(
                  userInitials: userInitials,
                  userAvatarUrl: userAvatarUrl,
                  isOnline: isOnline,
                  scale: scale,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradients(double scale) {
    const pillars = [
      // (left, top, topLeft corner)
      (21.0, 160.0, true),
      // (left, top, topRight corner)
      (109.0, 81.0, false),
      // (left, top, topRight corner) — was missing
      (197.0, 140.0, false),
      // (left, top, topRight corner)
      (286.0, 185.0, false),
    ];

    return Stack(
      children: pillars.map((p) {
        final left = p.$1;
        final top = p.$2;
        final isTopLeft = p.$3;
        return Positioned(
          left: left * scale,
          top: top * scale,
          child: Container(
            width: 181 * scale,
            height: 718 * scale,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.popover,
                  AppColors.popover.withValues(alpha: 0),
                ],
              ),
              borderRadius: isTopLeft
                  ? const BorderRadius.only(topLeft: Radius.circular(90))
                  : const BorderRadius.only(topRight: Radius.circular(90)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar Hub
// ---------------------------------------------------------------------------

class _AvatarHub extends StatelessWidget {
  final String userInitials;
  final String? userAvatarUrl;
  final bool isOnline;
  final double scale;

  const _AvatarHub({
    required this.userInitials,
    required this.isOnline,
    required this.scale,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140 * scale,
      height: 140 * scale,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.popover, width: 8 * scale),
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.05),
            blurRadius: 20 * scale,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 70 * scale,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage:
                userAvatarUrl != null ? NetworkImage(userAvatarUrl!) : null,
            child: userAvatarUrl == null
                ? Text(
                    userInitials,
                    style: AppTextStyles.h1.copyWith(
                      fontSize: 32 * scale,
                      color: AppColors.mutedForeground,
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 4 * scale,
            right: 4 * scale,
            child: _PulseIndicator(isOnline: isOnline, scale: scale),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat Card
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtext;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double? progress;
  final double? valueFontSize;
  final double scale;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtext,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.scale,
    this.progress,
    this.valueFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155 * scale,
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24 * scale),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.foreground.withValues(alpha: 0.02),
            blurRadius: 10 * scale,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color, size: 20 * scale),
          ),
          SizedBox(height: 14 * scale),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.mutedForeground,
              fontSize: 9 * scale,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 4 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.h2.copyWith(
                color: color,
                fontSize: (valueFontSize ?? 24) * scale,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            subtext,
            style: AppTextStyles.bodySm.copyWith(fontSize: 11 * scale),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (progress != null) ...[
            SizedBox(height: 12 * scale),
            ClipRRect(
              borderRadius: BorderRadius.circular(4 * scale),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: backgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6 * scale,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulse Indicator — self-contained StatefulWidget
// ---------------------------------------------------------------------------

class _PulseIndicator extends StatefulWidget {
  final bool isOnline;
  final double scale;

  const _PulseIndicator({required this.isOnline, required this.scale});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isOnline) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseIndicator old) {
    super.didUpdateWidget(old);
    if (widget.isOnline && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isOnline && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double s = widget.scale;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double pulseScale =
            widget.isOnline ? 1.0 + (_controller.value * 0.5) : 1.0;
        final double opacity =
            widget.isOnline ? 1.0 - _controller.value : 1.0;

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isOnline)
              Transform.scale(
                scale: pulseScale,
                child: Container(
                  width: 16 * s,
                  height: 16 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: opacity * 0.5),
                  ),
                ),
              ),
            Container(
              width: 12 * s,
              height: 12 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isOnline ? AppColors.success : AppColors.error,
                border: Border.all(color: AppColors.popover, width: 2 * s),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Continue Learning Section
// ---------------------------------------------------------------------------

class _ContinueLearningSection extends StatelessWidget {
  final String lastLessonTitle;
  final String lastModuleName;
  final double lastLessonProgress;
  final VoidCallback onPressed;

  const _ContinueLearningSection({
    required this.lastLessonTitle,
    required this.lastModuleName,
    required this.lastLessonProgress,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(40),
        topRight: Radius.circular(40),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        splashColor: AppColors.primaryForeground.withValues(alpha: 0.08),
        highlightColor: AppColors.primaryForeground.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg + AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continue where you left off',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.primaryForeground.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lastLessonTitle,
                          style: AppTextStyles.h3
                              .copyWith(color: AppColors.primaryForeground),
                        ),
                        if (lastModuleName.isNotEmpty)
                          Text(
                            lastModuleName,
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.primaryForeground
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.primaryForeground,
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: LinearProgressIndicator(
                  value: lastLessonProgress,
                  backgroundColor:
                      AppColors.primaryForeground.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryForeground),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skill Map Section
// ---------------------------------------------------------------------------

class _SkillMapSection extends StatelessWidget {
  final List<SkillResult> skillResults;

  const _SkillMapSection({required this.skillResults});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(AppSpacing.lg + AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Skill Map', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.lg),
          _SkillMapGrid(skillResults: skillResults),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skill Map Grid
// ---------------------------------------------------------------------------

class _SkillMapGrid extends StatelessWidget {
  final List<SkillResult> skillResults;

  const _SkillMapGrid({required this.skillResults});

  static const _skillMeta = {
    SkillCategory.sequencing: {
      'name': 'Sequencing',
      'icon': Icons.swap_vert_rounded,
    },
    SkillCategory.logicFlow: {
      'name': 'Logic Flow',
      'icon': Icons.account_tree_rounded,
    },
    SkillCategory.debugging: {
      'name': 'Debugging',
      'icon': Icons.bug_report_rounded,
    },
    SkillCategory.syntax: {
      'name': 'Syntax',
      'icon': Icons.code_rounded,
    },
    SkillCategory.computationalThinking: {
      'name': 'Comp. Thinking',
      'icon': Icons.psychology_rounded,
    },
  };

  Color _levelColor(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:
        return AppColors.success;
      case SkillLevel.building:
        return AppColors.primary;
      case SkillLevel.developing:
        return AppColors.warning;
    }
  }

  String _levelLabel(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:
        return 'Confident';
      case SkillLevel.building:
        return 'Building';
      case SkillLevel.developing:
        return 'Developing';
    }
  }

  Color _levelBg(SkillLevel level) {
    switch (level) {
      case SkillLevel.confident:
        return AppColors.successLight;
      case SkillLevel.building:
        return AppColors.primaryLight;
      case SkillLevel.developing:
        return AppColors.warningLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.sm + AppSpacing.xs,
      mainAxisSpacing: AppSpacing.sm + AppSpacing.xs,
      childAspectRatio: 1.4,
      children: skillResults.map((result) {
        final meta =
            _skillMeta[result.skill] ?? {'name': 'Skill', 'icon': Icons.star};
        return _buildCard(result, meta);
      }).toList(),
    );
  }

  Widget _buildCard(SkillResult result, Map<String, dynamic> meta) {
    final color = _levelColor(result.level);
    final label = _levelLabel(result.level);
    final bg = _levelBg(result.level);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(meta['icon'] as IconData, size: 20, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: color),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(meta['name'] as String, style: AppTextStyles.labelSm),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: result.barFraction,
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
