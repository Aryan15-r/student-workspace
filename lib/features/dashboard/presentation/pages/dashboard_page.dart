import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../todo/presentation/widgets/task_card.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Route: /dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DashboardProvider>().load());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final name      = auth.profile?.displayName.split(' ').first ?? 'Student';
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return AdaptiveScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: CustomScrollView(
                slivers: [
                  // ── Greeting Header ─────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${_greeting()}, $name 👋', style: AppTextStyles.headlineLarge)
                                        .animate().fadeIn(duration: 500.ms).slideX(begin: -0.04, end: 0),
                                    const SizedBox(height: 6),
                                    Text("Let's make today productive and achieve your goals.",
                                        style: AppTextStyles.tagline.copyWith(fontSize: 14))
                                        .animate().fadeIn(delay: 100.ms),
                                  ],
                                ),
                              ),
                              if (isDesktop)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn(delay: 150.ms),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── AI Banner ────────────────────────────────────────
                          GestureDetector(
                            onTap: () => context.go('/ai'),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Center(
                                      child: Text('🤖', style: TextStyle(fontSize: 26)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'StudySpace AI Tutor',
                                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Ask about study routines, recursion, physics equations, and exam notes',
                                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
                          const SizedBox(height: 28),

                          // ── Quick Tools Title ─────────────────────────────────
                          Text('Quick Tools', style: AppTextStyles.titleLarge),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),

                  // ── Quick Tools Grid (Compact & Responsive) ─────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        mainAxisExtent: 100,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      delegate: SliverChildListDelegate([
                        _QuickTool(emoji: '🤖', label: 'AI Tutor',   route: '/ai',          delay: 0),
                        _QuickTool(emoji: '🔍', label: 'Search',     route: '/search',      delay: 40),
                        _QuickTool(emoji: '🧮', label: 'Calculator', route: '/calculator',  delay: 80),
                        _QuickTool(emoji: '📄', label: 'PDF Tools',  route: '/pdf-tools',   delay: 120),
                        _QuickTool(emoji: '✅', label: 'To-Do',      route: '/todo',        delay: 160),
                        _QuickTool(emoji: '💬', label: 'Community', route: '/community',   delay: 200),
                        _QuickTool(emoji: '👤', label: 'Profile',    route: '/profile',     delay: 240),
                      ]),
                    ),
                  ),

                  // ── Today's Tasks Header ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                      child: Row(
                        children: [
                          Text("Today's Tasks", style: AppTextStyles.titleLarge),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.go('/todo'),
                            child: const Text('See All Tasks →'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Today's Tasks List ──────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: dashboard.todayTasks.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Text('🎉', style: TextStyle(fontSize: 32)),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('No tasks due today!', style: AppTextStyles.titleMedium),
                                      const SizedBox(height: 2),
                                      Text('Enjoy your free time or plan ahead for the week.', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: dashboard.todayTasks
                                  .asMap()
                                  .entries
                                  .map((e) => TaskCard(task: e.value).animate().fadeIn(delay: Duration(milliseconds: e.key * 60)))
                                  .toList(),
                            ),
                    ),
                  ),

                  // ── Explore Modules Hub ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
                      child: Text('Explore Modules', style: AppTextStyles.titleLarge),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 280,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.5,
                      ),
                      delegate: SliverChildListDelegate([
                        _FeatureCard(emoji: '🤖', title: 'AI Assistant', subtitle: 'Academic tutor & coding helper', color: AppColors.secondary, route: '/ai'),
                        _FeatureCard(emoji: '💬', title: 'Student Community', subtitle: 'Chat in subject channels', color: AppColors.accent, route: '/community'),
                        _FeatureCard(emoji: '🔍', title: 'Smart Search', subtitle: 'Find academic papers & docs', color: AppColors.success, route: '/search'),
                        _FeatureCard(emoji: '📄', title: 'PDF Tools', subtitle: 'Merge & convert study notes', color: AppColors.warning, route: '/pdf-tools'),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTool extends StatelessWidget {
  final String emoji, label, route;
  final int delay;
  const _QuickTool({required this.emoji, required this.label, required this.route, required this.delay});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay + 100)).scale(begin: const Offset(0.9, 0.9));
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji, title, subtitle, route;
  final Color color;
  const _FeatureCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}
