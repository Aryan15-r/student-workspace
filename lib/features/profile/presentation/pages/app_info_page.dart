import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';

/// Readable in-app legal and product information, available before and after
/// login.
class AppInfoPage extends StatelessWidget {
  final bool isPrivacy;
  const AppInfoPage.about({super.key}) : isPrivacy = false;
  const AppInfoPage.privacy({super.key}) : isPrivacy = true;

  @override
  Widget build(BuildContext context) {
    final sections = isPrivacy ? _privacySections : _aboutSections;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(isPrivacy ? 'Privacy Policy' : 'About StudySpace'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            isPrivacy ? 'Your privacy matters' : 'StudySpace',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPrivacy
                ? 'Last updated: September 2026'
                : 'Your all-in-one student productivity workspace.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          for (final section in sections) ...[
            Text(
              section.$1,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.$2,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

const _aboutSections = <(String, String)>[
  (
    'What it does',
    'StudySpace brings tasks, focus tracking, study alarms, AI help, resources, PDF tools, and student communities into one place.',
  ),
  (
    'Your study data',
    'When you sign in, your tracker and attendance data are securely synced so they can be restored on another device or after reinstalling the app.',
  ),
  ('Version', 'StudySpace is currently version 1.0.34.'),
];

const _privacySections = <(String, String)>[
  (
    'Information we use',
    'We use the name and email address provided by your account, plus the profile details and study data you choose to save, to operate the app.',
  ),
  (
    'How study data is stored',
    'Signed-in study tracker progress and attendance are stored in your private cloud account. Local storage is used as a fast offline copy. Guest-mode data stays only on that device.',
  ),
  (
    'Who can access it',
    'Your private tasks and study-tracker records are protected by account-level access rules. Public community posts can be seen by other community users.',
  ),
  (
    'Your choices',
    'You can edit your profile or sign out at any time. Clearing app storage removes the local copy; sign in again to restore cloud-synced tracker data.',
  ),
];
