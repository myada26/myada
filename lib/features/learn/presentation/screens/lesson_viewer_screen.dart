import 'package:flutter/material.dart';

class LessonViewerScreen extends StatelessWidget {
  final String moduleId;
  const LessonViewerScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson Viewer')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Complete Lesson'),
        )
      )
    );
  }
}
