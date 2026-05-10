// lib/features/learn/presentation/screens/lesson_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/parsons_question_widget.dart';
import '../../data/models/lesson_data.dart';
import '../../data/services/lesson_completion_service.dart';
import '../../data/services/progress_service.dart';
import '../controllers/lesson_controller.dart';

class LessonViewerScreen extends StatefulWidget {
  final String moduleId;
  final String lessonId;
  final String lessonNumber;

  const LessonViewerScreen({
    super.key,
    required this.moduleId,
    required this.lessonId,
    required this.lessonNumber,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  late final LessonController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _controller = LessonController(LessonCompletionService());
    _pageController = PageController();
    _controller.loadLesson(widget.moduleId, widget.lessonId);
    ProgressService.instance.saveLastViewed(widget.moduleId, widget.lessonId);
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    // Animate page to follow slide index when in slide mode
    if (!_controller.isQuizMode && !_controller.isLoading) {
      final target = _controller.currentSlideIndex;
      if (_pageController.hasClients &&
          _pageController.page?.round() != target) {
        _pageController.animateToPage(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<LessonController>(
        builder: (context, controller, _) {
          if (controller.isLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.error != null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                leading: const BackButton(),
              ),
              body: Center(
                child: Text(controller.error!,
                    style: const TextStyle(color: AppColors.error)),
              ),
            );
          }
          final lesson = controller.lessonData!;
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(context, lesson, controller),
            body: controller.isQuizMode
                ? _QuizView(controller: controller)
                : _SlideView(
                    lesson: lesson,
                    controller: controller,
                    pageController: _pageController,
                  ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, LessonData lesson, LessonController controller) {
    final total = lesson.slides.length;
    final current = controller.isQuizMode
        ? total
        : controller.currentSlideIndex + 1;
    final label = controller.isQuizMode ? 'Quiz' : '$current / $total';

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.foreground),
        onPressed: () {
          if (controller.isQuizMode || controller.currentSlideIndex > 0) {
            controller.previousSlide();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.title,
            style: const TextStyle(
              color: AppColors.foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: _ProgressBar(lesson: lesson, controller: controller),
      ),
    );
  }
}

// ─── Progress bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final LessonData lesson;
  final LessonController controller;

  const _ProgressBar({required this.lesson, required this.controller});

  @override
  Widget build(BuildContext context) {
    final total = lesson.slides.length + lesson.quiz.length;
    final done = controller.isQuizMode
        ? lesson.slides.length + controller.currentQuizIndex
        : controller.currentSlideIndex;
    final fraction = total == 0 ? 0.0 : done / total;

    return LinearProgressIndicator(
      value: fraction,
      backgroundColor: AppColors.border,
      color: AppColors.primary,
      minHeight: 4,
    );
  }
}

// ─── Slide view ───────────────────────────────────────────────────────────────

class _SlideView extends StatelessWidget {
  final LessonData lesson;
  final LessonController controller;
  final PageController pageController;

  const _SlideView({
    required this.lesson,
    required this.controller,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lesson.slides.length,
            itemBuilder: (context, index) =>
                _slideWidget(lesson.slides[index]),
          ),
        ),
        _NextButton(
          controller: controller,
          onPressed: controller.isLastSlide
              ? () => _showLessonCompleteModal(context, controller)
              : controller.nextSlide,
        ),
      ],
    );
  }

  Widget _slideWidget(SlideData slide) {
    switch (slide.slideType) {
      case 'concept':
        return _ConceptSlide(slide: slide);
      case 'analogy':
        return _AnalogySlide(slide: slide);
      case 'code_example':
        return _CodeExampleSlide(slide: slide);
      default:
        return _ConceptSlide(slide: slide);
    }
  }
}

class _NextButton extends StatelessWidget {
  final LessonController controller;
  final VoidCallback onPressed;
  const _NextButton({required this.controller, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isLast  = controller.isLastSlide;
    final hasQuiz = controller.lessonData?.quiz.isNotEmpty == true;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(
            isLast ? (hasQuiz ? 'Start Quiz' : 'Complete Lesson') : 'Next',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

void _showLessonCompleteModal(
    BuildContext context, LessonController controller) {
  final lessonNum =
      controller.currentLessonId?.split('_l').last ?? '?';
  final hasQuiz = controller.lessonData?.quiz.isNotEmpty == true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successLight,
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Icon(Icons.check_rounded,
                size: 32, color: AppColors.success),
          ),
          const SizedBox(height: 16),
          Text(
            'Lesson $lessonNum Completed!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep grinding! You have finished this lesson and are ready to test what you learned.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.mutedForeground,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                controller.nextSlide();
              },
              child: Text(
                hasQuiz ? 'Continue with Mini-Quiz' : 'Complete Lesson',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Slide content widgets ────────────────────────────────────────────────────

class _ConceptSlide extends StatelessWidget {
  final SlideData slide;
  const _ConceptSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CONCEPT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.heading ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.body ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.foreground,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalogySlide extends StatelessWidget {
  final SlideData slide;
  const _AnalogySlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'ANALOGY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            slide.heading ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.foreground,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withAlpha(50)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    slide.body ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.foreground,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeExampleSlide extends StatelessWidget {
  final SlideData slide;
  const _CodeExampleSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withAlpha(30),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'CODE EXAMPLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryLight,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Code block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              slide.code ?? '',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Color(0xFFD4D4D4),
                height: 1.6,
              ),
            ),
          ),
          // Annotations
          if (slide.annotations.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Line by line:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedForeground,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 10),
            ...slide.annotations.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${a.line}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.note,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.foreground,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Quiz view ────────────────────────────────────────────────────────────────

class _QuizView extends StatefulWidget {
  final LessonController controller;
  const _QuizView({required this.controller});

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  dynamic _pendingAnswer;
  bool _submitted = false;

  @override
  void didUpdateWidget(_QuizView old) {
    super.didUpdateWidget(old);
    // Reset local state when the quiz question index changes
    if (old.controller.currentQuizIndex !=
        widget.controller.currentQuizIndex) {
      _resetInput();
    }
  }

  void _resetInput() {
    setState(() {
      _pendingAnswer = null;
      _submitted = false;
    });
  }

  Future<void> _submit() async {
    if (_pendingAnswer == null) return;
    final controller = widget.controller;
    final question =
        controller.lessonData!.quiz[controller.currentQuizIndex];
    final isCorrect = question.checkAnswer(_pendingAnswer);
    controller.submitQuizAnswer(isCorrect);
    setState(() => _submitted = true);
  }

  void _advance() {
    // advanceQuiz() moves to next question OR calls completeLesson() if last.
    // _resetInput() fires automatically via didUpdateWidget on index change.
    widget.controller.advanceQuiz();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller.isLessonComplete) {
      return _CompletionView(
          onBack: () => Navigator.of(context).pop());
    }

    final quiz = controller.lessonData!.quiz;
    final question = quiz[controller.currentQuizIndex];
    final questionCount = quiz.length;
    final currentNum = controller.currentQuizIndex + 1;
    final isCorrect = controller.lastAnswerCorrect;

    return Column(
      children: [
        // Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Row(
            children: [
              Text(
                'Question $currentNum of $questionCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.foreground,
                ),
              ),
              const Spacer(),
              ...List.generate(
                questionCount,
                (i) => Container(
                  margin: const EdgeInsets.only(left: 6),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < controller.quizResults.length &&
                            controller.quizResults[i]
                        ? AppColors.success
                        : i == controller.currentQuizIndex
                            ? AppColors.primary
                            : AppColors.border,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildQuestion(question),
          ),
        ),
        // Feedback banner
        if (_submitted && isCorrect != null)
          _FeedbackBanner(isCorrect: isCorrect, explanation: question.explanation),
        // Action buttons
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _submitted
              ? SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCorrect == true ? _advance : _resetInput,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCorrect == true
                          ? AppColors.success
                          : AppColors.primary,
                      foregroundColor: isCorrect == true
                          ? AppColors.foreground
                          : AppColors.primaryForeground,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      isCorrect == true
                          ? (controller.isLastQuizQuestion
                              ? 'Complete Lesson'
                              : 'Continue')
                          : 'Try Again',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _pendingAnswer != null ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.primaryForeground,
                      disabledBackgroundColor: AppColors.border,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Check Answer',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildQuestion(LessonQuizQuestion question) {
    switch (question.questionType) {
      case 'multiple_choice':
        return _MultipleChoiceCard(
          question: question,
          selectedIndex: _pendingAnswer as int?,
          onSelect: _submitted ? null : (i) => setState(() => _pendingAnswer = i),
        );
      case 'fill_in_blank':
        return _FillInBlankCard(
          question: question,
          submitted: _submitted,
          onChanged: _submitted ? null : (v) => setState(() => _pendingAnswer = v),
        );
      case 'spot_bug':
        return _SpotBugCard(
          question: question,
          submitted: _submitted,
          onChanged: _submitted ? null : (v) => setState(() => _pendingAnswer = v),
        );
      case 'parsons':
        return _ParsonsCard(
          question: question,
          submitted: _submitted,
          onChanged: _submitted ? null : (v) => setState(() => _pendingAnswer = v),
        );
      case 'coding':
        return _CodingCard(
          question: question,
          submitted: _submitted,
          onChanged: _submitted ? null : (v) => setState(() => _pendingAnswer = v),
        );
      default:
        return Text(question.promptText);
    }
  }
}

// ─── Question card widgets ────────────────────────────────────────────────────

class _MultipleChoiceCard extends StatelessWidget {
  final LessonQuizQuestion question;
  final int? selectedIndex;
  final void Function(int)? onSelect;

  const _MultipleChoiceCard({
    required this.question,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final options = question.options ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.promptText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(options.length, (i) {
          final selected = selectedIndex == i;
          return GestureDetector(
            onTap: onSelect != null ? () => onSelect!(i) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withAlpha(10)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : AppColors.borderStrong,
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 12, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      options[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _FillInBlankCard extends StatelessWidget {
  final LessonQuizQuestion question;
  final bool submitted;
  final void Function(String)? onChanged;

  const _FillInBlankCard({
    required this.question,
    required this.submitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hint = question.content['hint'] as String?;
    final codeWithBlank = question.content['code_with_blank'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.promptText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.4,
          ),
        ),
        if (codeWithBlank != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              codeWithBlank,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Color(0xFFD4D4D4),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          enabled: !submitted,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: hint ?? 'Type your answer…',
            hintStyle: const TextStyle(color: AppColors.subtleForeground),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotBugCard extends StatelessWidget {
  final LessonQuizQuestion question;
  final bool submitted;
  final void Function(String)? onChanged;

  const _SpotBugCard({
    required this.question,
    required this.submitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final buggyCode = question.content['buggy_code'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.promptText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.4,
          ),
        ),
        if (buggyCode != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.error.withAlpha(100), width: 1),
            ),
            child: Text(
              buggyCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                color: Color(0xFFFF8A5B),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        const Text(
          'Describe the bug:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: !submitted,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: 'What is wrong with this code?',
            hintStyle: const TextStyle(color: AppColors.subtleForeground),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Parsons card ─────────────────────────────────────────────────────────────

class _ParsonsCard extends StatelessWidget {
  final LessonQuizQuestion question;
  final bool submitted;
  final void Function(String)? onChanged;

  const _ParsonsCard({
    required this.question,
    required this.submitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lines = (question.content['lines'] as List<dynamic>? ?? [])
        .map((l) => l.toString())
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.promptText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        ParsonsQuestionWidget(
          key: ValueKey('lesson_parsons_${question.questionId}'),
          lines: lines,
          enabled: !submitted,
          onOrderChanged: (_, answer) => onChanged?.call(answer),
        ),
      ],
    );
  }
}

// ─── Coding card ──────────────────────────────────────────────────────────────

class _CodingCard extends StatelessWidget {
  final LessonQuizQuestion question;
  final bool submitted;
  final void Function(String)? onChanged;

  const _CodingCard({
    required this.question,
    required this.submitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final starterCode = question.content['starter_code'] as String? ?? '';
    final hint = question.content['hint'] as String? ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.promptText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.foreground,
            height: 1.4,
          ),
        ),
        if (starterCode.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              starterCode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: Color(0xFFABB2BF),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          enabled: !submitted,
          maxLines: 4,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.foreground),
          decoration: InputDecoration(
            hintText: 'Write your code here…',
            hintStyle: const TextStyle(color: AppColors.subtleForeground),
            helperText: hint.isNotEmpty ? hint : null,
            helperMaxLines: 3,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Feedback banner ──────────────────────────────────────────────────────────

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  const _FeedbackBanner(
      {required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: isCorrect ? AppColors.successLight : AppColors.errorLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isCorrect ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect ? 'Correct!' : 'Not quite.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  explanation,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.foreground,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lesson completion view ───────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  final VoidCallback onBack;
  const _CompletionView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successLight,
                border: Border.all(color: AppColors.success, width: 2),
              ),
              child: const Icon(Icons.star_rounded,
                  size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 24),
            const Text(
              'Lesson Complete!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Great work — you passed the quiz!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.mutedForeground,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryForeground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Module',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
