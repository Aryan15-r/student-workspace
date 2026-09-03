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

    return AdaptiveScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Greeting ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()}, $name 👋', style: AppTextStyles.headlineLarge)
                          .animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 4),
                      Text("Let's make today productive.", style: AppTextStyles.tagline.copyWith(fontSize: 14))
                          .animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // ── Quick Tools ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Tools', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 14),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.85,
                        children: [
                          _QuickTool(emoji: '🤖', label: 'AI',       route: '/ai',          delay: 0),
                          _QuickTool(emoji: '🔍', label: 'Search',   route: '/search',      delay: 50),
                          _QuickTool(emoji: '🧮', label: 'Calc',     route: '/calculator',  delay: 100),
                          _QuickTool(emoji: '📄', label: 'PDF',      route: '/pdf-tools',   delay: 150),
                          _QuickTool(emoji: '✅', label: 'To-Do',    route: '/todo',        delay: 200),
                          _QuickTool(emoji: '💬', label: 'Community',route: '/community',   delay: 250),
                          _QuickTool(emoji: '👤', label: 'Profile',  route: '/profile',     delay: 300),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // ── Today's Tasks ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text("Today's Tasks", style: AppTextStyles.titleLarge),
                        const Spacer(),
                        TextButton(onPressed: () => context.go('/todo'), child: const Text('See all')),
                      ]),
                      const SizedBox(height: 10),
                      if (dashboard.todayTasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                          child: Row(children: [
                            const Text('🎉', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('No tasks due today!', style: AppTextStyles.titleMedium),
                              Text('Enjoy your free time or plan ahead.', style: AppTextStyles.bodySmall),
                            ]),
                          ]),
                        )
                      else
                        ...dashboard.todayTasks.asMap().entries.map((e) => TaskCard(task: e.value).animate().fadeIn(delay: Duration(milliseconds: e.key * 60))),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),

              // ── Feature Cards ─────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  delegate: SliverChildListDelegate([
                    _FeatureCard(emoji: '🤖', title: 'AI Assistant', subtitle: 'Ask me anything', color: AppColors.secondary, route: '/ai'),
                    _FeatureCard(emoji: '💬', title: 'Community', subtitle: 'Join discussions', color: AppColors.accent, route: '/community'),
                    _FeatureCard(emoji: '🔍', title: 'Smart Search', subtitle: 'Find resources', color: AppColors.success, route: '/search'),
                    _FeatureCard(emoji: '📄', title: 'PDF Tools', subtitle: 'Convert files', color: AppColors.warning, route: '/pdf-tools'),
                  ]),
                ),
              ),
            ],
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
    return GestureDetector(
      onTap: () => context.go(route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 52, maxHeight: 52),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ).animate().fadeIn(delay: Duration(milliseconds: delay + 200)).scale(begin: const Offset(0.85, 0.85)),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji, title, subtitle, route;
  final Color color;
  const _FeatureCard({required this.emoji, required this.title, required this.subtitle, required this.color, required this.route});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(title,    style: AppTextStyles.titleMedium),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ]),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
