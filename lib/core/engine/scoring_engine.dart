class ScoringConstants {
  static const Map<String, int> questionWeights = {
    'multiple_choice': 10,
    'parsons':         15,
    'fill_in_blank':   15,
    'spot_bug':        15,
    'coding':          20,
    'coding_partial':  10,
  };

  static const int    timeBonusMax         = 30;
  static const double fullZoneThreshold    = 0.30;
  static const double zeroZoneThreshold    = 0.70;
  static const int    firstAttemptBonus    = 15;
  static const int    streakBonus          = 20;
  static const double passThreshold        = 0.70;
  static const double confidentThreshold   = 0.90;
  static const int    moduleQuizMinutes    = 15;
  static const int    retryQuizMinutes     = 10;
  static const int    maxModuleScore       = 185;
}

class QuizSessionResult {
  final int    accuracyScore;
  final int    timeBonus;
  final int    firstAttemptBonus;
  final int    streakBonus;
  final int    totalScore;
  final double accuracyPct;
  final bool   passed;
  final String skillLevelAchieved;

  const QuizSessionResult({
    required this.accuracyScore,
    required this.timeBonus,
    required this.firstAttemptBonus,
    required this.streakBonus,
    required this.totalScore,
    required this.accuracyPct,
    required this.passed,
    required this.skillLevelAchieved,
  });
}

class ScoringEngine {
  static int calcTimeBonus(int timeUsedSeconds, int timeLimitSeconds) {
    if (timeLimitSeconds == 0) return 0;
    final pct = timeUsedSeconds / timeLimitSeconds;
    if (pct <= ScoringConstants.fullZoneThreshold) {
      return ScoringConstants.timeBonusMax;
    }
    if (pct >= ScoringConstants.zeroZoneThreshold) return 0;
    final decay = (pct - ScoringConstants.fullZoneThreshold) /
        (ScoringConstants.zeroZoneThreshold -
            ScoringConstants.fullZoneThreshold);
    return (ScoringConstants.timeBonusMax * (1 - decay)).floor();
  }

  static int calcQuestionPoints({
    required String questionType,
    required bool isCorrect,
    bool isPartialCredit = false,
  }) {
    if (!isCorrect && !isPartialCredit) return 0;
    if (isPartialCredit && questionType == 'coding') {
      return ScoringConstants.questionWeights['coding_partial'] ?? 10;
    }
    return ScoringConstants.questionWeights[questionType] ?? 10;
  }

  static String resolveSkillLevel(double accuracyPct) {
    if (accuracyPct >= ScoringConstants.confidentThreshold) return 'confident';
    if (accuracyPct >= ScoringConstants.passThreshold) return 'building';
    return 'developing';
  }

  static QuizSessionResult calcSessionResult({
    required List<int> pointsPerQuestion,
    required int totalQuestions,
    required int timeUsedSeconds,
    required int timeLimitSeconds,
    required bool isFirstAttempt,
    required bool hasStreak,
    required String attemptType,
  }) {
    final accuracyScore = pointsPerQuestion.fold(0, (a, b) => a + b);
    final correctCount  = pointsPerQuestion.where((p) => p > 0).length;
    final accuracyPct   = totalQuestions > 0
        ? correctCount / totalQuestions : 0.0;
    final passed       = accuracyPct >= ScoringConstants.passThreshold;
    final isModule     = attemptType == 'module_quiz';

    final tBonus  = isModule
        ? calcTimeBonus(timeUsedSeconds, timeLimitSeconds) : 0;
    final fBonus  = (isModule && isFirstAttempt && passed)
        ? ScoringConstants.firstAttemptBonus : 0;
    final sBonus  = (isModule && hasStreak && passed)
        ? ScoringConstants.streakBonus : 0;

    return QuizSessionResult(
      accuracyScore:     accuracyScore,
      timeBonus:         tBonus,
      firstAttemptBonus: fBonus,
      streakBonus:       sBonus,
      totalScore:        accuracyScore + tBonus + fBonus + sBonus,
      accuracyPct:       accuracyPct,
      passed:            passed,
      skillLevelAchieved: resolveSkillLevel(accuracyPct),
    );
  }
}
