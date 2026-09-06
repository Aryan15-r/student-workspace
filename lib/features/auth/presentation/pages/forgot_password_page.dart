import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';

enum _ResetStep { enterEmail, enterOtpAndNewPassword, success }

/// Route: /forgot-password or /reset-password
class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  _ResetStep _currentStep = _ResetStep.enterEmail;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isDirectLinkRecovery = false;
  bool _hasSentOtp = false;

  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isPasswordRecovery) {
        setState(() {
          _isDirectLinkRecovery = true;
          _currentStep = _ResetStep.enterOtpAndNewPassword;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _hasSentOtp = true;
      _resendSeconds = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendResetCode() async {
    if (_resendSeconds > 0 && _hasSentOtp) {
      setState(() => _currentStep = _ResetStep.enterOtpAndNewPassword);
      return;
    }

    if (!_emailFormKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final auth = context.read<AuthProvider>();

    final ok = await auth.resetPassword(email);
    if (!mounted) return;

    if (ok) {
      _startResendCountdown();
      setState(() => _currentStep = _ResetStep.enterOtpAndNewPassword);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification OTP code sent to $email'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to send OTP. Please check your email and try again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendCode() async {
    if (_resendSeconds > 0) return;
    final email = _emailCtrl.text.trim();
    final auth = context.read<AuthProvider>();

    final ok = await auth.resetPassword(email);
    if (!mounted) return;

    if (ok) {
      _startResendCountdown();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A fresh verification OTP code has been sent!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to resend reset code.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resetPasswordAndSetNew() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final email = _emailCtrl.text.trim();
    final token = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();

    final auth = context.read<AuthProvider>();
    bool ok = false;

    if (_isDirectLinkRecovery) {
      ok = await auth.updatePassword(newPassword);
    } else {
      ok = await auth.resetPasswordWithOtp(
        email: email,
        token: token,
        newPassword: newPassword,
      );
    }

    if (!mounted) return;

    if (ok) {
      auth.clearPasswordRecovery();
      await auth.signOut(); // Clear any temp recovery session
      setState(() => _currentStep = _ResetStep.success);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Failed to reset password. Please check your OTP code.'),
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
              child: _buildCurrentStep(auth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AuthProvider auth) {
    switch (_currentStep) {
      case _ResetStep.enterEmail:
        return _buildEmailStep(auth);
      case _ResetStep.enterOtpAndNewPassword:
        return _buildResetStep(auth);
      case _ResetStep.success:
        return _buildSuccessStep(auth);
    }
  }

  Widget _buildEmailStep(AuthProvider auth) {
    final bool isCooldownActive = _hasSentOtp && _resendSeconds > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.go('/login'),
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
        Text('Forgot password?', style: AppTextStyles.headlineLarge)
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          "Enter your registered email and we'll send you a 6-digit verification OTP code to set a new password.",
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 32),
        Form(
          key: _emailFormKey,
          child: Column(
            children: [
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading || isCooldownActive ? null : _sendResetCode,
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
                      : Text(
                          isCooldownActive
                              ? 'Resend OTP in ${_resendSeconds}s'
                              : 'Send Verification OTP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              if (_hasSentOtp) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.pin_outlined, size: 18, color: AppColors.primary),
                    label: const Text('Already have OTP? Enter Code ➔', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () => setState(() => _currentStep = _ResetStep.enterOtpAndNewPassword),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/login'),
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

  Widget _buildResetStep(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                if (_isDirectLinkRecovery) {
                  auth.clearPasswordRecovery();
                  context.go('/login');
                } else {
                  setState(() => _currentStep = _ResetStep.enterEmail);
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
              padding: EdgeInsets.zero,
            ),
            if (!_isDirectLinkRecovery)
              TextButton(
                onPressed: () => setState(() => _currentStep = _ResetStep.enterEmail),
                child: const Text('Change email', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primary, size: 36),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 20),
        Text('Create New Password', style: AppTextStyles.headlineLarge)
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text(
          _isDirectLinkRecovery
              ? 'Your recovery link is verified! Enter a new password for your account.'
              : 'Enter the 6-digit OTP code sent to ${_emailCtrl.text.trim()} and choose your new password.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 28),
        Form(
          key: _resetFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OTP Code field (only if not already authenticated via direct link)
              if (!_isDirectLinkRecovery) ...[
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
                    labelText: '6-Digit Verification OTP Code',
                    hintText: '123456',
                    hintStyle: TextStyle(
                      letterSpacing: 4,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Icon(Icons.security_rounded, color: AppColors.primary),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter the 6-digit OTP code from your email';
                    if (v.trim().length < 6) return 'Code must be at least 6 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // New password
              TextFormField(
                controller: _newPasswordCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a new password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm password
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

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _resetPasswordAndSetNew,
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
              if (!_isDirectLinkRecovery) ...[
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Didn't receive OTP? ", style: AppTextStyles.bodySmall),
                      TextButton(
                        onPressed: _resendSeconds > 0 ? null : _resendCode,
                        child: Text(
                          _resendSeconds > 0 ? 'Resend in ${_resendSeconds}s' : 'Resend OTP',
                          style: TextStyle(
                            color: _resendSeconds > 0 ? AppColors.textMuted : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildSuccessStep(AuthProvider auth) {
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
        Text('Password Reset Successfully!', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text(
          'Your password has been changed. You can now sign in to StudySpace with your new password.',
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
            child: const Text('Back to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
