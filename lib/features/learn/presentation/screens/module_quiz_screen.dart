// lib/features/learn/presentation/screens/module_quiz_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/parsons_question_widget.dart';
import '../../../learn/data/services/module_unlock_service.dart';

class ModuleQuizScreen extends StatefulWidget {
  final String moduleId;
  final String learnerId;
  final List<Map<String, dynamic>> questions;
  final bool isFirstAttempt;
  final bool hasStreak;
  final bool isRetryQuiz;
  final String nextModuleId; // e.g. "module_02" — passed on to QuizResultScreen

  const ModuleQuizScreen({
    super.key,
    required this.moduleId,
    required this.learnerId,
    required this.questions,
    required this.isFirstAttempt,
    required this.hasStreak,
    this.isRetryQuiz = false,
    this.nextModuleId = '',
  });

  @override
  State<ModuleQuizScreen> createState() => _ModuleQuizScreenState();
}

class _ModuleQuizScreenState extends State<ModuleQuizScreen> {
  int _currentIndex = 0;
  final List<int> _pointsPerQuestion = [];
  int _timeElapsed = 0;
  late int _timeLimit;
  Timer? _timer;
  bool _showFeedback = false;
  String? _selectedAnswer;

  // ── Parsons state ──────────────────────────────────────────────────────────
  // ── Fill blank state ───────────────────────────────────────────────────────
  final TextEditingController _fillBlankCtrl = TextEditingController();
  bool _fillBlankSubmitted = false;

