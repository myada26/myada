import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class PasswordStrengthBar extends StatelessWidget {
  final String password;

  const PasswordStrengthBar({super.key, required this.password});

  int get strength {
    if (password.isEmpty) return 0;
    int s = 1;
    if (password.length >= 6) s = 2;
    if (password.length >= 8 && password.contains(RegExp(r'[A-Z]'))) s = 3;
    if (password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      s = 4;
    }
    return s;
  }

  Color _getColor(int index) {
    if (strength >= index) {
      if (strength == 1) return AppColors.error; // Weak
      if (strength == 2)
        return AppColors.warning; // Fair (using warning for consistency)
      if (strength == 3) return Colors.green.shade500; // Good
      if (strength == 4) return AppColors.primary; // Strong
    }
    return AppColors.border.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0),
              decoration: BoxDecoration(
                color: _getColor(index + 1), // Using the determined color
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}
