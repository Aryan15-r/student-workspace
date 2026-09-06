import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Route: /reset-password
class ResetPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ResetPasswordPage({super.key, this.initialEmail});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSuccess = false;
  bool _useOtpMode = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
    
    // Check if user already has an active recovery session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isPasswordRecovery || (auth.isAuthenticated && !auth.isGuest)) {
        setState(() => _useOtpMode = false);
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final newPassword = _newPasswordCtrl.text.trim();
    bool success = false;

    if (_useOtpMode) {
      final email = _emailCtrl.text.trim();
      final otp = _otpCtrl.text.trim();
      success = await auth.resetPasswordWithOtp(
        email: email,
        token: otp,
        newPassword: newPassword,
      );
    } else {
      success = await auth.updatePassword(newPassword);
    }

    if (!mounted) return;

    if (success) {
      auth.clearPasswordRecovery();
      setState(() => _isSuccess = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to update password. Please verify your OTP code.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _isSuccess ? _buildSuccessView(auth) : _buildFormView(auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () {
            auth.clearPasswordRecovery();
            context.go('/login');
          },
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: 20),
        const Center(child: AppLogo(size: 44, horizontal: true))
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 36),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 20),
        Text('Reset Password', style: AppTextStyles.headlineLarge)
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          _useOtpMode
              ? 'Enter the verification OTP code sent to your email and choose a new password.'
              : 'Your email link is verified! Choose a strong new password for your account.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 24),

        // Mode switch pill if session detected
        if (auth.isPasswordRecovery || auth.isAuthenticated)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useOtpMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_useOtpMode ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Direct Link Mode',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_useOtpMode ? Colors.white : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _useOtpMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _useOtpMode ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Enter 6-Digit OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _useOtpMode ? Colors.white : AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OTP Mode: Email & Code fields
              if (_useOtpMode) ...[
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'student@example.com',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email';
                    if (!v.contains('@') || !v.contains('.')) return 'Please enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.text,
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: '6-Digit Verification Code (OTP)',
                    hintText: '123456',
                    hintStyle: TextStyle(
                      letterSpacing: 4,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter the code from your email';
                    if (v.trim().length < 6) return 'Code must be at least 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // New Password
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscureNewPassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a new password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _obscureConfirmPassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password';
                  if (v != _newPasswordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _submitReset,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Back to login
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    auth.clearPasswordRecovery();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Back to Login'),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildSuccessView(AuthProvider auth) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        Text('Password Updated!', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Your password has been successfully changed. Please log in with your new credentials.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await auth.signOut();
              auth.clearPasswordRecovery();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Sign In Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