  @override
  void initState() {
    super.initState();
    _timeLimit = widget.isRetryQuiz
        ? ScoringConstants.retryQuizMinutes * 60
        : ScoringConstants.moduleQuizMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeElapsed >= _timeLimit) {
        _submitQuiz();
      } else {
        setState(() => _timeElapsed++);
      }
    });
    _initCurrentQuestion();
  }

  void _initCurrentQuestion() {
    final q = widget.questions[_currentIndex];
    final type = _getQuestionType(q);

    if (_isFillBlank(type)) {
      _fillBlankCtrl.clear();
      _fillBlankSubmitted = false;
    }
  }

  Map<String, dynamic> _getContent(Map<String, dynamic> q) {
    if (q.containsKey('content_json') && q['content_json'] is String) {
      return jsonDecode(q['content_json'] as String) as Map<String, dynamic>;
    }
    if (q.containsKey('content') && q['content'] is Map) {
      return Map<String, dynamic>.from(q['content'] as Map);
    }
    return {};
  }

  // ── Answer submission ──────────────────────────────────────────────────────

  String _getQuestionType(Map<String, dynamic> q) {
    return (q['question_type'] ?? q['type'] ?? 'multiple_choice').toString();
  }

  bool _isFillBlank(String type) {
    return type == 'fill_blank' || type == 'fill_in_blank';
  }

  void _submitAnswer(String answer) {
    if (_showFeedback) return;

    final q = widget.questions[_currentIndex];
    final correctAnswer = q['correct_answer']?.toString() ?? '';
    final isCorrect =
        _normaliseAnswer(answer) == _normaliseAnswer(correctAnswer);
    final pts = ScoringEngine.calcQuestionPoints(
      questionType: _getQuestionType(q),
      isCorrect: isCorrect,
    );
    _pointsPerQuestion.add(pts);
    setState(() {
      _showFeedback = true;
      _selectedAnswer = answer;
    });
  }

  void _submitFillBlank() {
    final answer = _fillBlankCtrl.text.trim();
    if (answer.isEmpty) return;
    _submitAnswer(answer);
    setState(() => _fillBlankSubmitted = true);
  }

  String _normaliseAnswer(String answer) {
    final trimmed = answer.toLowerCase().trim();
    if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
      try {
        final decoded = jsonDecode(trimmed) as List<dynamic>;
        return jsonEncode(decoded.map((e) => int.parse(e.toString())).toList());
      } catch (_) {
        return trimmed.replaceAll(RegExp(r'\s+'), '');
      }
    }
    if (RegExp(r'^\d+(,\d+)*$').hasMatch(trimmed)) {
      return jsonEncode(trimmed.split(',').map(int.parse).toList());
    }
    return trimmed;
  }

  void _skipQuestion() {
    _pointsPerQuestion.add(0);
    _advance();
  }

  void _advance() {
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
      _fillBlankSubmitted = false;
    });
    if (_currentIndex + 1 >= widget.questions.length) {
      _submitQuiz();
    } else {
      setState(() => _currentIndex++);
      _initCurrentQuestion();
    }
  }

  Future<void> _submitQuiz() async {
    _timer?.cancel();
    while (_pointsPerQuestion.length < widget.questions.length) {
      _pointsPerQuestion.add(0);
    }
    final result = ScoringEngine.calcSessionResult(
      pointsPerQuestion: _pointsPerQuestion,
      totalQuestions: widget.questions.length,
      timeUsedSeconds: _timeElapsed,
      timeLimitSeconds: _timeLimit,
      isFirstAttempt: widget.isFirstAttempt,
      hasStreak: widget.hasStreak,
      attemptType: widget.isRetryQuiz ? 'retry_quiz' : 'module_quiz',
    );

    // Persist attempt
    await ModuleUnlockService.instance.saveQuizAttempt(
      moduleId: widget.moduleId,
      passed: result.passed,
      totalScore: result.totalScore,
      timeUsedSeconds: _timeElapsed,
      accuracyPct: result.accuracyPct,
      skillLevelAchieved: result.skillLevelAchieved,
      attemptType: widget.isRetryQuiz ? 'retry_quiz' : 'module_quiz',
      timeLimitSeconds: _timeLimit,
      accuracyScore: result.accuracyScore,
      timeBonus: result.timeBonus,
      firstAttemptBonus: result.firstAttemptBonus,
      streakBonus: result.streakBonus,
    );

    // Unlock exam if quiz was passed
    if (result.passed) {
      await ModuleUnlockService.instance.unlockExam(widget.moduleId);
    }

    if (!mounted) return;
    final correctCount = _pointsPerQuestion.where((p) => p > 0).length;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizResultDialog(
        result: result,
        correctCount: correctCount,
        totalCount: widget.questions.length,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop(); // return to learn screen
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fillBlankCtrl.dispose();
    super.dispose();
  }

  // ── Question widgets ───────────────────────────────────────────────────────

  Widget _buildQuestionWidget(String type, Map<String, dynamic> content) {
    switch (type) {
      case 'multiple_choice':
        return _buildMultipleChoice(content);
      case 'parsons':
        return _buildParsons(content);
      case 'fill_in_blank':
      case 'fill_blank':
        return _buildFillBlank(content);
      default:
        // Graceful fallback — treat unknown types as fill_blank
        return _buildFillBlank(content);
    }
  }

  // ── Multiple Choice ────────────────────────────────────────────────────────

  Widget _buildMultipleChoice(Map<String, dynamic> content) {
    final options = (content['options'] as List?)?.cast<String>() ?? [];
    return Column(
      children: options.asMap().entries.map((e) {
        final idx = e.key.toString();
        final isSelected = _selectedAnswer == idx;
        final q = widget.questions[_currentIndex];
        final correctIdx = q['correct_answer']?.toString() ?? '';
        Color? bg;
        if (_showFeedback) {
          if (idx == correctIdx) {
            bg = AppColors.success.withAlpha(40);
          } else if (isSelected && idx != correctIdx) {
            bg = AppColors.error.withAlpha(40);
          }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  bg ?? (isSelected ? AppColors.primary.withAlpha(30) : null),
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onPressed: _showFeedback ? null : () => _submitAnswer(idx),
            child: Align(alignment: Alignment.centerLeft, child: Text(e.value)),
          ),
        );
      }).toList(),
    );
  }

  // ── Parsons (drag-and-drop) ────────────────────────────────────────────────

  Widget _buildParsons(Map<String, dynamic> content) {
    final lines = (content['lines'] as List<dynamic>? ?? [])
        .map((line) => line.toString())
        .toList();

    if (lines.isEmpty) {
      return Text(
        'This question is missing code lines.',
        style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
      );
    }

    return ParsonsQuestionWidget(
      key: ValueKey('module_parsons_$_currentIndex'),
      lines: lines,
      enabled: !_showFeedback,
      onOrderChanged: (_, answer) => _submitAnswer(answer),
    );
  }

  // ── Fill Blank ─────────────────────────────────────────────────────────────

  Widget _buildFillBlank(Map<String, dynamic> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your answer:',
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _fillBlankCtrl,
          enabled: !_fillBlankSubmitted,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
          decoration: InputDecoration(
            hintText: 'e.g. print',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
          ),
          onSubmitted: _fillBlankSubmitted ? null : (_) => _submitFillBlank(),
        ),
        const SizedBox(height: 12),
        if (!_fillBlankSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitFillBlank,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Submit answer'),
            ),
          ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final remaining = _timeLimit - _timeElapsed;
    final q = widget.questions[_currentIndex];
    final type = _getQuestionType(q);
    final content = _getContent(q);
    final isLast = _currentIndex + 1 >= widget.questions.length;
    final timeDanger = remaining <= 30;
    final selectedIsCorrect =
        _selectedAnswer != null &&
        _normaliseAnswer(_selectedAnswer!) ==
            _normaliseAnswer(q['correct_answer']?.toString() ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_currentIndex + 1} of ${widget.questions.length}',
              style: AppTextStyles.label,
            ),
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: timeDanger
                      ? AppColors.error.withAlpha(30)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                  style: AppTextStyles.label.copyWith(
                    color: timeDanger ? AppColors.error : AppColors.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question type chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _typeLabel(type),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Prompt
            Text(
              q['prompt_text'] as String? ?? '',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: 20),

            // Question widget
            _buildQuestionWidget(type, content),

            const SizedBox(height: 24),

            // Feedback card
            if (_showFeedback) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedIsCorrect
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      selectedIsCorrect
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: selectedIsCorrect
                          ? AppColors.success
                          : AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        q['explanation'] as String? ?? '',
                        style: AppTextStyles.bodySm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _advance,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text(isLast ? 'See results' : 'Next question'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _skipQuestion,
                child: const Text('Skip question'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'parsons':
        return 'Order the Code';
      case 'fill_blank':
        return 'Fill in the Blank';
      case 'coding':
        return 'Coding';
      default:
        return 'Question';
    }
  }
}

