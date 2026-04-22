// lib/core/engine/badge_definitions.dart
//
// Pure data registry of all 15 badges from the plan.
// No business logic here — just the definitions that BadgeEngine reads.

import 'package:flutter/material.dart';

enum BadgeCategory { beginner, streak, quiz, coding, progress }
enum BadgeTrigger { milestone, count, quality }

class BadgeDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeCategory category;
  final BadgeTrigger trigger;
  final bool isRare;
  /// For count-based badges, the target count to earn it.
  final int? targetCount;
  /// Event types that should trigger a check for this badge.
  final List<String> relevantEvents;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.trigger,
    this.isRare = false,
    this.targetCount,
    required this.relevantEvents,
  });

  Color get categoryColor {
    switch (category) {
      case BadgeCategory.beginner: return const Color(0xFF1D9E75);
      case BadgeCategory.streak:  return const Color(0xFFEF9F27);
      case BadgeCategory.quiz:    return const Color(0xFF6C63FF);
      case BadgeCategory.coding:  return const Color(0xFF1E3A8A);
      case BadgeCategory.progress: return const Color(0xFF4CAF50);
    }
  }

  Color get categoryBgColor {
    switch (category) {
      case BadgeCategory.beginner: return const Color(0xFFE1F5EE);
      case BadgeCategory.streak:  return const Color(0xFFFAEEDA);
      case BadgeCategory.quiz:    return const Color(0xFFEEEDFE);
      case BadgeCategory.coding:  return const Color(0xFFE6F1FB);
      case BadgeCategory.progress: return const Color(0xFFEAF3DE);
    }
  }

  String get categoryLabel {
    switch (category) {
      case BadgeCategory.beginner: return 'Beginner';
      case BadgeCategory.streak:  return 'Streak';
      case BadgeCategory.quiz:    return 'Quiz';
      case BadgeCategory.coding:  return 'Coding';
      case BadgeCategory.progress: return 'Progress';
    }
  }
}

/// Master list of all badges in the system.
class BadgeRegistry {
  BadgeRegistry._();

