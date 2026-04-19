import 'package:flutter/material.dart';
import 'module_quiz_screen.dart';

class RetryQuizScreen extends StatelessWidget {
  final String moduleId;
  final String learnerId;
  final List<Map<String, dynamic>> questions;
  
  const RetryQuizScreen({
    super.key,
    required this.moduleId,
    required this.learnerId,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retry Quiz')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ModuleQuizScreen(
                  moduleId: moduleId,
                  learnerId: learnerId,
                  questions: questions,
                  isFirstAttempt: false,
                  hasStreak: false,
                  isRetryQuiz: true
                )
              )
            );
          },
          child: const Text('Start Retry'),
        )
      )
    );
  }
}
