import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../components/buttons/app_button.dart';
import '../../../../components/inputs/app_text_field.dart';
import '../../../../components/inputs/password_strength_bar.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../main.dart'; // For AppRoutes

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
  String _passwordValue = "";

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      setState(() {
        _passwordValue = _passwordCtrl.text;
      });
    });
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _dobCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

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
              onPrimary: Colors.white,
              onSurface: AppColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Simple manual formatting YYYY-MM-DD
        _dobCtrl.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You must agree to the Terms & Conditions"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final success = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      dateOfBirth: _dobCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? "Registration failed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text("Create Account", style: AppTextStyles.h1.copyWith(fontSize: 32)),
                const SizedBox(height: 8),
                Text("We're thrilled to have you join us.", style: AppTextStyles.bodyLg.copyWith(color: AppColors.mutedForeground)),
                const SizedBox(height: AppSpacing.xl2),
                
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _lastNameCtrl,
                        placeholder: "Last Name",
                        validator: (value) => value!.isEmpty ? "Required" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTextField(
                        controller: _firstNameCtrl,
                        placeholder: "First Name",
                        validator: (value) => value!.isEmpty ? "Required" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _dobCtrl,
                  placeholder: "Date of Birth",
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  validator: (value) => value!.isEmpty ? "Select Date of Birth" : null,
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _emailCtrl,
                  placeholder: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Email is required";
                    if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) return "Invalid email address";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _passwordCtrl,
                  placeholder: "Password",
                  isPassword: true,
                  validator: (value) => value!.length < 6 ? "Minimum 6 characters" : null,
                ),
                PasswordStrengthBar(password: _passwordValue),
                const SizedBox(height: 16),
                
                AppTextField(
                  controller: _confirmPasswordCtrl,
                  placeholder: "Confirm Password",
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please confirm password";
                    if (value != _passwordCtrl.text) return "Passwords do not match";
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreedToTerms,
                        onChanged: (val) {
                          setState(() {
                            _agreedToTerms = val ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: BorderSide(color: AppColors.border.withOpacity(0.3), width: 1.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "I agree to the Terms & Conditions",
                      style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.foreground.withOpacity(0.8)),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                
                Consumer<AuthController>(
                  builder: (context, auth, _) {
                    final isLoading = auth.status == AuthStatus.loading;
                    return AppButton(
                      label: "Create Account",
                      isLoading: isLoading,
                      onPressed: _onSubmit,
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: TextStyle(color: AppColors.foreground.withOpacity(0.7))),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        "Log in",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
