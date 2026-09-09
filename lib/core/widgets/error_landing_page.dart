import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../shared/widgets/app_logo.dart';

/// Beautiful branded Error & 404 landing page for StudySpace
class ErrorLandingPage extends StatelessWidget {
  final GoRouterState state;

  const ErrorLandingPage({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final location = state.uri.toString().toLowerCase();
    final errorMsg = state.error?.message.toLowerCase() ?? '';

    final isExpiredOtp =
        location.contains('otp_expired') ||
        location.contains('expired') ||
        errorMsg.contains('otp_expired') ||
        errorMsg.contains('expired');

    final isAccessDenied =
        location.contains('access_denied') ||
        errorMsg.contains('access_denied');

    String title;
    String description;
    String emoji;
    String primaryActionLabel;
    String primaryActionRoute;

    if (isExpiredOtp) {
      emoji = '⏳';
      title = 'Verification Link Expired';
      description =
          'This email confirmation or login link has expired or has already been used. Please log in or request a new 6-digit verification code.';
      primaryActionLabel = 'Sign In / Request Code';
      primaryActionRoute = '/login';
    } else if (isAccessDenied) {
      emoji = '🔒';
      title = 'Access Denied';
      description =
          'Unable to verify this link. Please check your credentials or sign in with your email and password.';
      primaryActionLabel = 'Go to Sign In';
      primaryActionRoute = '/login';
    } else {
      emoji = '🧭';
      title = 'Page Not Found';
      description =
          "The page or route you're looking for doesn't exist or has been moved.";
      primaryActionLabel = 'Back to Home';
      primaryActionRoute = '/';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(
                      size: 40,
                      horizontal: true,
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 28),

                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ).animate().scale(delay: 100.ms, duration: 400.ms),
                    const SizedBox(height: 20),

                    Text(
                      title,
                      style: AppTextStyles.headlineMedium,
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 10),

                    Text(
                      description,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go(primaryActionRoute),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          primaryActionLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Return to Home Page'),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
