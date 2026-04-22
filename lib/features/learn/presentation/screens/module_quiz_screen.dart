// lib/features/learn/presentation/screens/module_quiz_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'quiz_result_screen.dart';

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
  List<Map<String, dynamic>> _parsonsBlocks = [];
  bool _parsonsSubmitted = false;

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
    final type = q['question_type'] as String? ?? 'multiple_choice';

    if (type == 'parsons') {
      final content = _getContent(q);
      final blocks = (content['blocks'] as List<dynamic>? ?? [])
          .map((b) => Map<String, dynamic>.from(b as Map))
          .toList();
      // Shuffle for display
      _parsonsBlocks = List.from(blocks)..shuffle();
      _parsonsSubmitted = false;
    } else if (type == 'fill_blank') {
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

  void _submitAnswer(String answer) {
    final q = widget.questions[_currentIndex];
    final correctAnswer = q['correct_answer']?.toString() ?? '';
    final isCorrect = answer.toLowerCase().trim() ==
        correctAnswer.toLowerCase().trim();
    final pts = ScoringEngine.calcQuestionPoints(
      questionType: q['question_type'] as String? ?? 'multiple_choice',
      isCorrect: isCorrect,
    );
    _pointsPerQuestion.add(pts);
    setState(() {
      _showFeedback = true;
      _selectedAnswer = answer;
    });
  }

  void _submitParsons() {
    final q = widget.questions[_currentIndex];
    final content = _getContent(q);
    final correctOrder = (content['correct_order'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final currentOrder = _parsonsBlocks.map((b) => b['id'].toString()).toList();
    final isCorrect = _listsEqual(currentOrder, correctOrder);
    final pts = ScoringEngine.calcQuestionPoints(
      questionType: 'parsons',
      isCorrect: isCorrect,
    );
    _pointsPerQuestion.add(pts);
    setState(() {
      _parsonsSubmitted = true;
      _showFeedback = true;
      _selectedAnswer = isCorrect ? 'correct' : 'incorrect';
    });
  }

  void _submitFillBlank() {
    final answer = _fillBlankCtrl.text.trim();
    if (answer.isEmpty) return;
    _submitAnswer(answer);
    setState(() => _fillBlankSubmitted = true);
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _skipQuestion() {
    _pointsPerQuestion.add(0);
    _advance();
  }

  void _advance() {
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
      _parsonsSubmitted = false;
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
      totalQuestions:    widget.questions.length,
      timeUsedSeconds:   _timeElapsed,
      timeLimitSeconds:  _timeLimit,
      isFirstAttempt:    widget.isFirstAttempt,
      hasStreak:         widget.hasStreak,
      attemptType:       widget.isRetryQuiz ? 'retry_quiz' : 'module_quiz',
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(
          result:          result,
          moduleId:        widget.moduleId,
          learnerId:       widget.learnerId,
          isRetryQuiz:     widget.isRetryQuiz,
          nextModuleId:    widget.nextModuleId,
          timeUsedSeconds: _timeElapsed,
        ),
      ),
    );
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
              backgroundColor: bg ?? (isSelected
                  ? AppColors.primary.withAlpha(30)
                  : null),
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            onPressed: _showFeedback
                ? null
                : () => _submitAnswer(idx),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(e.value),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Parsons (drag-and-drop) ────────────────────────────────────────────────

  Widget _buildParsons(Map<String, dynamic> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Drag the blocks into the correct order:',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 12),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _parsonsSubmitted
              ? (_, __) {}
              : (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _parsonsBlocks.removeAt(oldIndex);
                    _parsonsBlocks.insert(newIndex, item);
                  });
                },
          children: _parsonsBlocks.map((block) {
            final blockId = block['id'].toString();
            return Container(
              key: ValueKey(blockId),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _parsonsSubmitted
                      ? AppColors.border
                      : AppColors.primary.withAlpha(80),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle_rounded,
                      color: AppColors.mutedForeground, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      block['code']?.toString() ?? blockId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (!_parsonsSubmitted)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitParsons,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Lock in answer'),
            ),
          ),
      ],
    );
  }

  // ── Fill Blank ─────────────────────────────────────────────────────────────

  Widget _buildFillBlank(Map<String, dynamic> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type your answer:',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.mutedForeground),
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
    final type = q['question_type'] as String? ?? 'multiple_choice';
    final content = _getContent(q);
    final isLast = _currentIndex + 1 >= widget.questions.length;
    final timeDanger = remaining <= 30;

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
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  color: (_selectedAnswer == 'correct' ||
                          _selectedAnswer ==
                              (q['correct_answer']?.toString() ?? ''))
                      ? AppColors.successLight
                      : AppColors.warningLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (_selectedAnswer == 'correct' ||
                              _selectedAnswer ==
                                  (q['correct_answer']?.toString() ?? ''))
                          ? Icons.check_circle_rounded
                          : Icons.info_rounded,
                      color: (_selectedAnswer == 'correct' ||
                              _selectedAnswer ==
                                  (q['correct_answer']?.toString() ?? ''))
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
                      minimumSize: const Size(double.infinity, 52)),
                  child: Text(isLast ? 'See results' : 'Next question'),
                ),
              ),
            ] else if (type == 'multiple_choice' || _parsonsSubmitted || _fillBlankSubmitted)
              const SizedBox.shrink()
            else ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _skipQuestion,
                child: const Text('Skip'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'multiple_choice': return 'Multiple Choice';
      case 'parsons':         return 'Order the Code';
      case 'fill_blank':      return 'Fill in the Blank';
      case 'coding':          return 'Coding';
      default:                return 'Question';
    }
  }
}
