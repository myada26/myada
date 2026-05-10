// lib/features/learn/presentation/screens/learn_screen.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/learning_path_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../components/navigation/global_stat_bar.dart';
import '../../../../features/learn/data/services/progress_service.dart';
import '../../../../features/learn/data/services/module_unlock_service.dart';
import '../../../../models/learning_path_model.dart';
import '../../../../main.dart';
import 'module_quiz_screen.dart';

// Local enum that mirrors ModuleUnlockService.ModuleState (avoids import conflicts)
enum _ModuleState { locked, inProgress, readyForQuiz, passed, recommended, mastered }

// ── Layout constants that mirror the inspiration's fixed coordinate system ────

/// Height reserved for each step node row (vertical spacing between nodes).
const double _kRowHeight = 200.0;

/// The neutral X center of the spine (fraction of available width).
const double _kSpineCenterFraction = 0.5;

/// The X fraction for "left" card nodes (slightly right of center, mirroring
/// the inspiration's cx=230 in a 390px container ≈ 59%).
const double _kRightNodeFraction = 0.68;

/// The X fraction for "right" card nodes (slightly left of center ≈ 41%).
const double _kLeftNodeFraction = 0.32;

/// Vertical padding before the first node and after the last.
const double _kTopPad = 40.0;
const double _kBottomPad = 56.0;

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  void _onDiagnosticTap(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.diagnostic);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningPathController>(
      builder: (context, controller, child) {
        if (controller.isBuilding) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final learningPath = controller.result?.learningPath ?? [];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.screenPadding,
                      AppSpacing.md,
                      AppSpacing.screenPadding,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const GlobalStatBar(),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Learning Path',
                          style: AppTextStyles.displayMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Diagnostic banner (if no result yet) ─────────────────
                if (!controller.hasResult)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: _DiagnosticBanner(
                        onTap: () => _onDiagnosticTap(context),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

                // ── Timeline ──────────────────────────────────────────────
                // The entire snaking timeline is one big SliverToBoxAdapter
                // so the single CustomPaint can draw the bezier snake across
                // ALL nodes simultaneously, exactly like the inspiration's SVG.
                SliverToBoxAdapter(
                  child: _SnakingTimeline(
                    modules: learningPath,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Snaking Timeline ──────────────────────────────────────────────────────────
//
// Renders the full spine path + all module nodes in a single widget so the
// CustomPainter can compute the bezier path across the complete height.

class _SnakingTimeline extends StatelessWidget {
  final List<LearningModule> modules;
  const _SnakingTimeline({required this.modules});

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) return const SizedBox.shrink();

    final totalHeight =
        _kTopPad + modules.length * _kRowHeight + _kBottomPad;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double w = constraints.maxWidth;

        return SizedBox(
          width: w,
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Background snake path ─────────────────────────────────
              Positioned.fill(
                child: CustomPaint(
                  painter: _SnakePainter(
                    moduleCount: modules.length,
                    lineColor: AppColors.subtleForeground.withAlpha(100),
                  ),
                ),
              ),

              // ── Module cards ──────────────────────────────────────────
              for (int i = 0; i < modules.length; i++)
                _PositionedModuleCard(
                  module: modules[i],
                  index: i,
                  isFirst: i == 0,
                  isLast: i == modules.length - 1,
                  totalWidth: w,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Positioned wrapper ────────────────────────────────────────────────────────
//
// Computes the node's (cx, cy) from the painter logic and positions the
// _ModuleCardAsync at the correct location.

class _PositionedModuleCard extends StatelessWidget {
  final LearningModule module;
  final int index;
  final bool isFirst;
  final bool isLast;
  final double totalWidth;

  const _PositionedModuleCard({
    required this.module,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.totalWidth,
  });

  /// Whether this node sits on the RIGHT side of the spine (even indices
  /// mirror the inspiration's isLeft=true which places right-of-center dots).
  bool get _isEven => index.isEven;

  /// Y centre of this node.
  double get _nodeCy => _kTopPad + index * _kRowHeight + _kRowHeight / 2;

  /// X centre of the node dot.
  double get _nodeCx =>
      totalWidth * (_isEven ? _kRightNodeFraction : _kLeftNodeFraction);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: _nodeCy - _kRowHeight / 2,
      left: 0,
      right: 0,
      height: _kRowHeight,
      child: _ModuleCardAsync(
        module: module,
        index: index,
        isFirst: isFirst,
        isLast: isLast,
        nodeCx: _nodeCx,
        totalWidth: totalWidth,
      ),
    );
  }
}

// ── Snake Painter ─────────────────────────────────────────────────────────────
//
// Draws the continuous bezier bezier path connecting all module nodes, plus
// start / end terminal dots – directly porting the SVG path from App.tsx.

class _SnakePainter extends CustomPainter {
  final int moduleCount;
  final Color lineColor;

  const _SnakePainter({
    required this.moduleCount,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (moduleCount == 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final double w = size.width;

    // Node X positions (same fractions as _PositionedModuleCard)
    double nodeX(int i) =>
        w * (i.isEven ? _kRightNodeFraction : _kLeftNodeFraction);
    double nodeY(int i) => _kTopPad + i * _kRowHeight + _kRowHeight / 2;

    final double startX = w * _kSpineCenterFraction;
    final double startY = _kTopPad / 2;
    final double endY = _kTopPad + moduleCount * _kRowHeight + _kBottomPad / 2;

    final path = Path();
    path.moveTo(startX, startY);

    // From start to first node
    final double cx0 = nodeX(0);
    final double cy0 = nodeY(0);
    path.cubicTo(
      startX, startY + (cy0 - startY) * 0.6,
      cx0, startY + (cy0 - startY) * 0.4,
      cx0, cy0,
    );

    // Between subsequent nodes
    for (int i = 0; i < moduleCount - 1; i++) {
      final double ax = nodeX(i);
      final double ay = nodeY(i);
      final double bx = nodeX(i + 1);
      final double by = nodeY(i + 1);
      final double midY = (ay + by) / 2;
      path.cubicTo(
        ax, midY,
        bx, midY,
        bx, by,
      );
    }

    // From last node to end terminal
    if (moduleCount > 0) {
      final double lx = nodeX(moduleCount - 1);
      final double ly = nodeY(moduleCount - 1);
      path.cubicTo(
        lx, ly + (endY - ly) * 0.4,
        startX, ly + (endY - ly) * 0.6,
        startX, endY,
      );
    }

    canvas.drawPath(path, paint);

    // Terminal dots
    canvas.drawCircle(Offset(startX, startY), 5, dotPaint);
    canvas.drawCircle(Offset(startX, endY), 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) =>
      old.moduleCount != moduleCount || old.lineColor != lineColor;
}

// ── Async wrapper ─────────────────────────────────────────────────────────────

class _ModuleCardAsync extends StatefulWidget {
  final LearningModule module;
  final int index;
  final bool isFirst;
  final bool isLast;
  final double nodeCx;
  final double totalWidth;

  const _ModuleCardAsync({
    required this.module,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.nodeCx,
    required this.totalWidth,
  });

  @override
  State<_ModuleCardAsync> createState() => _ModuleCardAsyncState();
}

class _ModuleCardAsyncState extends State<_ModuleCardAsync> {
  _ModuleState _state = _ModuleState.locked;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void didUpdateWidget(_ModuleCardAsync old) {
    super.didUpdateWidget(old);
    if (old.module.moduleId != widget.module.moduleId) _loadState();
  }

  Future<void> _loadState() async {
    // Mastered from diagnostic → always show as completed regardless of DB
    if (widget.module.status == ModuleStatus.mastered) {
      if (mounted) setState(() { _state = _ModuleState.mastered; _loaded = true; });
      return;
    }

    final ms = await ModuleUnlockService.instance.getModuleState(
      widget.module.moduleId,
      widget.module.estimatedLessons,
    );
    _ModuleState mapped;
    switch (ms) {
      case ModuleState.inProgress:
        mapped = widget.module.status == ModuleStatus.recommended
            ? _ModuleState.recommended
            : _ModuleState.inProgress;
        break;
      case ModuleState.readyForQuiz:
        mapped = _ModuleState.readyForQuiz;
        break;
      case ModuleState.passed:
        mapped = _ModuleState.passed;
        break;
      default:
        // Locked in DB — recommended modules are auto-unlocked after diagnostic
        mapped = widget.module.status == ModuleStatus.recommended
            ? _ModuleState.recommended
            : _ModuleState.locked;
    }
    if (mounted) setState(() { _state = mapped; _loaded = true; });
  }

  Future<void> _refresh() => _loadState();

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return _ModuleTimelineCard(
        module: widget.module,
        moduleState: _ModuleState.locked,
        onTap: null,
        onRefresh: _refresh,
        index: widget.index,
        isFirst: widget.isFirst,
        isLast: widget.isLast,
        nodeCx: widget.nodeCx,
        totalWidth: widget.totalWidth,
      );
    }
    return _ModuleTimelineCard(
      module: widget.module,
      moduleState: _state,
      onTap: (_state != _ModuleState.locked) ? () => _handleTap(context) : null,
      onRefresh: _refresh,
      index: widget.index,
      isFirst: widget.isFirst,
      isLast: widget.isLast,
      nodeCx: widget.nodeCx,
      totalWidth: widget.totalWidth,
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (_state == _ModuleState.readyForQuiz) {
      await _openQuiz(context);
    } else {
      await _openLesson(context);
    }
    await _refresh();
  }

  Future<void> _openLesson(BuildContext context) async {
    if (!context.mounted) return;
    await Navigator.of(context).pushNamed(
      AppRoutes.moduleDetail,
      arguments: {'moduleId': widget.module.moduleId},
    );
  }

  Future<void> _openQuiz(BuildContext context) async {
    final moduleId = widget.module.moduleId;
    final folderName = moduleId.replaceAll('_', '');
    List<Map<String, dynamic>> questions = [];
    String nextModuleId = '';

    try {
      final raw = await rootBundle
          .loadString('assets/content/modules/$folderName/quiz.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final rawQuestions = decoded['questions'] as List<dynamic>? ?? [];
      questions = rawQuestions.map<Map<String, dynamic>>((q) {
        final m = Map<String, dynamic>.from(q as Map);
        return {
          'id':            m['id'] ?? '',
          'prompt_text':   m['prompt'] ?? m['prompt_text'] ?? '',
          'question_type': m['type'] ?? m['question_type'] ?? 'multiple_choice',
          'content':       m,
          'correct_answer': m['correct_index']?.toString() ?? m['answer'] ?? '',
          'explanation':   m['explanation'] ?? '',
        };
      }).toList();

      final remediation =
          decoded['adaptive_remediation'] as Map<String, dynamic>? ?? {};
      final onPass = remediation['on_pass'] as Map<String, dynamic>? ?? {};
      nextModuleId = onPass['next_module_id'] as String? ?? '';
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load quiz: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleQuizScreen(
          moduleId:       moduleId,
          learnerId:      ProgressService.instance.currentUserId,
          questions:      questions,
          isFirstAttempt: true,
          hasStreak:      false,
          nextModuleId:   nextModuleId,
        ),
      ),
    );
  }
}

// ── Timeline Card (visual presentation layer) ─────────────────────────────────
//
// Directly mirrors the inspiration's layout:
//
//  Even index (isLeft in inspiration):
//    [step label] ← [NodeDot] ← [Pill card with icon on RIGHT side▶] [STEP 0N]
//
//  Odd index (isRight in inspiration):
//    [STEP 0N] [◀Pill card with icon on LEFT side] → [NodeDot] → [step label]
//
// The pill + pointer + icon-circle are absolute-positioned in a Stack, just
// like the inspiration's CSS absolute positioning.

class _ModuleTimelineCard extends StatelessWidget {
  final LearningModule module;
  final _ModuleState moduleState;
  final VoidCallback? onTap;
  final Future<void> Function() onRefresh;
  final int index;
  final bool isFirst;
  final bool isLast;
  final double nodeCx;
  final double totalWidth;

  const _ModuleTimelineCard({
    required this.module,
    required this.moduleState,
    required this.onTap,
    required this.onRefresh,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.nodeCx,
    required this.totalWidth,
  });

  bool get _isLocked      => moduleState == _ModuleState.locked;
  bool get _isPassed      => moduleState == _ModuleState.passed;
  bool get _isMastered    => moduleState == _ModuleState.mastered;
  bool get _isRecommended => moduleState == _ModuleState.recommended;
  bool get _isQuizReady   => moduleState == _ModuleState.readyForQuiz;
  bool get _isEven        => index.isEven;

  // ── Color helpers ─────────────────────────────────────────────────────────

  Color get _pillColor {
    if (_isLocked)   return AppColors.locked;
    if (_isMastered) return AppColors.success;
    switch (module.tagLabel) {
      case 'Sequencing':     return AppColors.success;
      case 'Logic Flow':     return AppColors.primary;
      case 'Syntax':         return AppColors.primary;
      case 'Debugging':      return AppColors.error;
      case 'Comp. Thinking': return AppColors.accent;
      default:               return AppColors.primary;
    }
  }

  IconData get _moduleIcon {
    switch (module.tagLabel) {
      case 'Sequencing':     return Icons.low_priority_rounded;
      case 'Logic Flow':     return Icons.alt_route_rounded;
      case 'Syntax':         return Icons.code_rounded;
      case 'Debugging':      return Icons.bug_report_rounded;
      case 'Comp. Thinking': return Icons.lightbulb_outline_rounded;
      default:               return Icons.library_books_rounded;
    }
  }

  // ── Geometry helpers ──────────────────────────────────────────────────────

  /// Pill dimensions are computed dynamically from totalWidth in build().
  /// Diameter of the white icon circle inside the pill.
  static const double _iconCircleD = 56.0;
  /// Diameter of the node dot on the spine.
  static const double _dotD = 22.0;
  /// Width of the triangle pointer.
  static const double _triW = 7.0;
  /// Height of the triangle pointer.
  static const double _triH = 12.0;
  /// Minimum horizontal safe margin from screen edges.
  static const double _edgeMargin = 12.0;

  @override
  Widget build(BuildContext context) {
    // The node dot centre is at nodeCx, vertically centred in the row.
    final double cx = nodeCx;

    // For even items the card is LEFT of the node; for odd it's RIGHT.
    // "Left card" in the inspiration: card sits to the LEFT, icon circle on
    // the RIGHT end, pointer on the RIGHT tip pointing right toward the node.
    // Here: even → card on left of node, odd → card on right.
    final bool cardOnLeft = _isEven;

    // ── Dynamic pill dimensions ──────────────────────────────────────
    // The pill should fill as much of its half-side as possible while keeping
    // a 12 px safe margin from both screen edges.
    //
    // cardOnLeft:  pill occupies [_edgeMargin … cx − dot/2 − triW]
    // cardOnRight: pill occupies [cx + dot/2 + triW … totalWidth − _edgeMargin]
    final double maxPillW = cardOnLeft
        ? cx - _dotD / 2 - _triW - _edgeMargin
        : totalWidth - _edgeMargin - (cx + _dotD / 2 + _triW);
    // Clamp to a sensible [120, 220] range so it doesn't look odd on huge screens.
    final double pillW = maxPillW.clamp(120.0, 220.0);
    // Taller pill so the title can wrap to 2 lines.
    const double pillH = 92.0;

    // Raw card origin before safe-margin enforcement.
    final double rawCardLeft = cardOnLeft
        ? cx - _dotD / 2 - _triW - pillW   // ends at dot edge
        : cx + _dotD / 2 + _triW;           // starts at dot edge

    // Clamp: never let the pill clip the left or right screen edge.
    final double cardLeft = cardOnLeft
        ? math.max(_edgeMargin, rawCardLeft)
        : math.min(rawCardLeft, totalWidth - _edgeMargin - pillW);

    // Step-number label sits on the OPPOSITE side from the card.
    final double stepLabelLeft = cardOnLeft
        ? cx + _dotD / 2 + 10
        : math.max(0.0, cx - _dotD / 2 - 10 - 48); // ~48 px label width

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: _isLocked ? 0.55 : 1.0,
        child: SizedBox(
          width: totalWidth,
          height: _kRowHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Node dot on spine ───────────────────────────────────
              Positioned(
                left: cx - _dotD / 2,
                top: _kRowHeight / 2 - _dotD / 2,
                child: _buildNodeDot(),
              ),

              // ── Pill card ───────────────────────────────────────────
              Positioned(
                left: cardLeft,
                top: _kRowHeight / 2 - pillH / 2,
                width: pillW,
                height: pillH,
                child: _buildPill(
                  cardOnLeft: cardOnLeft,
                  pillW: pillW,
                  pillH: pillH,
                ),
              ),

              // ── Step number label ───────────────────────────────────
              Positioned(
                left: stepLabelLeft,
                top: _kRowHeight / 2 - 36,
                child: _buildStepLabel(cardOnLeft: cardOnLeft),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Node dot ──────────────────────────────────────────────────────────────

  Widget _buildNodeDot() {
    final Color borderColor = _isLocked ? AppColors.subtleForeground : _pillColor;
    return Container(
      width: _dotD,
      height: _dotD,
      decoration: BoxDecoration(
        color: AppColors.popover,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withAlpha(51),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: (_isPassed || _isMastered)
            ? Icon(Icons.check_rounded, size: 13, color: borderColor)
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                ),
              ),
      ),
    );
  }

  // ── Pill card ─────────────────────────────────────────────────────────────

  Widget _buildPill({
    required bool cardOnLeft,
    required double pillW,
    required double pillH,
  }) {
    // The icon circle sits on the node-facing edge of the pill.
    // cardOnLeft → icon on RIGHT edge; cardOnRight → icon on LEFT edge.
    final bool iconOnRight = cardOnLeft;

    // Inner text column is padded away from the icon-circle side.
    // Give it at least AppSpacing.sm on the far edge and clear the circle.
    const double textPadFar  = AppSpacing.sm + 2.0;    // side away from icon
    final double textPadNear = _iconCircleD - 4.0;     // side next to icon

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background pill
        Container(
          width: pillW,
          height: pillH,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          // Text content — padded away from the icon circle side
          padding: EdgeInsets.only(
            left:   iconOnRight ? textPadFar  : textPadNear,
            right:  iconOnRight ? textPadNear : textPadFar,
            top:    AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: iconOnRight
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              Text(
                'Module ${module.number.toString().padLeft(2, '0')}: ${module.name}'.toUpperCase(),
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: iconOnRight ? TextAlign.left : TextAlign.right,
              ),
              const SizedBox(height: 3),
              Text(
                module.description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mutedForeground,
                  fontSize: 8,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: iconOnRight ? TextAlign.left : TextAlign.right,
              ),
              if (_isQuizReady) ...[
                const SizedBox(height: 5),
                _buildQuizBadge(),
              ],
              if (_isMastered) ...[
                const SizedBox(height: 5),
                _buildStatusBadge(
                  label: 'Mastered ✓',
                  color: AppColors.success,
                  icon: Icons.verified_rounded,
                ),
              ],
              if (_isRecommended) ...[
                const SizedBox(height: 5),
                _buildStatusBadge(
                  label: 'Recommended',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.star_outline_rounded,
                ),
              ],
            ],
          ),
        ),

        // White icon circle (positioned on the node-facing edge)
        Positioned(
          right: iconOnRight ? 2 : null,
          left:  iconOnRight ? null : 2,
          top: (pillH - _iconCircleD) / 2,
          child: Container(
            width: _iconCircleD,
            height: _iconCircleD,
            decoration: const BoxDecoration(
              color: AppColors.popover,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _isQuizReady ? Icons.quiz_rounded : _moduleIcon,
                color: _isLocked ? AppColors.textMuted : _pillColor,
                size: 22,
              ),
            ),
          ),
        ),

        // Triangle pointer (on the node-facing tip of the pill)
        Positioned(
          right: iconOnRight ? -_triW : null,
          left:  iconOnRight ? null   : -_triW,
          top: pillH / 2 - _triH / 2,
          child: CustomPaint(
            painter: _TrianglePainter(
              color: AppColors.surface,
              pointingRight: cardOnLeft, // card on left points RIGHT toward the node
            ),
            size: const Size(_triW, _triH),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryForeground,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_rounded, size: 10, color: _pillColor),
          const SizedBox(width: 3),
          Text(
            'Take Quiz',
            style: AppTextStyles.caption.copyWith(
              color: _pillColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ── Step label ────────────────────────────────────────────────────────────

  Widget _buildStepLabel({required bool cardOnLeft}) {
    // If card is on left, step label is on the RIGHT → align left
    // If card is on right, step label is on the LEFT → align right
    final bool labelOnRight = cardOnLeft;
    return Column(
      crossAxisAlignment:
          labelOnRight ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MODULE',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.subtleForeground,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            fontSize: 9,
          ),
        ),
        Text(
          (index + 1).toString().padLeft(2, '0'),
          style: AppTextStyles.h1.copyWith(
            fontSize: 52,
            fontWeight: FontWeight.w700,
            color: _isLocked
                ? AppColors.subtleForeground.withAlpha(60)
                : _pillColor.withAlpha(180),
            height: 0.85,
            letterSpacing: -3,
          ),
        ),
      ],
    );
  }
}

// ── Triangle pointer painter ──────────────────────────────────────────────────

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool pointingRight;

  const _TrianglePainter({required this.color, required this.pointingRight});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointingRight) {
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      old.color != color || old.pointingRight != pointingRight;
}

// ── Diagnostic banner ─────────────────────────────────────────────────────────

class _DiagnosticBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DiagnosticBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(25),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.accent.withAlpha(76)),
          ),
          child: Row(
            children: [
              Icon(Icons.psychology_rounded, color: AppColors.accent, size: 28),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take the diagnostic first',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your path adapts to your skill level',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.accent,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
