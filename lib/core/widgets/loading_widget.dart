import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LoadingWidget — Reusable loading indicator
///
/// USAGE:
///   if (isLoading) return const LoadingWidget();
///   if (isLoading) return const LoadingWidget(message: 'Fetching tasks...');
/// ─────────────────────────────────────────────────────────────────────────────
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingWidget({super.key, this.message, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms);

    if (fullScreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: content),
      );
    }
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: content));
  }
}
