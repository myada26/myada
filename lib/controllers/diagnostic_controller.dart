import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/diagnostic_models.dart';
import '../core/engine/diagnostic_engine.dart';

/// DiagnosticController
///
/// Pure state + logic controller for the MyADA diagnostic assessment.
/// Contains NO UI code — it is consumed by Flutter widgets via
/// ChangeNotifier / Provider. Widgets call methods here and rebuild
/// whenever [notifyListeners] fires.
///
/// Scoring rules (from ADA curriculum document):
///   Tier 1 correct  → +1.0 pt
///   Tier 2 correct  → +2.0 pt
///   Wrong answer    →  0.0 pt  (no penalty)
///   Skip / timeout  → −0.5 pt
///
/// Skill level thresholds:
///   0.0 – 1.0  → Developing
///   1.5 – 2.0  → Building
///   2.5 – 3.0  → Confident
///
/// Overall profile:
///   ≥ 3 Confident skills              → Intermediate
///   ≥ 1 Confident + ≤ 2 Developing   → Novice
///   Everything else                   → Beginner
class DiagnosticController extends ChangeNotifier {
  // ─────────────────────────────────────────────────────
  // Private state
  // ─────────────────────────────────────────────────────

  /// The active, ordered list of questions for this session.
  /// Starts with one Tier 1 per skill (5 questions).
  /// Tier 2 follow-ups are injected adaptively after each Tier 1 answer.
  List<DiagnosticQuestion> _questionOrder = [];

  /// Index of the question currently being displayed.
  int _currentIndex = 0;

