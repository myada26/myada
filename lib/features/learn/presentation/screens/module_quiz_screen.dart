import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';
import 'quiz_result_screen.dart';

class ModuleQuizScreen extends StatefulWidget {
  final String moduleId;
  final String learnerId;
  final List<Map<String, dynamic>> questions;
  final bool isFirstAttempt;
  final bool hasStreak;
  final bool isRetryQuiz;

  const ModuleQuizScreen({
    super.key,
    required this.moduleId,
    required this.learnerId,
    required this.questions,
    required this.isFirstAttempt,
    required this.hasStreak,
    this.isRetryQuiz = false,
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
  }

  void _submitAnswer(String answer) {
    final q = widget.questions[_currentIndex];
    final isCorrect = answer == q['correct_answer'];
    final pts = ScoringEngine.calcQuestionPoints(
      questionType: q['question_type'] as String,
      isCorrect: isCorrect,
    );
    _pointsPerQuestion.add(pts);
    setState(() {
      _showFeedback = true;
      _selectedAnswer = answer;
    });
  }

  void _skipQuestion() {
    _pointsPerQuestion.add(0);
    _advance();
  }

  void _advance() {
    setState(() {
      _showFeedback = false;
      _selectedAnswer = null;
    });
    if (_currentIndex + 1 >= widget.questions.length) {
      _submitQuiz();
    } else {
      setState(() => _currentIndex++);
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
          result: result,
          moduleId: widget.moduleId,
          learnerId: widget.learnerId,
          isRetryQuiz: widget.isRetryQuiz,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildQuestionWidget(String type, Map<String, dynamic> content) {
    switch (type) {
      case 'multiple_choice':
        final options = (content['options'] as List).cast<String>();
        return Column(
          children: options.asMap().entries.map((e) {
            final idx = e.key.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: _selectedAnswer == idx
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  minimumSize: const Size(double.infinity, 48),
                ),
                onPressed: _selectedAnswer == null || _showFeedback ? () => _submitAnswer(idx) : null,
                child: Text(e.value, textAlign: TextAlign.start),
              ),
            );
          }).toList(),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8)
          ),
          child: Text('Placeholder for $type widget', style: TextStyle(color: Colors.amber.shade900)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _timeLimit - _timeElapsed;
    final q = widget.questions[_currentIndex];

    // parse content_json if available
    Map<String, dynamic> content = {};
    if (q.containsKey('content_json') && q['content_json'] is String) {
      content = jsonDecode(q['content_json'] as String);
    } else if (q.containsKey('content')) {
      content = q['content'] as Map<String, dynamic>;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('${_currentIndex + 1} / ${widget.questions.length}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: remaining <= 30 ? Colors.redAccent : null,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentIndex + 1) / widget.questions.length,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q['prompt_text'] as String,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  
                  _buildQuestionWidget(q['question_type'] as String, content),

                  const Spacer(),
                  if (_showFeedback) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(q['explanation'] as String? ?? ''),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _advance,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48)),
                      child: _currentIndex + 1 >= widget.questions.length
                          ? const Text('See results')
                          : const Text('Next question'),
                    ),
                  ] else
                    TextButton(
                      onPressed: _skipQuestion,
                      child: const Text('Skip'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