  static const List<BadgeDef> all = [
    // ── Category 1: Getting Started ───────────────────────────────────────────
    BadgeDef(
      id: 'first_step',
      name: 'First Step',
      description: 'Complete the diagnostic assessment for the first time.',
      icon: Icons.directions_walk_rounded,
      category: BadgeCategory.beginner,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['diagnostic_completed'],
    ),
    BadgeDef(
      id: 'path_found',
      name: 'Path Found',
      description: 'Your personalized learning path has been generated.',
      icon: Icons.explore_rounded,
      category: BadgeCategory.beginner,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['learning_path_generated'],
    ),

    // ── Category 2: Consistency & Streaks ─────────────────────────────────────
    BadgeDef(
      id: 'showing_up',
      name: 'Showing Up',
      description: 'Log in on 3 consecutive days.',
      icon: Icons.calendar_today_rounded,
      category: BadgeCategory.streak,
      trigger: BadgeTrigger.count,
      targetCount: 3,
      relevantEvents: ['daily_checkin'],
    ),
    BadgeDef(
      id: 'week_warrior',
      name: 'Week Warrior',
      description: 'Log in on 7 consecutive days.',
      icon: Icons.local_fire_department_rounded,
      category: BadgeCategory.streak,
      trigger: BadgeTrigger.count,
      targetCount: 7,
      relevantEvents: ['daily_checkin'],
    ),
    BadgeDef(
      id: 'unstoppable',
      name: 'Unstoppable',
      description: 'Log in on 30 consecutive days.',
      icon: Icons.whatshot_rounded,
      category: BadgeCategory.streak,
      trigger: BadgeTrigger.count,
      targetCount: 30,
      isRare: true,
      relevantEvents: ['daily_checkin'],
    ),

    // ── Category 3: Quiz Performance ──────────────────────────────────────────
    BadgeDef(
      id: 'quiz_taker',
      name: 'Quiz Taker',
      description: 'Submit your very first quiz.',
      icon: Icons.quiz_rounded,
      category: BadgeCategory.quiz,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['quiz_submitted'],
    ),
    BadgeDef(
      id: 'perfect_score',
      name: 'Perfect Score',
      description: 'Score 100% on any quiz for the first time.',
      icon: Icons.star_rounded,
      category: BadgeCategory.quiz,
      trigger: BadgeTrigger.quality,
      isRare: true,
      relevantEvents: ['quiz_submitted'],
    ),
    BadgeDef(
      id: 'quiz_streak',
      name: 'Quiz Streak',
      description: 'Score 70% or above on 5 quizzes in a row.',
      icon: Icons.trending_up_rounded,
      category: BadgeCategory.quiz,
      trigger: BadgeTrigger.count,
      targetCount: 5,
      relevantEvents: ['quiz_submitted'],
    ),
    BadgeDef(
      id: 'comeback',
      name: 'Comeback',
      description: 'Retake a quiz you previously failed and pass it.',
      icon: Icons.replay_rounded,
      category: BadgeCategory.quiz,
      trigger: BadgeTrigger.quality,
      relevantEvents: ['quiz_submitted'],
    ),

    // ── Category 4: Coding Exercises ──────────────────────────────────────────
    BadgeDef(
      id: 'first_code',
      name: 'First Code',
      description: 'Complete your very first coding exercise.',
      icon: Icons.code_rounded,
      category: BadgeCategory.coding,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['exercise_completed'],
    ),
    BadgeDef(
      id: 'clean_shot',
      name: 'Clean Shot',
      description: 'Complete an exercise correctly on the first try with no hints.',
      icon: Icons.bolt_rounded,
      category: BadgeCategory.coding,
      trigger: BadgeTrigger.quality,
      relevantEvents: ['exercise_completed'],
    ),
    BadgeDef(
      id: 'bug_hunter',
      name: 'Bug Hunter',
      description: 'Complete 5 debugging exercises in total.',
      icon: Icons.bug_report_rounded,
      category: BadgeCategory.coding,
      trigger: BadgeTrigger.count,
      targetCount: 5,
      relevantEvents: ['exercise_completed'],
    ),
    BadgeDef(
      id: 'speed_coder',
      name: 'Speed Coder',
      description: 'Complete a timed challenge before the timer runs out.',
      icon: Icons.speed_rounded,
      category: BadgeCategory.coding,
      trigger: BadgeTrigger.quality,
      isRare: true,
      relevantEvents: ['exercise_completed'],
    ),

    // ── Category 5: Module & Learning Path Progress ───────────────────────────
    BadgeDef(
      id: 'module_complete',
      name: 'Module Complete',
      description: 'Finish all lessons and the quiz inside a module.',
      icon: Icons.check_circle_rounded,
      category: BadgeCategory.progress,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['module_completed'],
    ),
    BadgeDef(
      id: 'halfway_there',
      name: 'Halfway There',
      description: 'Complete 50% of your assigned learning path.',
      icon: Icons.flag_rounded,
      category: BadgeCategory.progress,
      trigger: BadgeTrigger.milestone,
      relevantEvents: ['module_completed'],
    ),
    BadgeDef(
      id: 'path_completed',
      name: 'Path Completed',
      description: 'Complete all modules in your assigned learning path.',
      icon: Icons.emoji_events_rounded,
      category: BadgeCategory.progress,
      trigger: BadgeTrigger.milestone,
      isRare: true,
      relevantEvents: ['module_completed'],
    ),
  ];

  /// Look up a badge definition by ID.
  static BadgeDef? getById(String id) {
    try {
      return all.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all badges relevant to a given event type.
  static List<BadgeDef> forEvent(String event) {
    return all.where((b) => b.relevantEvents.contains(event)).toList();
  }
}
