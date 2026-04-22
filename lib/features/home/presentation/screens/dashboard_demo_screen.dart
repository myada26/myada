import 'package:flutter/material.dart';
import '../widgets/home_dashboard.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../core/theme/app_colors.dart';

class DashboardDemoScreen extends StatelessWidget {
  const DashboardDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Skill Results
    final mockSkills = [
      const SkillResult(skill: SkillCategory.sequencing, level: SkillLevel.confident, rawScore: 2.8, wasSkipped: false),
      const SkillResult(skill: SkillCategory.logicFlow, level: SkillLevel.building, rawScore: 1.5, wasSkipped: false),
      const SkillResult(skill: SkillCategory.debugging, level: SkillLevel.developing, rawScore: 0.8, wasSkipped: false),
      const SkillResult(skill: SkillCategory.syntax, level: SkillLevel.confident, rawScore: 3.0, wasSkipped: false),
      const SkillResult(skill: SkillCategory.computationalThinking, level: SkillLevel.building, rawScore: 1.2, wasSkipped: false),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home Dashboard Demo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.foreground,
      ),
      body: HomeDashboard(
        moduleProgress: 0.64,
        currentModuleName: 'Module 3 · Functions',
        studentRank: 4,
        pointsBehind: 12,
        bestSkill: 'Syntax',
        weakestSkill: 'Logic flow',
        userInitials: 'EL',
        isOnline: true,
        lastLessonTitle: 'Advanced Closures',
        lastModuleName: 'Functional Programming',
        lastLessonProgress: 0.75,
        onContinuePressed: () {
          debugPrint('Continue Learning Pressed!');
        },
        skillResults: mockSkills,
        // userAvatarUrl: 'https://i.pravatar.cc/300',
      ),
    );
  }
}
