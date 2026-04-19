// lib/features/quiz/data/services/quiz_result_service.dart
import '../../../../core/data/local_database.dart';
import '../../../../core/data/models/result_models.dart';

class QuizResultService {
  final LocalDatabase _db;

  QuizResultService(this._db);

  Future<QuizRoutingResult> processResult(
      String quizId, List<QuestionResult> results) async {

    final score = _calculateScore(results);
    final failedTags = _getFailedSkillTags(results);

    // Save result locally
    await _db.saveQuizResult(quizId, score, failedTags);

    if (score >= 0.70) {
      // PASS
      final moduleId = quizId.replaceAll('_quiz', '');
      final nextModuleId = _getNextModuleId(moduleId);
      await _db.unlockModule(nextModuleId);
      return QuizRoutingResult.pass(nextModuleId: nextModuleId);
    } else {
      // FAIL → adaptive remediation
      final remediationModuleId = '${quizId.replaceAll("_quiz", "")}_remediation';
      await _db.unlockRemediationModule(
        remediationModuleId,
        failedSkillTags: failedTags,
      );
      return QuizRoutingResult.remediation(
        remediationModuleId: remediationModuleId,
        failedTags: failedTags,
      );
    }
  }

  // ── Helpers ──────────────────────────────────────────────

  double _calculateScore(List<QuestionResult> results) {
    if (results.isEmpty) return 0.0;
    final correct = results.where((r) => r.isCorrect).length;
    return correct / results.length;
  }

  List<String> _getFailedSkillTags(List<QuestionResult> results) {
    return results
        .where((r) => !r.isCorrect)
        .map((r) => r.skillTag)
        .toSet()
        .toList();
  }

  /// Derives the next module ID from the current one.
  /// e.g. 'module_01' → 'module_02'
  String _getNextModuleId(String moduleId) {
    final num = int.tryParse(moduleId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    return 'module_${(num + 1).toString().padLeft(2, '0')}';
  }
}