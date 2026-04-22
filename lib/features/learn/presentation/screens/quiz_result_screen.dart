// lib/features/learn/presentation/screens/quiz_result_screen.dart
import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';
import '../../../../core/engine/badge_engine.dart';
import '../../../../core/engine/badge_definitions.dart';
import '../../../../core/services/points_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/services/module_unlock_service.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizSessionResult result;
  final String moduleId;
  final String learnerId;
  final bool isRetryQuiz;
  final String nextModuleId;
  final int timeUsedSeconds;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.moduleId,
    required this.learnerId,
    required this.isRetryQuiz,
    this.nextModuleId = '',
    this.timeUsedSeconds = 0,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  List<String> _earnedBadgeIds = [];
  int _pointsAwarded = 0;
  bool _scored = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _awardPointsAndBadges());
  }

  Future<void> _awardPointsAndBadges() async {
    if (_scored) return;
    _scored = true;

    // ── Points ──────────────────────────────────────────────────────────────
    final pts = await PointsService.instance.awardQuizPoints(
      scorePct: widget.result.accuracyPct,
      isRetake: widget.isRetryQuiz,
      improved: widget.result.passed,
    );

    int totalAwarded = pts;

    if (!widget.isRetryQuiz && widget.result.passed) {
      // Module completion bonus
      await PointsService.instance.addPoints(
        PointsService.moduleCompleted,
        'module_completed_${widget.moduleId}',
      );
      await PointsService.instance.incrementModulesCompleted();
      totalAwarded += PointsService.moduleCompleted;

      // ── KEY FIX: unlock the next module in sqflite ───────────────────────
      if (widget.nextModuleId.isNotEmpty) {
        await ModuleUnlockService.instance.unlockModule(
          widget.nextModuleId,
          reason: 'quiz_passed',
        );
      }
    }

    // Save quiz attempt record
    await ModuleUnlockService.instance.saveQuizAttempt(
      moduleId:           widget.moduleId,
      passed:             widget.result.passed,
      totalScore:         widget.result.totalScore,
      timeUsedSeconds:    widget.timeUsedSeconds,
      accuracyPct:        widget.result.accuracyPct,
      skillLevelAchieved: widget.result.skillLevelAchieved,
      attemptType:        widget.isRetryQuiz ? 'retry_quiz' : 'module_quiz',
      timeLimitSeconds:   widget.isRetryQuiz
          ? ScoringConstants.retryQuizMinutes * 60
          : ScoringConstants.moduleQuizMinutes * 60,
      accuracyScore:      widget.result.accuracyScore,
      timeBonus:          widget.result.timeBonus,
      firstAttemptBonus:  widget.result.firstAttemptBonus,
      streakBonus:        widget.result.streakBonus,
    );

    // ── Badge checks ────────────────────────────────────────────────────────
    final badges = await BadgeEngine.instance.checkAndAward(
      'quiz_submitted',
      context: {
        'scorePct': widget.result.accuracyPct,
        'isRetake': widget.isRetryQuiz,
        'previouslyFailed': widget.isRetryQuiz,
      },
    );

    if (!widget.isRetryQuiz && widget.result.passed) {
      final moduleBadges = await BadgeEngine.instance.checkAndAward(
        'module_completed',
        context: {
          'modulesCompleted': 1,
          'totalModules': 6,
        },
      );
      badges.addAll(moduleBadges);
    }

    if (mounted) {
      setState(() {
        _pointsAwarded = totalAwarded;
        _earnedBadgeIds = badges;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Result header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: widget.result.passed
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  border: Border.all(
                    color: widget.result.passed
                        ? AppColors.success.withAlpha(60)
                        : AppColors.warning.withAlpha(60),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.result.passed
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      size: 52,
                      color: widget.result.passed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.result.passed
                          ? '🎉 Module Complete!'
                          : 'Not Quite Yet',
                      style: AppTextStyles.h2.copyWith(
                        color: widget.result.passed
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.result.passed
                          ? widget.nextModuleId.isNotEmpty
                              ? 'Excellent! ${_moduleLabel(widget.nextModuleId)} is now unlocked.'
                              : 'You reached ${widget.result.skillLevelAchieved} level!'
                          : widget.isRetryQuiz
                              ? 'Keep practicing — you\'re getting closer!'
                              : 'Score at least 70% to unlock the next module.',
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Score breakdown ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppConstants.radiusLG),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _ScoreRow(
                        'Accuracy',
                        '${widget.result.accuracyScore} pts'),
                    if (!widget.isRetryQuiz) ...[
                      _ScoreRow(
                          'Time bonus', '+${widget.result.timeBonus} pts'),
                      _ScoreRow('First attempt',
                          '+${widget.result.firstAttemptBonus} pts'),
                      _ScoreRow(
                          'Streak bonus', '+${widget.result.streakBonus} pts'),
                    ],
                    const Divider(height: 20),
                    _ScoreRow('Quiz total',
                        '${widget.result.totalScore} pts',
                        bold: true),
                    if (_pointsAwarded > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.xpBackground,
                          borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull),
                          border: Border.all(color: AppColors.xpBorder),
                        ),
                        child: Text(
                          '+$_pointsAwarded leaderboard points earned',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Badge reveals ──────────────────────────────────────────────
              if (_earnedBadgeIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentSubtle,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusLG),
                    border: Border.all(color: AppColors.accentLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events_rounded,
                              color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          Text('Badges Earned!',
                              style: AppTextStyles.label
                                  .copyWith(color: AppColors.accent)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _earnedBadgeIds.map((id) {
                          final badge = BadgeRegistry.getById(id);
                          if (badge == null) return const SizedBox.shrink();
                          return Chip(
                            avatar: Icon(badge.icon,
                                size: 16, color: badge.categoryColor),
                            label: Text(badge.name,
                                style: AppTextStyles.caption),
                            backgroundColor: badge.categoryBgColor,
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // ── CTA button ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleCta(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.result.passed
                        ? AppColors.primary
                        : AppColors.warning,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMD),
                    ),
                  ),
                  child: Text(
                    widget.result.passed
                        ? widget.nextModuleId.isNotEmpty
                            ? 'Continue to ${_moduleLabel(widget.nextModuleId)} →'
                            : 'Back to learning path'
                        : 'Practice & retry',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCta(BuildContext context) {
    // Pop back to the learn or home screen — the LearnScreen
    // will auto-refresh state when it resumes.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String _moduleLabel(String moduleId) {
    // "module_02" → "Module 2"
    final parts = moduleId.split('_');
    if (parts.length < 2) return moduleId;
    final num = int.tryParse(parts.last) ?? 0;
    return 'Module $num';
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ScoreRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: bold ? AppTextStyles.label : AppTextStyles.bodySm),
          Text(value,
              style: bold
                  ? AppTextStyles.label
                  : AppTextStyles.bodySm
                      .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
