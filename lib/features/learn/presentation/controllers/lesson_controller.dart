// lib/features/learn/presentation/controllers/lesson_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/lesson_data.dart';
import '../../data/services/lesson_completion_service.dart';
import '../../data/services/progress_service.dart';
import '../../../../core/data/models/result_models.dart';

class LessonController extends ChangeNotifier {
  final LessonCompletionService _completionService;

  LessonController(this._completionService);

  // ── State ────────────────────────────────────────────────────────────────

  LessonData? _lessonData;
  LessonData? get lessonData => _lessonData;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── Slide & Quiz State ──────────────────────────────────────────────────

  int _currentSlideIndex = 0;
  int get currentSlideIndex => _currentSlideIndex;

  bool _isQuizMode = false;
  bool get isQuizMode => _isQuizMode;

  int _currentQuizIndex = 0;
  int get currentQuizIndex => _currentQuizIndex;

  final List<bool> _quizResults = [];
  List<bool> get quizResults => _quizResults;

  bool _isLessonComplete = false;
  bool get isLessonComplete => _isLessonComplete;

  /// The lesson id that is currently displayed.
  String? _currentLessonId;
  String? get currentLessonId => _currentLessonId;

  /// The module id that is currently displayed.
  String? _currentModuleId;
  String? get currentModuleId => _currentModuleId;

  /// Total number of lessons in the current module (read from meta.json).
  int _totalLessons = 5;
  int get totalLessons => _totalLessons;

  // ── Derived navigation helpers ────────────────────────────────────────────

  int get _currentLessonNumber {
    if (_currentLessonId == null) return 1;
    final parts = _currentLessonId!.split('_l');
    if (parts.length > 1) {
      final numPart = parts.last.replaceAll('_', '.');
      return int.tryParse(numPart.split('.').first) ?? 1;
    }
    return 1;
  }

  bool get hasPreviousLesson => _currentLessonNumber > 1;
  bool get hasNextLesson => _currentLessonNumber < _totalLessons;
  bool get isLastLesson => _currentLessonNumber >= _totalLessons;

  /// True when the loaded lesson's JSON contains "is_module_closer": true.
  /// Used by LessonScreen and TryItYourselfCta to trigger quiz navigation
  /// instead of attempting to load a non-existent next lesson file.
  bool get isModuleCloser => _lessonData?.isModuleCloser ?? false;

  String get previousLessonId {
    final prev = _currentLessonNumber - 1;
    return '${_currentModuleId}_l${prev.toString().padLeft(2, '0')}';
  }

  String get nextLessonId {
    final next = _currentLessonNumber + 1;
    return '${_currentModuleId}_l${next.toString().padLeft(2, '0')}';
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadLesson(String moduleId, String lessonId) async {
    _isLoading = true;
    _error = null;
    _currentModuleId = moduleId;
    _currentLessonId = lessonId;
    _currentSlideIndex = 0;
    _isQuizMode = false;
    _currentQuizIndex = 0;
    _quizResults.clear();
    _isLessonComplete = false;
    notifyListeners();

    try {
      // Load lesson content
      final folderName = moduleId.replaceAll('_', '');
      final lessonNum = lessonId.split('_l').last;
      final formattedNum = lessonNum.replaceAll('_', '.');
      final jsonString = await rootBundle.loadString(
        'assets/content/modules/$folderName/lesson_$formattedNum.json',
      );
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      _lessonData = LessonData.fromJson(jsonMap);

      // Load module lesson count from meta.json
      await _loadTotalLessons(folderName, moduleId);
    } catch (e) {
      _error = 'Failed to load lesson: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadTotalLessons(String folderName, String moduleId) async {
    try {
      final metaString = await rootBundle.loadString(
        'assets/content/modules/$folderName/meta.json',
      );
      final List<dynamic> metaList = jsonDecode(metaString);
      // meta.json is a list; find the entry for this moduleId
      final entry = metaList.firstWhere(
        (m) => m['module_id'] == moduleId,
        orElse: () => null,
      );
      if (entry != null && entry['lesson_count'] != null) {
        _totalLessons = entry['lesson_count'] as int;
      }
    } catch (_) {
      // Keep default if meta.json is missing or malformed
    }
  }

  // ── Derived slide/quiz helpers ────────────────────────────────────────────

  bool get isLastSlide =>
      _lessonData != null &&
      _currentSlideIndex >= _lessonData!.slides.length - 1;

  bool get isLastQuizQuestion =>
      _lessonData != null &&
      _currentQuizIndex >= _lessonData!.quiz.length - 1;

  bool get allQuizAnswered =>
      _lessonData != null &&
      _quizResults.length >= _lessonData!.quiz.length;

  /// True/false if current question has been answered; null if not yet.
  bool? get lastAnswerCorrect =>
      _quizResults.length > _currentQuizIndex
          ? _quizResults[_currentQuizIndex]
          : null;

  // ── Slide & Quiz Actions ──────────────────────────────────────────────────

  void previousSlide() {
    if (_isQuizMode) {
      if (_currentQuizIndex > 0) {
        _currentQuizIndex--;
      } else {
        _isQuizMode = false;
        _quizResults.clear();
      }
    } else if (_currentSlideIndex > 0) {
      _currentSlideIndex--;
    }
    notifyListeners();
  }

  void nextSlide() {
    if (_lessonData == null) return;
    // Safe navigation to next slide, or launch quiz mode if slides are finished.
    if (_currentSlideIndex < (_lessonData!.slides.length) - 1) {
      _currentSlideIndex++;
      notifyListeners();
    } else if (_lessonData!.quiz.isEmpty) {
      // No embedded quiz — show completion view immediately and persist in background.
      _isQuizMode = true;
      _isLessonComplete = true;
      notifyListeners();
      completeLesson();
    } else {
      _isQuizMode = true;
      _currentQuizIndex = 0;
      _quizResults.clear();
      notifyListeners();
    }
  }

  void submitQuizAnswer(bool isCorrect) {
    if (_lessonData == null || _currentQuizIndex >= (_lessonData!.quiz.length))
      return;

    if (_quizResults.length == _currentQuizIndex) {
      _quizResults.add(isCorrect);
    } else {
      _quizResults[_currentQuizIndex] = isCorrect;
    }
    notifyListeners();
  }

  Future<LessonCompletionResult?> advanceQuiz() async {
    if (_lessonData == null) return null;

    if (_currentQuizIndex < (_lessonData!.quiz.length) - 1) {
      _currentQuizIndex++;
      notifyListeners();
      return null;
    } else {
      return await completeLesson();
    }
  }

  Future<LessonCompletionResult?> completeLesson() async {
    _isLessonComplete = true;
    notifyListeners();

    final canonicalModuleId = _currentModuleId ?? _lessonData!.moduleId;
    final canonicalLessonId = _currentLessonId ?? _lessonData!.lessonId;

    // Persist completion via ProgressService (sqflite)
    await ProgressService.instance.markLessonComplete(
      canonicalModuleId,
      canonicalLessonId,
    );

    final result = await _completionService.completeLesson(
      canonicalModuleId,
      canonicalLessonId,
      totalLessons: _totalLessons,
    );

    // ── Bug 3 fix: honour the is_module_closer JSON flag ───────────────────
    // If this lesson declares itself the last in the module, always direct
    // the user to the quiz — regardless of what the DB completion count
    // returns. This makes end-of-module detection authoritatively data-driven
    // and immune to UID scope mismatches in the sqflite progress table.
    if (_lessonData?.isModuleCloser == true) {
      return LessonCompletionResult.triggerQuiz;
    }

    return result;
  }
}
