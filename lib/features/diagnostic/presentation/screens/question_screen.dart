import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../controllers/diagnostic_controller.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../models/diagnostic_models.dart';
import '../../../../shared/widgets/parsons_question_widget.dart';
import 'package:provider/provider.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  // Local state for current question answers
  int? _mcqSelection;
  List<String>? _parsonsOrder;
  Map<String, int>? _dropdownSelections;
  bool _isNavigating = false; // guard to prevent double-navigation
  int? _localQuestionIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.watch<DiagnosticController>();

    // ── Diagnostic complete → build result and go to HomeScreen ───────────────
    if (ctrl.isComplete && !_isNavigating) {
      _isNavigating = true;
      // Use microtask so we never call setState/notifyListeners during a build.
      Future.microtask(() async {
        if (!mounted) return;

        // 1. Build the learning path from diagnostic scores.
        final pathCtrl = context.read<LearningPathController>();
        await pathCtrl.buildResult(scores: ctrl.scores, skips: ctrl.skips);
        if (!mounted) return;

        // 2. Persist the diagnostic completion flag to the user profile.
        final auth = context.read<AuthController>();
        final level = ctrl.getOverallLevel();
        await auth.markDiagnosticComplete(level);

        // 3. Pop all routes back to AuthGate root.
        //    AuthGate will rebuild to MainNavShell (home) automatically.
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
      return;
    }

    // ── Reset local selections when moving to a new question ──────────────────
    if (_localQuestionIndex != ctrl.currentIndex) {
      _localQuestionIndex = ctrl.currentIndex;
      _mcqSelection = null;
      _parsonsOrder = null;
      _dropdownSelections = null;
    }

    // ── Initialize complex-type answers without calling notifyListeners in build
    if (!ctrl.isComplete && ctrl.questionOrder.isNotEmpty) {
      final q = ctrl.currentQuestion;
      if (q.type == QuestionType.parsons && _parsonsOrder == null) {
        _parsonsOrder = List.from(q.items!);
      } else if (q.type == QuestionType.dropdown &&
          _dropdownSelections == null) {
        _dropdownSelections = {};
        for (var drop in q.drops!) {
          _dropdownSelections![drop['id']] = 0;
        }
        Future.microtask(() {
          if (mounted) ctrl.selectAnswer(_dropdownSelections);
        });
      }
    }
  }

  void _handleNext() {
    context.read<DiagnosticController>().nextQuestion();
  }

  void _handleSkip() {
    context.read<DiagnosticController>().skipQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<DiagnosticController>();
    if (ctrl.isComplete || ctrl.questionOrder.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = ctrl.currentQuestion;
    final progress = (ctrl.currentIndex + 1) / ctrl.questionOrder.length;
    final m = ctrl.timerSec ~/ 60;
    final s = ctrl.timerSec % 60;
    final timerText = "$m:${s.toString().padLeft(2, '0')}";

    Color timerColor = AppColors.mutedForeground;
    if (ctrl.timerSec <= 10) {
      timerColor = Colors.red;
    } else if (ctrl.timerSec <= 30) {
      timerColor = AppColors.warning;
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Question ${ctrl.currentIndex + 1} of ${ctrl.questionOrder.length}",
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _handleSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.mutedForeground,
                        ),
                        child: const Text("Skip"),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timerText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress Bar
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Question Metadata
              Text(
                q.label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                q.text,
                style: AppTextStyles.h4.copyWith(
                  fontSize: 18, // Custom size for question text
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              if (q.code != null && q.type != QuestionType.dropdown)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    q.code!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),

              // Body
              Expanded(child: _buildQuestionBody(q, ctrl)),

              // Footer
              Center(
                child: Text(
                  diagnosticMicrocopy[ctrl.currentIndex %
                      diagnosticMicrocopy.length],
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: "Next",
                onPressed: ctrl.selectedAnswer != null ? _handleNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionBody(DiagnosticQuestion q, DiagnosticController ctrl) {
    if (q.type == QuestionType.mcq) {
      return ListView.builder(
        itemCount: q.opts!.length,
        itemBuilder: (context, index) {
          final isSelected = _mcqSelection == index;
          final letters = ['A', 'B', 'C', 'D'];
          return GestureDetector(
            onTap: () {
              setState(() {
                _mcqSelection = index;
              });
              ctrl.selectAnswer(index);
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.border.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letters[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.foreground.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      q.opts![index],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (q.type == QuestionType.parsons) {
      final lines = q.items ?? const <String>[];
      if (lines.isEmpty) {
        return Text(
          'This question is missing code lines.',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
        );
      }

      return ParsonsQuestionWidget(
        key: ValueKey('diagnostic_parsons_${ctrl.currentIndex}'),
        lines: lines,
        expand: true,
        onOrderChanged: (order, _) {
          final arrangedLines = order.map((index) => lines[index]).toList();
          setState(() => _parsonsOrder = arrangedLines);
          ctrl.selectAnswer(arrangedLines);
        },
      );
    } else if (q.type == QuestionType.dropdown) {
      // Very basic Dropdown representation
      // We parse the HTML strings `___1___` into widgets
      List<Widget> codeSpans = [];
      String remaining = q.code!;

      while (remaining.isNotEmpty) {
        int nextDrop = remaining.indexOf('___');
        if (nextDrop == -1) {
          codeSpans.add(
            Text(
              remaining,
              style: AppTextStyles.body.copyWith(
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          );
          break;
        } else {
          codeSpans.add(
            Text(
              remaining.substring(0, nextDrop),
              style: AppTextStyles.body.copyWith(
                fontFamily: 'monospace',
                height: 1.6,
              ),
            ),
          );
          // Extract the id
          int endDrop = remaining.indexOf('___', nextDrop + 3);
          String id = remaining.substring(nextDrop + 3, endDrop);

          final dropData = q.drops!.firstWhere((d) => d['id'] == id);
          final currentSelectionObj =
              dropData['opts'][_dropdownSelections![id]!];

          codeSpans.add(
            GestureDetector(
              onTap: () async {
                final selectedOption = await showModalBottomSheet<int>(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: (dropData['opts'] as List)
                            .asMap()
                            .entries
                            .map((entry) {
                              return ListTile(
                                title: Text(
                                  entry.value,
                                  style: const TextStyle(
                                    fontFamily:
                                        'monospace', // Keep monospace for code
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, entry.key),
                              );
                            })
                            .toList(),
                      ),
                    );
                  },
                );
                if (selectedOption != null) {
                  setState(() {
                    _dropdownSelections![id] = selectedOption;
                  });
                  ctrl.selectAnswer(_dropdownSelections);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(
                    bottom: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                child: Text(
                  currentSelectionObj,
                  style: AppTextStyles.body.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
          remaining = remaining.substring(endDrop + 3);
        }
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: codeSpans,
        ),
      );
    }
    return const SizedBox();
  }
}
