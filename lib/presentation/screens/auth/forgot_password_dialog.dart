import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../state/auth_provider.dart';
import '../../widgets/custom_button.dart';

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      await ref.read(authProvider.notifier).sendPasswordReset(email);
      setState(() {
        _isLoading = false;
        _message = 'Password reset instructions have been sent to your email.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.themeSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.themeBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your registered email to receive password reset link.',
              style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(
                labelText: 'Email Address',
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
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(color: AppColors.success, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    isOutlined: true,
                    height: 44,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Send Link',
                    isLoading: _isLoading,
                    height: 44,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
