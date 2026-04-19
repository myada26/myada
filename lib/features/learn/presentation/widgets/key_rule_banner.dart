// lib/features/learn/presentation/widgets/key_rule_banner.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

class KeyRuleBanner extends StatelessWidget {
  final String ruleText;

  const KeyRuleBanner({
    super.key,
    required this.ruleText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F5), // Light teal background
        border: const Border(
          left: BorderSide(color: Color(0xFF1ABC9C), width: 4), // Teal accent
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.md),
          bottomRight: Radius.circular(AppRadius.md),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.key_rounded, color: Color(0xFF1ABC9C), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ruleText,
              style: const TextStyle(
                color: Color(0xFF0E6251),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
