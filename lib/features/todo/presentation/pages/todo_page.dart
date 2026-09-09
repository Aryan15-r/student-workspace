import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/todo_provider.dart';
import '../../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/add_task_sheet.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

import '../../../auth/providers/auth_provider.dart';
import '../../../../shared/widgets/login_prompt_dialog.dart';

/// Route: /todo
class TodoPage extends StatefulWidget {
  const TodoPage({super.key});
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTasks();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openAddTask() {
    final auth = context.read<AuthProvider>();
    final todo = context.read<TodoProvider>();

    if (auth.isGuest && todo.tasks.length >= 3) {
      LoginPromptDialog.show(
        context,
        featureName: 'To-Do Lists',
        customMessage:
            'Guest mode is limited to 3 tasks. Please sign in to create unlimited tasks, set reminders, and sync across devices!',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFFCF8).withValues(alpha: 0.8),
          title: Text(
            'Task & Study Tracker',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: const Color(0xFFD66A50),
            labelColor: const Color(0xFFD66A50),
            unselectedLabelColor: const Color(0xFF806A63),
            isScrollable: true,
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: '📊 Activity Stats'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddTask,
          backgroundColor: const Color(0xFFE07A5F),
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Task',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Consumer<TodoProvider>(
          builder: (context, todo, _) {
            if (todo.isLoading && todo.tasks.isEmpty)
              return const LoadingWidget(message: 'Loading tasks...');
            if (todo.error != null && todo.tasks.isEmpty)
              return AppErrorWidget(
                message: todo.error!,
                onRetry: todo.loadTasks,
              );

            return Column(
              children: [
                if (auth.isGuest)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE07A5F).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE07A5F).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFD66A50),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest Mode: ${todo.tasks.length} of 3 tasks used.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: const Color(0xFFD66A50),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => LoginPromptDialog.show(
                            context,
                            featureName: 'To-Do Lists',
                            customMessage:
                                'Sign in to unlock unlimited task management and cloud sync!',
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFFD66A50),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Interactive Horizontal Date Strip Calendar ────────
                Container(
                  height: 84,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: const Color(0xFFFFFCF8).withValues(alpha: 0.4),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final day = DateTime.now().add(Duration(days: index - 2));
                      final isSelected =
                          day.year == _selectedDate.year &&
                          day.month == _selectedDate.month &&
                          day.day == _selectedDate.day;
                      final isToday =
                          day.year == DateTime.now().year &&
                          day.month == DateTime.now().month &&
                          day.day == DateTime.now().day;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFE07A5F),
                                      Color(0xFFF2CC8F),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : const Color(0xFFF7EBDD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFD66A50)
                                  : (isToday
                                        ? const Color(
                                            0xFFD66A50,
                                          ).withValues(alpha: 0.5)
                                        : const Color(0xFFE8D4C4)),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _weekdayName(day.weekday),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF806A63),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isToday
                                            ? const Color(0xFFD66A50)
                                            : Colors.white),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      // Today's Tasks
                      _TaskList(
                        tasks: todo.todayTasks,
                        emptyTitle: 'No tasks due today 🎉',
                        emptySubtitle: 'Enjoy your day or add new study goals!',
                      ),
                      // Upcoming Tasks
                      _TaskList(
                        tasks: todo.pendingTasks,
                        emptyTitle: 'No upcoming tasks',
                        emptySubtitle:
                            'Tap + to schedule upcoming study sessions',
                      ),
                      // Completed Tasks
                      _TaskList(
                        tasks: todo.completedTasks,
                        emptyTitle: 'Nothing completed yet',
                        emptySubtitle:
                            'Complete tasks to build your activity streak!',
                      ),
                      // Activity Stats
                      _ActivityStatsView(todo: todo),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String emptyTitle, emptySubtitle;
  const _TaskList({
    required this.tasks,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.check_circle_outline_rounded,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: tasks.length,
      itemBuilder: (context, i) => TaskCard(task: tasks[i])
          .animate()
          .fadeIn(delay: Duration(milliseconds: i * 50))
          .slideY(begin: 0.1, end: 0),
    );
  }
}

class _ActivityStatsView extends StatelessWidget {
  final TodoProvider todo;
  const _ActivityStatsView({required this.todo});

  @override
  Widget build(BuildContext context) {
    final total = todo.tasks.length;
    final done = todo.completedTasks.length;
    final pending = todo.pendingTasks.length;
    final percent = total > 0 ? (done / total * 100).toStringAsFixed(0) : '0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Activity & Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Overview Cards
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Tasks',
                  value: '$total',
                  icon: Icons.format_list_bulleted_rounded,
                  color: const Color(0xFFD66A50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Completed',
                  value: '$done',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Pending',
                  value: '$pending',
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Completion Rate',
                  value: '$percent%',
                  icon: Icons.pie_chart_rounded,
                  color: const Color(0xFFC084FC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Productivity Streak Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8F4F3A), Color(0xFFB85C38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD66A50).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Study Streak Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep completing daily tasks to maintain your study focus!',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBDD).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D4C4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(color: Color(0xFF806A63), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
