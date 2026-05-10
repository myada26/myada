// lib/features/learn/presentation/screens/module_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../main.dart' show AppRoutes;
import '../../data/services/progress_service.dart';

// ─── Lightweight lesson metadata (from meta.json lessons array) ───────────────

class _LessonMeta {
  final String lessonId;
  final String lessonNumber;
  final String title;

  const _LessonMeta({
    required this.lessonId,
    required this.lessonNumber,
    required this.title,
  });

  /// Builds a _LessonMeta from a plain lesson ID string (e.g. "m01_l1_1").
  /// The lesson number is derived by taking the part after "_l" and
  /// replacing underscores with dots: "1_1" → "1.1".
  factory _LessonMeta.fromId(String lessonId) {
    final parts = lessonId.split('_l');
    final numStr =
        parts.length > 1 ? parts.last.replaceAll('_', '.') : lessonId;
    return _LessonMeta(
      lessonId: lessonId,
      lessonNumber: numStr,
      title: 'Lesson $numStr',
    );
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ModuleDetailScreen extends StatefulWidget {
  final String moduleId;

  const ModuleDetailScreen({super.key, required this.moduleId});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  List<_LessonMeta> _lessons = [];
  Set<String> _completedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final folderName = widget.moduleId.replaceAll('_', '');
    try {
      final metaString = await rootBundle
          .loadString('assets/content/modules/$folderName/meta.json');
      final List<dynamic> metaList = jsonDecode(metaString);
      final entry = metaList.firstWhere(
        (m) => m['module_id'] == widget.moduleId,
        orElse: () => null,
      );

      List<_LessonMeta> lessons = [];
      if (entry != null && entry['lessons'] is List) {
        lessons = (entry['lessons'] as List)
            .map((l) => _LessonMeta.fromId(l as String))
            .toList();
      }

      final completed =
          await ProgressService.instance.getAllCompletedLessons(widget.moduleId);

      if (mounted) {
        setState(() {
          _lessons = lessons;
          _completedIds = completed.toSet();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() => _load();

  void _openLesson(_LessonMeta lesson) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.lessonViewer,
      arguments: {
        'moduleId': widget.moduleId,
        'lessonId': lesson.lessonId,
        'lessonNumber': lesson.lessonNumber,
      },
    );
    // Refresh completion state when returning from lesson
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.foreground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Module Lessons',
          style: const TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? const Center(child: Text('No lessons found.'))
              : _buildStepper(),
    );
  }

  Widget _buildStepper() {
    // Find the first non-completed lesson as the active one
    final activeIndex = _lessons.indexWhere(
      (l) => !_completedIds.contains(l.lessonId),
    );

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      itemCount: _lessons.length,
      itemBuilder: (context, index) {
        final lesson = _lessons[index];
        final isCompleted = _completedIds.contains(lesson.lessonId);
        final isActive = index == activeIndex;
        final isLocked = !isCompleted && !isActive;
        final isLast = index == _lessons.length - 1;

        return _LessonStepTile(
          lesson: lesson,
          isCompleted: isCompleted,
          isActive: isActive,
          isLocked: isLocked,
          isLast: isLast,
          onTap: isLocked ? null : () => _openLesson(lesson),
        );
      },
    );
  }
}

// ─── Individual step tile ─────────────────────────────────────────────────────

class _LessonStepTile extends StatelessWidget {
  final _LessonMeta lesson;
  final bool isCompleted;
  final bool isActive;
  final bool isLocked;
  final bool isLast;
  final VoidCallback? onTap;

  const _LessonStepTile({
    required this.lesson,
    required this.isCompleted,
    required this.isActive,
    required this.isLocked,
    required this.isLast,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSpineColumn(),
          const SizedBox(width: 16),
          Expanded(child: _buildCard(context)),
        ],
      ),
    );
  }

  Widget _buildSpineColumn() {
    final dotColor = isCompleted
        ? AppColors.success
        : isActive
            ? AppColors.primary
            : AppColors.locked;

    return SizedBox(
      width: 32,
      child: Column(
        children: [
          // Dot
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? AppColors.successLight
                  : isActive
                      ? AppColors.primary.withAlpha(20)
                      : AppColors.surfaceVariant,
              border: Border.all(color: dotColor, width: 2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: AppColors.success)
                  : isLocked
                      ? const Icon(Icons.lock_rounded,
                          size: 12, color: AppColors.locked)
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                        ),
            ),
          ),
          // Vertical connector line (hidden for last item)
          if (!isLast)
            Expanded(
              child: Center(
                child: Container(
                  width: 2,
                  color: isCompleted
                      ? AppColors.success.withAlpha(80)
                      : AppColors.border,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final cardBorder = isActive
        ? Border.all(color: AppColors.primary, width: 1.5)
        : Border.all(color: AppColors.border, width: 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: cardBorder,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lesson ${lesson.lessonNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? AppColors.subtleForeground
                          : AppColors.mutedForeground,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLocked
                          ? AppColors.subtleForeground
                          : AppColors.foreground,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                  if (isCompleted) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isLocked)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }
}
