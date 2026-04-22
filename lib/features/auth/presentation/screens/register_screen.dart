import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../components/inputs/app_text_field.dart';
import '../../../../components/inputs/password_strength_bar.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _dobCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _agreedToTerms = false;
  String _passwordValue = '';

  // Direct reference to the controller so we can add/remove the listener.
  AuthController? _authRef;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      setState(() {
        _passwordValue = _passwordCtrl.text;
      });
    });

    // Register the auth-state listener after the first frame so the context
    // is fully active and Provider.of is safe to call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authRef = context.read<AuthController>();
      _authRef!.addListener(_onAuthStateChanged);
    });
  }

  @override
  void dispose() {
    _authRef?.removeListener(_onAuthStateChanged);
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _dobCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ── Auth-state listener ────────────────────────────────────────────────────
  //
  // Called synchronously by ChangeNotifier.notifyListeners() whenever auth
  // status changes. We defer the actual Navigator call to the next frame so we
  // never attempt a navigation-stack mutation while a notifyListeners dispatch
  // or widget build is in progress.

  void _onAuthStateChanged() {
    if (!mounted) return;

    if (_authRef!.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // RegisterScreen is always pushed as a named route on top of AuthGate,
        // so canPop() will be true. Pop it and let the AuthGate's context.watch
        // rebuild render PreassessScreen (or MainNavShell) underneath.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryForeground,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ── Submit handler ─────────────────────────────────────────────────────────
  //
  // Sole responsibility: validate the form and call the controller.
  // Navigation on success is handled entirely by _onAuthStateChanged.

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms & Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text,
    );

    // Guard: widget may have been unmounted while Firebase was responding.
    if (!mounted) return;

    // Show the error SnackBar only on failure; success navigation is handled
    // by the listener above.
    if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Registration failed.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text('Create Account', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  "We're thrilled to have you join us.",
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameCtrl,
                        placeholder: 'Last Name',
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameCtrl,
                        placeholder: 'First Name',
                        validator: (value) =>
                            value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _dobCtrl,
                  placeholder: 'Date of Birth',
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) =>
                      value!.isEmpty ? 'Select Date of Birth' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _emailCtrl,
                  placeholder: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value)) {
                      return 'Invalid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _passwordCtrl,
                  placeholder: 'Password',
                  isPassword: true,
                  validator: (value) =>
                      value!.length < 6 ? 'Minimum 6 characters' : null,
                ),
                PasswordStrengthBar(password: _passwordValue),
                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _confirmPasswordCtrl,
                  placeholder: 'Confirm Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm password';
                    if (value != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (val) {
                          setState(() => _agreedToTerms = val ?? false);
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        side: BorderSide(color: AppColors.border, width: 1.5),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'I agree to the Terms & Conditions',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl3),

                Consumer<AuthController>(
                  builder: (context, auth, _) {
                    final isLoading = auth.status == AuthStatus.loading;
                    return AppButton(
                      label: 'Create Account',
                      isLoading: isLoading,
                      onPressed: _onSubmit,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      ),
                      child: Text(
                        'Log in',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
