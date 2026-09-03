import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    return AdaptiveScaffold(
      selectedIndex: 7,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Profile', style: AppTextStyles.headlineSmall)),
        body: profile == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(profile.initials, style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w700)),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 16),
                    Text(profile.displayName, style: AppTextStyles.headlineMedium).animate().fadeIn(delay: 100.ms),
                    Text('@${profile.username}', style: AppTextStyles.bodySmall).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 32),

                    // Info cards
                    ...[
                      if (profile.college.isNotEmpty) _InfoRow(icon: Icons.school_outlined, label: 'College', value: profile.college),
                      if (profile.branch.isNotEmpty)  _InfoRow(icon: Icons.code_rounded, label: 'Branch', value: profile.branch),
                      if (profile.year != null)        _InfoRow(icon: Icons.calendar_today_outlined, label: 'Year', value: 'Year ${profile.year}'),
                      if (profile.bio.isNotEmpty)      _InfoRow(icon: Icons.info_outline_rounded, label: 'Bio', value: profile.bio),
                    ].asMap().entries.map((e) => e.value.animate().fadeIn(delay: Duration(milliseconds: 200 + e.key * 60))),

                    const SizedBox(height: 32),

                    // Sign out button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                        label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          await context.read<AuthProvider>().signOut();
                          if (context.mounted) context.go('/');
                        },
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                  ],
                ),
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Row(children: [
      Icon(icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppTextStyles.labelSmall),
        Text(value, style: AppTextStyles.bodyMedium),
      ]),
    ]),
  );
}
