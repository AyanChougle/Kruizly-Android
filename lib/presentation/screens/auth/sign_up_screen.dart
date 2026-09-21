import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  String? _localError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _localError = 'Please fill in all required fields.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _localError = 'Passwords do not match.');
      return;
    }

    if (password.length < 6) {
      setState(() => _localError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _localError = null);

    final success = await ref.read(authProvider.notifier).registerWithEmailPassword(
          email,
          password,
          name,
          phone.isNotEmpty ? phone : null,
        );

    if (success && mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.themeTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      isDark ? AppAssets.logoDark : AppAssets.logoLight,
                      height: 52,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          'KRUIZLY',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Join KRUIZLY to rent self-drive cars',
                          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Full Name *',
                            labelStyle: TextStyle(color: context.themeTextSecondary),
                            prefixIcon: Icon(Icons.person_outline, color: context.themeTextSecondary),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email Address *',
                            labelStyle: TextStyle(color: context.themeTextSecondary),
                            prefixIcon: Icon(Icons.email_outlined, color: context.themeTextSecondary),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Phone Number (Optional)',
                            labelStyle: TextStyle(color: context.themeTextSecondary),
                            prefixIcon: Icon(Icons.phone_outlined, color: context.themeTextSecondary),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            labelStyle: TextStyle(color: context.themeTextSecondary),
                            prefixIcon: Icon(Icons.lock_outline, color: context.themeTextSecondary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: context.themeTextSecondary,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: context.themeTextPrimary),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password *',
                            labelStyle: TextStyle(color: context.themeTextSecondary),
                            prefixIcon: Icon(Icons.lock_outline, color: context.themeTextSecondary),
                            filled: true,
                            fillColor: context.themeSurfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.themeBorder),
                            ),
                          ),
                        ),
                        if (_localError != null) ...[
                          const SizedBox(height: 12),
                          Text(_localError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ],
                        if (authState.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(authState.errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 20),
                        CustomButton(
                          text: 'Create Account',
                          isLoading: authState.isLoading,
                          onPressed: _handleSignUp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(color: context.themeTextSecondary, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            color: isDark ? AppColors.primaryLight : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
