import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../components/buttons/app_button.dart';
import '../../../../components/inputs/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../main.dart';
import '../../../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  // Direct reference to the controller so we can add/remove the listener.
  AuthController? _authRef;

  @override
  void initState() {
    super.initState();
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Auth-state listener ────────────────────────────────────────────────────
  //
  // Called synchronously by ChangeNotifier.notifyListeners() whenever auth
  // status changes.  We defer the actual Navigator call to the next frame via
  // addPostFrameCallback so we never attempt a navigation-stack mutation while
  // a notifyListeners dispatch or a widget build is in progress.

  void _onAuthStateChanged() {
    if (!mounted) return;

    if (_authRef!.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // If this screen was pushed as a named route, pop it and let the
        // rebuilt AuthGate (which watches the same controller) render the
        // appropriate destination at the root level.
        // If this IS the AuthGate root (canPop == false), the AuthGate's own
        // context.watch rebuild already swaps the widget — nothing to do here.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  // ── Login handler ──────────────────────────────────────────────────────────
  //
  // Sole responsibility: validate the form and call the controller.
  // Navigation on success is handled entirely by _onAuthStateChanged.
  // This avoids the async-gap / reassigned-context problem of the old pattern.

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    // Guard: widget may have been unmounted while Firebase was responding.
    if (!mounted) return;

    // Show the error SnackBar only on failure; success is handled by the
    // listener above.
    if (auth.status == AuthStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Login failed.'),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl4),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(AppRadius.xl2),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(76),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.code,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),
                Text('Welcome back', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Log in to pick up where you left off.',
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl3),

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
                      return 'Invalid email';
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
                      value!.isEmpty ? 'Password is required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.mutedForeground,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Forgot password?', style: AppTextStyles.labelSm),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl3),

                Consumer<AuthController>(
                  builder: (context, auth, _) {
                    final isLoading = auth.status == AuthStatus.loading;
                    return AppButton(
                      label: 'Log in',
                      isLoading: isLoading,
                      onPressed: _onLogin,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl2),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.register,
                      ),
                      child: Text(
                        'Sign up',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