  /// Per-skill score accumulator.
  /// Key = skillIndex (0–4), Value = running score (can go below 0 via skips).
  final Map<int, double> _scores = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};

  /// Skill indices that were skipped at least once.
  /// Tracked separately from wrong answers for diagnostic nuance.
  final List<int> _skips = [];

  /// Tracks which skill indices have already had a Tier 2 question injected.
  /// Prevents duplicate injection if the controller state is reused.
  final Set<int> _tier2Injected = {};

  /// Responses recorded for the DiagnosticEngine.
  final List<DiagnosticResponse> _responses = [];

  /// The user's current answer for the active question.
  ///   MCQ        → int  (selected option index)
  ///   Parsons    → List<String>  (items in user-arranged order)
  ///   Dropdown   → Map<String, int>  (dropId → chosen option index)
  dynamic selectedAnswer;

  /// Countdown seconds remaining for the current question (max 90).
  int _timerSec = 90;
  Timer? _timer;

  /// True once all questions have been answered/skipped.
  /// The UI observes this to navigate to the results screen.
  bool _isComplete = false;

  // ─────────────────────────────────────────────────────
  // Public getters
  // ─────────────────────────────────────────────────────

  List<DiagnosticQuestion> get questionOrder   => _questionOrder;
  int                       get currentIndex   => _currentIndex;
  Map<int, double>          get scores         => Map.unmodifiable(_scores);
  List<int>                 get skips          => List.unmodifiable(_skips);
  int                       get timerSec       => _timerSec;
  bool                      get isComplete     => _isComplete;

  /// Total questions in the current session (grows as Tier 2s are injected).
  int get totalQuestions => _questionOrder.length;

  /// Convenience getter — throws if called when the list is empty.
  DiagnosticQuestion get currentQuestion => _questionOrder[_currentIndex];

  /// True when the user has provided any answer for the current question.
  bool get hasAnswer => selectedAnswer != null;

  // ─────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────

  /// Resets all state back to initial values.
  /// Call before starting a new session or on retake.
  void reset() {
    _scores.updateAll((_, __) => 0.0);
    _skips.clear();
    _tier2Injected.clear();
    _responses.clear();
    _currentIndex = 0;
    _isComplete = false;
    _questionOrder = [];
    selectedAnswer = null;
    _stopTimer();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Session entry points
  // ─────────────────────────────────────────────────────

  /// Entry point for users who self-identify as complete beginners.
  /// Bypasses all questions and marks the session complete immediately
  /// so the UI can jump straight to results (all scores = 0 → all Developing).
  void startCompleteBeginnerRoute() {
    reset();
    // Scores remain at 0 — all skills resolve to "Developing"
    _isComplete = true;
    notifyListeners();
  }

  /// Entry point for users who will take the full adaptive diagnostic.
  /// Builds an initial sequence of 5 Tier 1 questions (one per skill),
  /// then starts the countdown timer for the first question.
  void startDiagnostic() {
    reset();
    _buildInitialOrder();
    _startTimer();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────
  // Question order builder
  // ─────────────────────────────────────────────────────

  /// Populates [_questionOrder] with exactly one Tier 1 question per skill
  /// (skills 0–4), in skill-index order.
  /// Tier 2 follow-ups are NOT added here — they are injected dynamically
  /// in [nextQuestion] after each Tier 1 response.
  void _buildInitialOrder() {
    _questionOrder = [];

    for (int skillIdx = 0; skillIdx < 5; skillIdx++) {
      // Pick the first available Tier 1 question for this skill
      final t1 = diagnosticQuestions.firstWhere(
        (q) => q.skillIndex == skillIdx && q.tier == 1,
        orElse: () => throw StateError(
          'No Tier 1 question found for skill $skillIdx. '
          'Check your diagnosticQuestions data.',
        ),
      );
      _questionOrder.add(t1);
    }
  }

  // ─────────────────────────────────────────────────────
  // Adaptive Tier 2 injection
  // ─────────────────────────────────────────────────────

  /// Called immediately after a Tier 1 answer is recorded.
  /// Injects the appropriate Tier 2 question directly after the current
  /// position in [_questionOrder], IF one hasn't been injected yet for
  /// this skill.
  ///
  /// Adaptive routing:
  ///   Correct Tier 1  → inject the *harder* Tier 2 (last in the bank)
  ///   Wrong / skipped → inject the *easier* Tier 2 (first in the bank)
  void _injectTier2IfNeeded({
    required int skillIndex,
    required bool wasCorrect,
  }) {
    // Guard: only inject once per skill per session
    if (_tier2Injected.contains(skillIndex)) return;

    final tier2Pool = diagnosticQuestions
        .where((q) => q.skillIndex == skillIndex && q.tier == 2)
        .toList();

    if (tier2Pool.isEmpty) return; // no Tier 2 available for this skill

    // Adaptive selection: harder follow-up if correct, easier if not
    final toInject = wasCorrect ? tier2Pool.last : tier2Pool.first;

    // Insert directly after the current question
    _questionOrder.insert(_currentIndex + 1, toInject);
    _tier2Injected.add(skillIndex);
  }

  // ─────────────────────────────────────────────────────
  // Answer evaluation
  // ─────────────────────────────────────────────────────

  /// Stores the user's answer for the current question and notifies listeners
  /// so the UI can enable the "Next" button.
  void selectAnswer(dynamic answer) {
    selectedAnswer = answer;
    notifyListeners();
  }

  /// Evaluates [selectedAnswer] against the current question's correct answer.
  /// Returns false if no answer has been selected.
  bool _checkCurrentAnswer() {
    if (selectedAnswer == null) return false;

    final q = currentQuestion;

    switch (q.type) {
      case QuestionType.mcq:
        // selectedAnswer is the index of the chosen option
        return selectedAnswer == q.answer;

      case QuestionType.parsons:
        // selectedAnswer is the list of item strings in the user's arranged order.
        // q.correctSequence is a List<int> where each value is the original
        // index in q.items that should appear at that position.
        if (selectedAnswer is! List<String>) return false;
        final arranged = selectedAnswer as List<String>;
        if (arranged.length != q.items!.length) return false;
        for (int pos = 0; pos < arranged.length; pos++) {
          final originalIdx = q.items!.indexOf(arranged[pos]);
          if (originalIdx != q.correctSequence![pos]) return false;
        }
        return true;

      case QuestionType.dropdown:
        // selectedAnswer is Map<dropId, chosenOptionIndex>.
        // q.drops is a List<Map> each with 'id' and 'answer' keys.
        if (selectedAnswer is! Map<String, int>) return false;
        final chosen = selectedAnswer as Map<String, int>;
        for (final drop in q.drops!) {
          final dropId     = drop['id'] as String;
          final dropAnswer = drop['answer'] as int;
          if (chosen[dropId] != dropAnswer) return false;
        }
        return true;
    }
  }

  // ─────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────

  /// Records the current answer, applies scoring, injects an adaptive Tier 2
  /// if this was a Tier 1 question, then advances to the next question.
  void nextQuestion() {
    _stopTimer();

    final q = currentQuestion;
    final isCorrect = _checkCurrentAnswer();

    // Apply score: +1 for Tier 1, +2 for Tier 2, 0 for wrong
    final double pts = isCorrect ? (q.tier == 2 ? 2.0 : 1.0) : 0.0;
    _scores[q.skillIndex] = (_scores[q.skillIndex] ?? 0.0) + pts;

    _responses.add(DiagnosticResponse(
      skillTag: SkillTag.values[q.skillIndex],
      tier: q.tier,
      isCorrect: isCorrect,
      wasSkipped: false,
    ));

    // Adaptively inject the follow-up Tier 2 question if this was Tier 1
    if (q.tier == 1) {
      _injectTier2IfNeeded(skillIndex: q.skillIndex, wasCorrect: isCorrect);
    }

    _advance();
  }

  /// Records a skip (−0.5 pts), then advances.
  /// Also called automatically when the timer reaches zero.
  void skipQuestion() {
    _stopTimer();

    final q = currentQuestion;
    _skips.add(q.skillIndex);

    // Apply skip penalty (floor at −1 to avoid extreme negative outliers)
    final current = _scores[q.skillIndex] ?? 0.0;
    _scores[q.skillIndex] = (current - 0.5).clamp(-1.0, double.infinity);

    _responses.add(DiagnosticResponse.skipped(SkillTag.values[q.skillIndex], q.tier));

    // Treat skip as wrong for adaptive routing
    if (q.tier == 1) {
      _injectTier2IfNeeded(skillIndex: q.skillIndex, wasCorrect: false);
    }

    _advance();
  }

  /// Moves to the next index or marks the session complete.
  void _advance() {
    selectedAnswer = null;
    _currentIndex++;

    if (_currentIndex >= _questionOrder.length) {
      _isComplete = true;
      notifyListeners();
    } else {
      _startTimer();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────
  // Timer
  // ─────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timerSec = 90;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerSec > 0) {
        _timerSec--;
        notifyListeners();
      } else {
        // Time's up — treat as a skip
        skipQuestion();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─────────────────────────────────────────────────────
  // Result helpers (consumed by the results UI)
  // ─────────────────────────────────────────────────────

  /// Returns the skill level label for a given skill index.
  /// Uses DiagnosticEngine to evaluate responses.
  String getSkillLevel(int skillIndex) {
    if (_responses.isEmpty) return 'Developing';
    final result = DiagnosticEngine.calculate(_responses);
    final tag = SkillTag.values[skillIndex];
    final score = result.skillScores.firstWhere((s) => s.skillTag == tag);
    if (score.level == SkillLevel.confident) return 'Confident';
    if (score.level == SkillLevel.building) return 'Building';
    return 'Developing';
  }

  /// Returns the aggregate learner profile across all 5 skills.
  /// Uses DiagnosticEngine to evaluate responses.
  String getOverallLevel() {
    if (_responses.isEmpty) return 'Beginner';
    final result = DiagnosticEngine.calculate(_responses);
    final level = result.overallLevel;
    return level.isNotEmpty ? level[0].toUpperCase() + level.substring(1) : 'Beginner';
  }

  /// Returns true if the skill at [skillIndex] was skipped at least once.
  /// The UI can use this to show a "low confidence" indicator on that skill.
  bool wasSkipped(int skillIndex) => _skips.contains(skillIndex);

  /// Returns a progress fraction (0.0 – 1.0) for the progress bar.
  double get progressFraction {
    if (_questionOrder.isEmpty) return 0.0;
    return (_currentIndex + 1) / _questionOrder.length;
  }

  // ─────────────────────────────────────────────────────
  // Dispose
  // ─────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}