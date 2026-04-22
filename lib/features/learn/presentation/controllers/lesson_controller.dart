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

  String _userCode = '';
  String get userCode => _userCode;

  String _userOutput = '';
  String get userOutput => _userOutput;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

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
    return int.tryParse(parts.last) ?? 1;
  }

  bool get hasPreviousLesson => _currentLessonNumber > 1;
  bool get hasNextLesson     => _currentLessonNumber < _totalLessons;
  bool get isLastLesson      => _currentLessonNumber >= _totalLessons;

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
    _isSuccess = false;
    _userOutput = '';
    _currentModuleId = moduleId;
    _currentLessonId = lessonId;
    notifyListeners();

    try {
      // Load lesson content
      final folderName  = moduleId.replaceAll('_', '');
      final lessonNum   = lessonId.split('_l').last.padLeft(2, '0');
      final jsonString  = await rootBundle.loadString(
          'assets/content/modules/$folderName/lesson_$lessonNum.json');
      final jsonMap     = jsonDecode(jsonString) as Map<String, dynamic>;
      _lessonData = LessonData.fromJson(jsonMap);
      _userCode   = _lessonData!.tryItYourself.starterCode;

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
          'assets/content/modules/$folderName/meta.json');
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

  // ── Code editor ───────────────────────────────────────────────────────────

  void updateUserCode(String code) {
    _userCode = code;
    notifyListeners();
  }

  // Very basic simulation of running Python for UI purposes.
  void runCodeSimulation() {
    if (_lessonData == null) return;
    final regex = RegExp(r"""print\(['"]?(.*?)['"]?\)""");
    final matches = regex.allMatches(_userCode);
    _userOutput = matches.isEmpty
        ? ''
        : matches.map((m) => m.group(1) ?? '').join('\n');
    notifyListeners();
  }

  Future<LessonCompletionResult?> submitCode() async {
    if (_lessonData == null) return null;
    final rules = _lessonData!.tryItYourself;
    bool isValid = false;

    runCodeSimulation();

    switch (rules.validationType) {
      case 'output_contains':
        final minPrints = rules.validationRules['min_print_calls'] ?? 1;
        final printCount = RegExp(r'print\(').allMatches(_userCode).length;
        if (printCount >= minPrints) {
          isValid = true;
        } else {
          _error = 'Code must contain at least $minPrints print() statements.';
        }
      case 'exact_output':
        final expected = rules.validationRules['expected_output'] ?? '';
        if (_userOutput.trim() == expected.toString().trim()) {
          isValid = true;
        } else {
          _error = 'Output does not match exactly.';
        }
      default:
        // code_structure and others: accept for now
        isValid = true;
    }

    if (isValid) {
      _isSuccess = true;
      _error = null;
      notifyListeners();

      // Both ProgressService.markLessonComplete and completeLesson must use the
      // same canonical IDs (_currentModuleId / _currentLessonId) — not the
      // JSON-internal lessonId (e.g. "m01_l05") which has a different prefix.
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
    } else {
      if (_error == null) _error = 'Validation failed. Please check the hint.';
      _isSuccess = false;
      notifyListeners();
      return null;
    }
  }
}
