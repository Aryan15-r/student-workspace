import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppLogo — The StudySpace logo widget
///
/// USAGE:
///   const AppLogo()             — default size
///   const AppLogo(size: 48)     — large
///   const AppLogo(showText: false) — icon only
/// ─────────────────────────────────────────────────────────────────────────────
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool horizontal; // true = icon + text side by side

  const AppLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _LogoIcon(size: size);

    if (!showText) return icon;

    final text = Column(
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'StudySpace',
          style: AppTextStyles.headlineMedium.copyWith(
            fontSize: size * 0.75,
            letterSpacing: -0.5,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
      ],
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [icon, const SizedBox(width: 10), text],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [icon, const SizedBox(height: 8), text],
    );
  }
}

class _LogoIcon extends StatelessWidget {
  final double size;
  const _LogoIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.25),
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
