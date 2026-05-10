// lib/features/progress/presentation/screens/progress_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../components/navigation/global_stat_bar.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../models/learning_path_model.dart';
import '../../../learn/data/services/module_unlock_service.dart';
import '../../../learn/data/services/progress_service.dart';
import '../../../learn/presentation/screens/module_quiz_screen.dart';
import '../../data/services/challenge_service.dart';

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
  final IconData icon;

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
    required this.icon,
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
  final String sectionLabel;
  final String title;
  final String subtitle;
  final double readinessPercent;
  final String ctaLabel;

  const _NextExamData({
    required this.sectionLabel,
    required this.title,
    required this.subtitle,
    required this.readinessPercent,
    required this.ctaLabel,
  });
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  bool _isLoading = true;
  int _activeCount = 0;
  int _retakeCount = 0;
  int _points = 0;
  List<ChallengeModel> _activeChallenges = [];
  List<RetakeItem> _retakes = [];
  _NextExamData? _nextExam;
  String _pathSignature = '';
  List<LearningModule> _unlockedExams = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final learningPath =
        context.watch<LearningPathController>().result?.learningPath ??
        const [];
    final signature = learningPath.map((m) => m.moduleId).join('|');
    if (_pathSignature != signature) {
      _pathSignature = signature;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
    }
  }

  Future<void> _loadData() async {
    final pathCtrl = context.read<LearningPathController>();
    final learningPath =
        pathCtrl.result?.learningPath ?? const <LearningModule>[];
    final preferredTags = _preferredSkillTags(learningPath);

    setState(() => _isLoading = true);

    await PointsService.instance.loadTotal();
    final activeChallenges = await ChallengeService.instance
        .getAvailableChallenges(preferredSkillTags: preferredTags);
    final retakes = await ChallengeService.instance.getRetakeSuggestions();
    final nextExam = await _buildNextExamData(learningPath);

    // Find modules with unlocked exams
    final unlockedExams = <LearningModule>[];
    for (final module in learningPath) {
      if (await ModuleUnlockService.instance.isExamUnlocked(module.moduleId)) {
        unlockedExams.add(module);
      }
    }

    if (!mounted) return;
    setState(() {
      _points = PointsService.instance.totalPoints;
      _activeChallenges = activeChallenges;
      _retakes = retakes;
      _activeCount = activeChallenges.length;
      _retakeCount = retakes.length;
      _nextExam = nextExam;
      _unlockedExams = unlockedExams;
      _isLoading = false;
    });
  }

  Set<String> _preferredSkillTags(List<LearningModule> learningPath) {
    LearningModule? activeModule;
    for (final module in learningPath) {
      if (module.isStartHere) {
        activeModule = module;
        break;
      }
    }
    if (activeModule == null) return const {};
    return {_skillTagFor(activeModule.skill)};
  }

  String _skillTagFor(SkillCategory skill) => switch (skill) {
    SkillCategory.sequencing => 'sequencing',
    SkillCategory.logicFlow => 'logic_flow',
    SkillCategory.debugging => 'debugging',
    SkillCategory.syntax => 'syntax',
    SkillCategory.computationalThinking => 'computational_thinking',
  };

  Future<_NextExamData> _buildNextExamData(
    List<LearningModule> learningPath,
  ) async {
    if (learningPath.isEmpty) {
      return const _NextExamData(
        sectionLabel: 'No path yet',
        title: 'Diagnostic needed',
        subtitle: 'Finish the diagnostic to unlock your first module exam.',
        readinessPercent: 0,
        ctaLabel: 'Start diagnostic',
      );
    }

    LearningModule? target;
    for (final module in learningPath) {
      final unlocked = await ModuleUnlockService.instance.isModuleUnlocked(
        module.moduleId,
      );
      final passed = await _isModulePassed(module.moduleId);
      if (unlocked && !passed) {
        target = module;
        break;
      }
    }

    for (final module in learningPath) {
      if (target != null) break;
      final passed = await _isModulePassed(module.moduleId);
      if (!passed) {
        target = module;
        break;
      }
    }

    if (target == null) {
      return const _NextExamData(
        sectionLabel: 'Completed',
        title: 'All module exams complete',
        subtitle: 'You are caught up. Review any module whenever you want.',
        readinessPercent: 1,
        ctaLabel: 'Review modules',
      );
    }

    final completedLessons = await ProgressService.instance
        .getCompletedLessonCount(target.moduleId);
    final lessonGoal = target.estimatedLessons == 0
        ? 1
        : target.estimatedLessons;
    final readiness = (completedLessons / lessonGoal).clamp(0.0, 1.0);
    final lessonsRemaining = (lessonGoal - completedLessons).clamp(
      0,
      lessonGoal,
    );
    final examReady = lessonsRemaining == 0;

    return _NextExamData(
      sectionLabel: 'Module ${target.number}',
      title: 'Module ${target.number} Exam',
      subtitle: examReady
          ? '${target.name} is ready whenever you are.'
          : 'Finish $lessonsRemaining more lesson${lessonsRemaining == 1 ? '' : 's'} in ${target.name} to unlock this exam.',
      readinessPercent: readiness,
      ctaLabel: examReady ? 'Take exam' : 'Continue module',
    );
  }

  Future<bool> _isModulePassed(String moduleId) async {
    return ModuleUnlockService.instance.isQuizPassed(moduleId);
  }

  Future<void> _openExam(BuildContext context, LearningModule module) async {
    final moduleId   = module.moduleId;
    final folderName = moduleId.replaceAll('_', '');
    List<Map<String, dynamic>> questions = [];

    try {
      final raw = await rootBundle
          .loadString('assets/content/modules/$folderName/exam.json');
      final decoded    = jsonDecode(raw) as Map<String, dynamic>;
      final rawQuestions = decoded['questions'] as List<dynamic>? ?? [];
      questions = rawQuestions.map<Map<String, dynamic>>((q) {
        final m = Map<String, dynamic>.from(q as Map);
        return {
          'id':            m['id'] ?? '',
          'prompt_text':   m['prompt'] ?? m['prompt_text'] ?? '',
          'question_type': m['type'] ?? m['question_type'] ?? 'multiple_choice',
          'content':       m,
          'correct_answer': m['correct_index']?.toString() ?? m['answer'] ?? '',
          'explanation':   m['explanation'] ?? '',
        };
      }).toList();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load exam: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleQuizScreen(
          moduleId:       moduleId,
          learnerId:      ModuleUnlockService.instance.currentUserId,
          questions:      questions,
          isFirstAttempt: true,
          hasStreak:      false,
          isRetryQuiz:    false,
          nextModuleId:   '',
        ),
      ),
    );
  }

  List<_ChallengeData> get _challengeCards => _activeChallenges.map((
    challenge,
  ) {
    final isTimed = challenge.isTimed;
    final accentColor = isTimed ? AppColors.success : AppColors.primary;
    final iconColor = isTimed ? AppColors.success : AppColors.primary;
    final iconBg = isTimed ? AppColors.successLight : AppColors.primaryLight;
    final status = isTimed ? 'Timed' : 'Practice';

    return _ChallengeData(
      title: challenge.title,
      subtitle: isTimed
          ? '${challenge.description.split('.').first} • ${challenge.timeLimitSeconds ~/ 60} min'
          : challenge.description.split('.').first,
      progress: 0,
      status: status,
      accentColor: accentColor,
      iconBg: iconBg,
      iconFg: iconColor,
      pillBg: iconBg,
      pillFg: iconColor,
      pointsLabel: '+${challenge.pointsReward} pts',
      icon: isTimed ? Icons.timer_rounded : Icons.psychology_alt_rounded,
    );
  }).toList();

  List<_RetakeData> get _retakeCards => _retakes
      .map(
        (item) => _RetakeData(
          title: item.moduleTitle,
          score: '${item.lastScore.round()}%',
          scoreColor: AppColors.error,
          reason:
              'Latest quiz attempt is below passing. Retake it when you are ready.',
          buttonLabel: 'Retake quiz',
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _ChallengeHeader()),
            SliverToBoxAdapter(
              child: _StatsRow(
                activeCount: _activeCount,
                retakeCount: _retakeCount,
                points: _points,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(
                    title: 'Active challenges',
                    count: '$_activeCount available',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_challengeCards.isEmpty)
                    const _EmptyStateCard(
                      title: 'No active challenges yet',
                      subtitle:
                          'Complete lessons and quizzes to unlock practice challenges here.',
                    )
                  else
                    ..._challengeCards.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ChallengeCard(data: data),
                      ),
                    ),
                  const _HorizontalDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    title: 'Retake suggestions',
                    count:
                        '$_retakeCount module${_retakeCount == 1 ? '' : 's'}',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_retakeCards.isEmpty)
                    const _EmptyStateCard(
                      title: 'No retakes needed right now!',
                      subtitle:
                          'When a module quiz needs another try, it will show up here.',
                    )
                  else
                    ..._retakeCards.map(
                      (data) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RetakeCard(data: data),
                      ),
                    ),
                  const _HorizontalDivider(),
                  const SizedBox(height: AppSpacing.md),
                  _SectionHeader(
                    title: 'Next exam',
                    count: _nextExam?.sectionLabel ?? 'Loading',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_nextExam != null)
                    _NextExamCard(data: _nextExam!)
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_unlockedExams.isNotEmpty) ...[
                    const _HorizontalDivider(),
                    const SizedBox(height: AppSpacing.md),
                    _SectionHeader(
                      title: 'Module exams',
                      count: '${_unlockedExams.length} unlocked',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ..._unlockedExams.map(
                      (module) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _ModuleExamCard(
                          module: module,
                          onTap: () => _openExam(context, module),
                        ),
                      ),
                    ),
                  ],
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
          const GlobalStatBar(),
          const SizedBox(height: AppSpacing.md),
          Text('Challenges', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Track live practice opportunities and your next module exam.',
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int activeCount;
  final int retakeCount;
  final int points;

  const _StatsRow({
    required this.activeCount,
    required this.retakeCount,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _SolidStatCard(
              icon: Icons.check_circle_rounded,
              label: 'Active',
              value: '$activeCount',
              subLabel: 'available',
              backgroundColor: AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SolidStatCard(
              icon: Icons.replay_rounded,
              label: 'Retakes',
              value: '$retakeCount',
              subLabel: 'eligible',
              backgroundColor: AppColors.error,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SolidStatCard(
              icon: Icons.star_rounded,
              label: 'Points',
              value: '$points',
              subLabel: 'earned',
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subLabel;
  final Color backgroundColor;

  const _SolidStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subLabel,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withAlpha(210),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subLabel,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withAlpha(160),
            ),
          ),
        ],
      ),
    );
  }
}

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
            child: Icon(data.icon, color: data.iconFg, size: 20),
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
                _ProgressBar(value: data.progress, color: data.accentColor),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusPill(label: data.status, bg: data.pillBg, fg: data.pillFg),
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
            data.sectionLabel.toUpperCase(),
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

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.popover,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _ModuleExamCard extends StatelessWidget {
  final LearningModule module;
  final VoidCallback onTap;

  const _ModuleExamCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Module ${module.number} Exam',
                  style: AppTextStyles.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  module.name,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              textStyle: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
            child: const Text('Take Exam'),
          ),
        ],
      ),
    );
  }
}
