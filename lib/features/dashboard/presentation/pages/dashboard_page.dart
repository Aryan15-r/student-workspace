import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/dashboard_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../todo/presentation/widgets/task_card.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/app_colors.dart';

/// Route: /dashboard — Ultra-Modern Student Dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DashboardProvider>().load(),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final dashboard = context.watch<DashboardProvider>();
    final name = auth.profile?.displayName.split(' ').first ?? 'Student';
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return AdaptiveScaffold(
      selectedIndex: 0,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        body: SafeArea(
          child: Stack(
            children: [
              // Ambient glowing background accent orbs
              Positioned(
                top: -60,
                right: -60,
                child:
                    Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFE07A5F,
                            ).withValues(alpha: 0.12),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 4000.ms,
                        ),
              ),
              Positioned(
                top: 250,
                left: -80,
                child:
                    Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFF2CC8F,
                            ).withValues(alpha: 0.08),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1.1, 1.1),
                          end: const Offset(0.9, 0.9),
                          duration: 5000.ms,
                        ),
              ),

              Center(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                                  '${_greeting()}, $name',
                                                  style: AppTextStyles
                                                      .headlineLarge
                                                      .copyWith(
                                                        color: AppColors.textPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                )
                                                .animate()
                                                .fadeIn(duration: 500.ms)
                                                .slideX(begin: -0.04, end: 0),
                                            const SizedBox(width: 8),
                                            const Text(
                                                  '👋',
                                                  style: TextStyle(
                                                    fontSize: 26,
                                                  ),
                                                )
                                                .animate(
                                                  onPlay: (c) =>
                                                      c.repeat(reverse: true),
                                                )
                                                .rotate(
                                                  begin: -0.05,
                                                  end: 0.05,
                                                  duration: 1200.ms,
                                                ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "One workspace. Less switching. More learning.",
                                          style: TextStyle(
                                            color: const Color(0xFF806A63),
                                            fontSize: 14,
                                          ),
                                        ).animate().fadeIn(delay: 100.ms),
                                      ],
                                    ),
                                  ),
                                  if (isDesktop)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFF7EBDD,
                                        ).withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: const Color(0xFFE8D4C4),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_rounded,
                                            size: 16,
                                            color: Color(0xFFD66A50),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ).animate().fadeIn(delay: 150.ms),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // ── AI Tutor Hero Banner ──────────────────────────────
                              GestureDetector(
                                    onTap: () => context.go('/ai'),
                                    child: Container(
                                      padding: const EdgeInsets.all(22),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF8F4F3A),
                                            Color(0xFFB85C38),
                                            Color(0xFFC96B52),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: const Color(
                                            0xFFD66A50,
                                          ).withValues(alpha: 0.4),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFE07A5F,
                                            ).withValues(alpha: 0.25),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '🤖',
                                                style: TextStyle(fontSize: 28),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Text(
                                                      'StudySpace AI Tutor',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(
                                                      Icons
                                                          .auto_awesome_rounded,
                                                      color: Color(0xFFE07A5F),
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Instant problem solver, zero-downtime model cascade, copy prompt ready',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: const BoxDecoration(
                                              color: AppColors.card,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: AppColors.textPrimary,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(delay: 200.ms)
                                  .slideY(begin: 0.08, end: 0),
                              const SizedBox(height: 28),

                              // ── Quick Tools Header ───────────────────────────
                              Text(
                                'Quick Tools & Utilities',
                                style: AppTextStyles.headlineMedium,
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),

                      // ── Quick Tools Grid ─────────────────────────────
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 135,
                                mainAxisExtent: 105,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          delegate: SliverChildListDelegate([
                            _QuickTool(
                              emoji: '🤖',
                              label: 'AI Tutor',
                              route: '/ai',
                              delay: 0,
                            ),
                            _QuickTool(
                              emoji: '📄',
                              label: 'PDF Tools',
                              route: '/pdf-tools',
                              delay: 40,
                            ),
                            _QuickTool(
                              emoji: '✅',
                              label: 'To-Do',
                              route: '/todo',
                              delay: 80,
                            ),
                            _QuickTool(
                              emoji: '💬',
                              label: 'Community',
                              route: '/community',
                              delay: 120,
                            ),
                            _QuickTool(
                              emoji: '🧮',
                              label: 'Calculator',
                              route: '/calculator',
                              delay: 160,
                            ),
                            _QuickTool(
                              emoji: '🔍',
                              label: 'Search',
                              route: '/search',
                              delay: 200,
                            ),
                            _QuickTool(
                              emoji: '👤',
                              label: 'Profile',
                              route: '/profile',
                              delay: 240,
                            ),
                          ]),
                        ),
                      ),

                      // ── Attendance Calendar ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                          child: Text(
                            "Attendance Tracker",
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE8D4C4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TableCalendar(
                              firstDay: DateTime.utc(2023, 1, 1),
                              lastDay: DateTime.utc(2030, 12, 31),
                              focusedDay: DateTime.now(),
                              calendarFormat: CalendarFormat.week,
                              availableCalendarFormats: const {
                                CalendarFormat.month: 'Month',
                                CalendarFormat.twoWeeks: '2 Weeks',
                                CalendarFormat.week: 'Week',
                              },
                              headerStyle: const HeaderStyle(
                                formatButtonVisible: false,
                                titleCentered: true,
                                titleTextStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                defaultBuilder: (context, day, focusedDay) => _buildCalCell(day, dashboard),
                                todayBuilder: (context, day, focusedDay) => _buildCalCell(day, dashboard, isToday: true),
                                outsideBuilder: (context, day, focusedDay) => _buildCalCell(day, dashboard, isOutside: true),
                                disabledBuilder: (context, day, focusedDay) => _buildCalCell(day, dashboard, isOutside: true),
                              ),
                            ),
                          ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.05, end: 0),
                        ),
                      ),

                      // ── Today's Tasks Header ────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
                          child: Row(
                            children: [
                              Text(
                                "Today's Tasks",
                                style: AppTextStyles.headlineMedium,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => context.go('/todo'),
                                child: const Text(
                                  'See All Tasks →',
                                  style: TextStyle(
                                    color: Color(0xFFD66A50),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
                                    color: const Color(
                                      0xFFF7EBDD,
                                    ).withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE8D4C4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text(
                                        '🎉',
                                        style: TextStyle(fontSize: 34),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'No tasks due today!',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'All clear! Enjoy your study break or prepare for exams ahead.',
                                              style: TextStyle(
                                                color: Color(0xFF806A63),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: dashboard.todayTasks
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => TaskCard(task: e.value)
                                            .animate()
                                            .fadeIn(
                                              delay: Duration(
                                                milliseconds: e.key * 60,
                                              ),
                                            ),
                                      )
                                      .toList(),
                                ),
                        ),
                      ),

                      // ── Explore Modules Hub ─────────────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 14),
                          child: Text(
                            'Explore Modules',
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.45,
                              ),
                          delegate: SliverChildListDelegate([
                            _FeatureCard(
                              emoji: '🤖',
                              title: 'AI Assistant',
                              subtitle: 'Academic tutor & coding mentor',
                              color: const Color(0xFFD66A50),
                              route: '/ai',
                            ),
                            _FeatureCard(
                              emoji: '📄',
                              title: 'Document Studio',
                              subtitle: 'View & convert Word, PDF, PPT',
                              color: const Color(0xFFF59E0B),
                              route: '/pdf-tools',
                            ),
                            _FeatureCard(
                              emoji: '💬',
                              title: 'Student Lounge',
                              subtitle: 'Real-time subject chat rooms',
                              color: const Color(0xFF38BDF8),
                              route: '/community',
                            ),
                            _FeatureCard(
                              emoji: '🔍',
                              title: 'Smart Search',
                              subtitle: 'Find academic papers & textbooks',
                              color: const Color(0xFF4ADE80),
                              route: '/search',
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalCell(DateTime date, DashboardProvider dashboard, {bool isToday = false, bool isOutside = false}) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);

    Color? bgColor;
    Color textColor = AppColors.textPrimary;

    if (normalizedDate.isAfter(normalizedToday)) {
      bgColor = Colors.transparent;
      textColor = AppColors.textMuted;
    } else {
      final isPresent = dashboard.attendance[normalizedDate] ?? false;
      bgColor = isPresent ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15);
      textColor = isPresent ? Colors.green[700]! : Colors.red[700]!;
      
      if (isToday) {
        bgColor = isPresent ? Colors.green : Colors.red;
        textColor = Colors.white;
      }
    }

    if (isOutside) {
      textColor = textColor.withValues(alpha: 0.4);
      if (bgColor != Colors.transparent) {
        bgColor = bgColor.withValues(alpha: 0.05);
      }
    }

    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${date.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
}

class _QuickTool extends StatelessWidget {
  final String emoji, label, route;
  final int delay;
  const _QuickTool({
    required this.emoji,
    required this.label,
    required this.route,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A3A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1A2A3A).withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay + 100))
        .scale(begin: const Offset(0.92, 0.92));
  }
}

class _FeatureCard extends StatelessWidget {
  final String emoji, title, subtitle, route;
  final Color color;
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A3A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}
