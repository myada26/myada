// lib/features/learn/presentation/widgets/concept_block.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ConceptBlock extends StatelessWidget {
  final String heading;
  final String body;

  const ConceptBlock({
    super.key,
    required this.heading,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 12),
        MarkdownBody(
          data: body,
          styleSheet: MarkdownStyleSheet(
            p: AppTextStyles.body.copyWith(
              color: AppColors.subtleForeground,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
