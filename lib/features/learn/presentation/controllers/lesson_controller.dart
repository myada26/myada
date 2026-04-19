// lib/features/learn/presentation/controllers/lesson_controller.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/lesson_data.dart';
import '../../data/services/lesson_completion_service.dart';
import '../../../../core/data/models/result_models.dart';

class LessonController extends ChangeNotifier {
  final LessonCompletionService _completionService;

  LessonController(this._completionService);

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

  // Load lesson from rootBundle
  Future<void> loadLesson(String moduleId, String lessonId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assets folder uses no underscore: 'module_01' → 'module01'
      final folderName = moduleId.replaceAll('_', '');
      final lessonNum = lessonId.split('_l').last.padLeft(2, '0');
      final lessonFileName = 'lesson_$lessonNum.json';
      final String jsonString = await rootBundle.loadString(
          'assets/content/modules/$folderName/$lessonFileName');

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      _lessonData = LessonData.fromJson(jsonMap);
      _userCode = _lessonData!.tryItYourself.starterCode;
    } catch (e) {
      _error = 'Failed to load lesson: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  void updateUserCode(String code) {
    _userCode = code;
    notifyListeners();
  }

  // Very basic simulation of running python for UI purposes
  void runCodeSimulation() {
    if (_lessonData == null) return;
    
    // Simulate output by checking the code strictly for what we expect
    // In a real app, this would send code to a backend or local interpreter.
    // For this prototype, we'll extract contents of print() statements.
    final regex = RegExp(r"print\(['" + '"' + r"']?(.*?)['" + '"' + r"]?\)");
    final matches = regex.allMatches(_userCode);
    
    if (matches.isEmpty) {
      _userOutput = '';
    } else {
      _userOutput = matches.map((m) => m.group(1) ?? '').join('\n');
    }
    notifyListeners();
  }

  Future<LessonCompletionResult?> submitCode() async {
    if (_lessonData == null) return null;
    final rules = _lessonData!.tryItYourself;
    
    bool isValid = false;

    // Run simulation to get output
    runCodeSimulation();

    // Validate based on validation_type
    switch (rules.validationType) {
      case 'output_contains':
        // we'll check if the output is not empty and code has required print calls
        final minPrints = rules.validationRules['min_print_calls'] ?? 1;
        final printCount = RegExp(r"print\(").allMatches(_userCode).length;
        if (printCount >= minPrints) {
          isValid = true;
        } else {
          _error = 'Code must contain at least $minPrints print() statements.';
        }
        break;
      case 'exact_output':
        final expected = rules.validationRules['expected_output'] ?? '';
        if (_userOutput.trim() == expected.toString().trim()) {
          isValid = true;
        } else {
          _error = 'Output does not match exactly.';
        }
        break;
      default:
        // code_structure validation deferred for Day 1
        isValid = true;
    }

    if (isValid) {
      _isSuccess = true;
      _error = null;
      notifyListeners();

      // Call completion service and return the result for routing
      return await _completionService.completeLesson(_lessonData!.lessonId);
    } else {
      if (_error == null) _error = 'Validation failed. Please check the hint.';
      _isSuccess = false;
      notifyListeners();
      return null;
    }
  }
}
