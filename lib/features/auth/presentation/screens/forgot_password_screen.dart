// lib/features/auth/presentation/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../components/inputs/app_text_field.dart';
import '../../../../controllers/auth_controller.dart'; // For AuthController
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final success = await auth.sendPasswordReset(_emailCtrl.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        _sent = success;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.mutedForeground,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'My',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: 'ADA',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _sent
                    ? _SuccessView(email: _emailCtrl.text)
                    : _FormView(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        isLoading: _isLoading,
                        onSubmit: _submit,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.lock_reset_rounded, // Using default icon, can be customized
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Reset your password', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address and we\'ll send you a link to reset your password.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppTextField(
            label: 'Email Address',
            placeholder: 'e.g. maria@cmu.edu.ph',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Send Reset Link',
            onPressed: onSubmit,
            isLoading: isLoading,
            size: AppButtonSize.md, // Using medium size for consistency
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(
              0.15,
            ), // Using accent for success
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.accent,
            size: 40,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Check your inbox',
          style: AppTextStyles.h2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We sent a password reset link to\n$email',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Back to Login', // Using default text style, can be customized
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
