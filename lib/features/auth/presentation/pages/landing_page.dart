import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_logo.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// LandingPage — The welcome screen shown to unauthenticated users
/// Route: /
/// ─────────────────────────────────────────────────────────────────────────────
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide ? _WideLayout() : _NarrowLayout();
            },
          ),
        ),
      ),
    );
  }
}

// ── Mobile / Narrow Layout ─────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          // Logo + name
          const AppLogo(size: 64)
              .animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 48),

          // Hero headline
          Text(
            'One workspace.\nLess switching.\nMore learning.',
            style: AppTextStyles.displayLarge.copyWith(fontSize: 36),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            'Everything a student needs, in one place.',
            style: AppTextStyles.tagline.copyWith(fontSize: 16),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

          const SizedBox(height: 48),

          // Feature pills
          const _FeatureHighlights()
              .animate().fadeIn(delay: 600.ms, duration: 500.ms),

          const SizedBox(height: 56),

          // CTA Buttons
          _CTAButtons()
              .animate().fadeIn(delay: 800.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

// ── Desktop / Wide Layout ─────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: hero content
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 48, horizontal: true)
                    .animate().fadeIn(duration: 600.ms),
                const SizedBox(height: 48),
                Text(
                  'One workspace.\nLess switching.\nMore learning.',
                  style: AppTextStyles.displayLarge,
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.1, end: 0),
                const SizedBox(height: 20),
                Text(
                  'Everything a student needs, in one place.',
                  style: AppTextStyles.tagline,
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: 48),
                _CTAButtons().animate().fadeIn(delay: 600.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
        // Right: feature highlights
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: const _FeatureHighlights(vertical: true)
                .animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.1, end: 0),
          ),
        ),
      ],
    );
  }
}

// ── Feature Highlights Grid ───────────────────────────────────────────────────
class _FeatureHighlights extends StatelessWidget {
  final bool vertical;
  const _FeatureHighlights({this.vertical = false});

  static const _features = [
    _Feature(icon: '🤖', label: 'AI Assistant',   desc: 'Get instant explanations'),
    _Feature(icon: '✅', label: 'To-Do List',      desc: 'Track assignments & deadlines'),
    _Feature(icon: '🔍', label: 'Smart Search',   desc: 'Find free study resources'),
    _Feature(icon: '💬', label: 'Community',       desc: 'Discuss with classmates'),
    _Feature(icon: '🧮', label: 'Calculator',      desc: 'Scientific, works offline'),
    _Feature(icon: '📄', label: 'PDF Tools',       desc: 'Convert and process PDFs'),
  ];

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Column(
        children: _features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _FeatureTile(feature: f),
        )).toList(),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _features.map((f) => _FeatureChip(feature: f)).toList(),
    );
  }
}

class _Feature {
  final String icon, label, desc;
  const _Feature({required this.icon, required this.label, required this.desc});
}

class _FeatureChip extends StatelessWidget {
  final _Feature feature;
  const _FeatureChip({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(feature.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(feature.label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  const _FeatureTile({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(feature.icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.label, style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text(feature.desc, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── CTA Buttons ────────────────────────────────────────────────────────────────
class _CTAButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/signup'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Get Started — It\'s Free',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}