// ── Quiz Result Dialog ────────────────────────────────────────────────────────

class _QuizResultDialog extends StatelessWidget {
  final QuizSessionResult result;
  final int correctCount;
  final int totalCount;

  const _QuizResultDialog({
    required this.result,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final passed = result.passed;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              passed ? Icons.emoji_events_rounded : Icons.replay_rounded,
              size: 48,
              color: passed ? AppColors.primary : AppColors.accent,
            ),
            const SizedBox(height: 12),
            Text(
              passed ? 'Mini-Quiz Completed!' : 'Keep Practicing!',
              style: AppTextStyles.h3.copyWith(color: AppColors.foreground),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _ResultRow(
              label: 'Points earned',
              value: '${result.totalScore} pts',
            ),
            _ResultRow(
              label: 'Correct answers',
              value: '$correctCount / $totalCount',
            ),
            if (result.timeBonus > 0)
              _ResultRow(
                label: 'Speed bonus',
                value: '+${result.timeBonus} pts',
              ),
            if (result.firstAttemptBonus > 0)
              _ResultRow(
                label: 'First attempt bonus',
                value: '+${result.firstAttemptBonus} pts',
              ),
            if (result.streakBonus > 0)
              _ResultRow(
                label: 'Streak bonus',
                value: '+${result.streakBonus} pts',
              ),
            const Divider(height: 24),
            _ResultRow(
              label: 'Total XP gained',
              value: '${result.totalScore} XP',
              bold: true,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed
                      ? AppColors.primary
                      : AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  passed ? 'Back to Learning Path' : 'Try Again',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _ResultRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color ?? AppColors.foreground,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
