import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final isGuest = auth.isGuest;

    return AdaptiveScaffold(
      selectedIndex: 8,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFCF8).withValues(alpha: 0.8),
          title: Text(
            'Profile & Settings',
            style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: isGuest
            ? _GuestProfileView()
            : profile == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar & Header Card
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(
                              0xFFE07A5F,
                            ).withValues(alpha: 0.25),
                            child: Text(
                              profile.initials,
                              style: const TextStyle(
                                color: Color(0xFFD66A50),
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ).animate().fadeIn().scale(),
                          const SizedBox(height: 14),
                          Text(
                            profile.displayName,
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ).animate().fadeIn(delay: 100.ms),
                          Text(
                            '@${profile.username}',
                            style: const TextStyle(
                              color: Color(0xFF806A63),
                              fontSize: 13,
                            ),
                          ).animate().fadeIn(delay: 150.ms),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Academic Info Cards
                    Text(
                      'Academic Profile',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ...[
                      if (profile.college.isNotEmpty)
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'College',
                          value: profile.college,
                        ),
                      if (profile.branch.isNotEmpty)
                        _InfoRow(
                          icon: Icons.code_rounded,
                          label: 'Branch',
                          value: profile.branch,
                        ),
                      if (profile.year != null)
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Year',
                          value: 'Year ${profile.year}',
                        ),
                      if (profile.bio.isNotEmpty)
                        _InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Bio',
                          value: profile.bio,
                        ),
                    ].asMap().entries.map(
                      (e) => e.value.animate().fadeIn(
                        delay: Duration(milliseconds: 200 + e.key * 60),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Settings Section
                    Text(
                      'App & Account Settings',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 12),

                    _SettingSwitchTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Study Notifications & Reminders',
                      subtitle: 'Get alerts for due tasks and room activity',
                      value: _notificationsEnabled,
                      onChanged: (val) =>
                          setState(() => _notificationsEnabled = val),
                    ),
                    const SizedBox(height: 10),

                    _SettingActionTile(
                      icon: Icons.feedback_outlined,
                      title: 'Submit Feedback',
                      subtitle: 'Help us improve StudySpace',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback feature coming soon! 🚀'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    _SettingActionTile(
                      icon: Icons.lock_reset_rounded,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () => context.go('/reset-password'),
                    ),
                    const SizedBox(height: 10),
                    _SettingActionTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About the app',
                      subtitle: 'Learn about StudySpace and its features',
                      onTap: () => context.push('/about'),
                    ),
                    const SizedBox(height: 10),
                    _SettingActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy policy',
                      subtitle: 'How your account and study data are handled',
                      onTap: () => context.push('/privacy'),
                    ),
                    const SizedBox(height: 28),

                    // Sign out button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFF87171),
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await context.read<AuthProvider>().signOut();
                          if (context.mounted) context.go('/');
                        },
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'StudySpace v1.0.22 • Build 23',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE07A5F), Color(0xFFF2CC8F)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE07A5F).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 42)),
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 16),
          const Text(
            'Guest Mode Active',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You are exploring StudySpace as a Guest. Sign in to unlock full cloud sync, unlimited AI queries, private study rooms, and PDF tools!',
            style: TextStyle(
              color: Color(0xFF806A63),
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE07A5F),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.login_rounded, color: AppColors.textPrimary),
              label: const Text(
                'Sign In to Account',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: () => context.go('/login'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD66A50)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.person_add_rounded,
                color: Color(0xFFD66A50),
              ),
              label: const Text(
                'Create New Account',
                style: TextStyle(
                  color: Color(0xFFD66A50),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: () => context.go('/register'),
            ),
          ),

          const SizedBox(height: 36),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'App Information',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SettingActionTile(
            icon: Icons.info_outline_rounded,
            title: 'About StudySpace',
            subtitle: 'Academic productivity suite & peer collaboration hub',
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 10),
          _SettingActionTile(
            icon: Icons.shield_outlined,
            title: 'Privacy & Security',
            subtitle: 'End-to-end encrypted storage & Supabase backend',
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: 30),
          const Text(
            'StudySpace v1.0.22',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8D4C4)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFD66A50), size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF806A63), fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SettingSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE8D4C4)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFFD66A50), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF806A63), fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: const Color(0xFFD66A50),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _SettingActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8D4C4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD66A50), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF806A63),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: Color(0xFF64748B),
            size: 14,
          ),
        ],
      ),
    ),
  );
}
