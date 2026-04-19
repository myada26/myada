import 'package:flutter/material.dart';
import '../../../../core/engine/scoring_engine.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizSessionResult result;
  final String moduleId;
  final String learnerId;
  final bool isRetryQuiz;

  const QuizResultScreen({
    super.key,
    required this.result,
    required this.moduleId,
    required this.learnerId,
    required this.isRetryQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.passed ? 'Module complete' : 'Not quite yet',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                result.passed
                    ? 'You reached ${result.skillLevelAchieved} level.'
                    : isRetryQuiz
                        ? 'Review the lessons and try again.'
                        : 'A short practice quiz will help you get there.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _ScoreRow('Accuracy score', '${result.accuracyScore} pts'),
              if (!isRetryQuiz) ...[
                _ScoreRow('Time bonus', '+${result.timeBonus} pts'),
                _ScoreRow('First attempt bonus', '+${result.firstAttemptBonus} pts'),
                _ScoreRow('Streak bonus', '+${result.streakBonus} pts'),
              ],
              const Divider(height: 32),
              _ScoreRow('Total', '${result.totalScore} pts',
                  bold: true),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(
                    context, ModalRoute.withName('/home')),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52)),
                child: const Text('Back to learning path'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _ScoreRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
