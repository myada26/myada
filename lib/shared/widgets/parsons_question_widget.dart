import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

typedef ParsonsOrderChanged = void Function(List<int> order, String answer);

class ParsonsQuestionWidget extends StatefulWidget {
  final List<String> lines;
  final ParsonsOrderChanged onOrderChanged;
  final bool enabled;
  final bool expand;
  final String helperText;

  const ParsonsQuestionWidget({
    super.key,
    required this.lines,
    required this.onOrderChanged,
    this.enabled = true,
    this.expand = false,
    this.helperText = 'Drag the lines into the correct order.',
  });

  @override
  State<ParsonsQuestionWidget> createState() => _ParsonsQuestionWidgetState();
}

class _ParsonsQuestionWidgetState extends State<ParsonsQuestionWidget> {
  late List<int> _order;

  @override
  void initState() {
    super.initState();
    _order = List<int>.generate(widget.lines.length, (index) => index);
    if (_order.length > 1) {
      _order.shuffle();
    }
  }

  @override
  void didUpdateWidget(covariant ParsonsQuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lines.length != widget.lines.length ||
        !_sameLines(oldWidget.lines, widget.lines)) {
      _order = List<int>.generate(widget.lines.length, (index) => index);
      if (_order.length > 1) {
        _order.shuffle();
      }
    }
  }

  bool _sameLines(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (!widget.enabled) return;

    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });

    final answer = jsonEncode(_order);
    widget.onOrderChanged(List<int>.unmodifiable(_order), answer);
  }

  @override
  Widget build(BuildContext context) {
    final list = ReorderableListView.builder(
      buildDefaultDragHandles: false,
      shrinkWrap: !widget.expand,
      physics: widget.expand
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: _order.length,
      onReorder: widget.enabled ? _handleReorder : (oldIndex, newIndex) {},
      itemBuilder: (context, index) {
        final originalIndex = _order[index];
        final line = widget.lines[originalIndex];

        return _ParsonsLineTile(
          key: ValueKey('parsons_line_$originalIndex'),
          index: index,
          line: line,
          enabled: widget.enabled,
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.helperText,
          style: AppTextStyles.bodySm.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.expand) Expanded(child: list) else list,
      ],
    );
  }
}

class _ParsonsLineTile extends StatelessWidget {
  final int index;
  final String line;
  final bool enabled;

  const _ParsonsLineTile({
    super.key,
    required this.index,
    required this.line,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(
          color: enabled ? AppColors.primary.withAlpha(90) : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            enabled: enabled,
            child: const Icon(
              Icons.drag_indicator_rounded,
              size: 18,
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              line,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );

    return Material(color: Colors.transparent, child: tile);
  }
}
