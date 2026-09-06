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

class _TodoPageState extends State<TodoPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    // Load tasks when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTasks();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  void _openAddTask() {
    final auth = context.read<AuthProvider>();
    final todo = context.read<TodoProvider>();

    if (auth.isGuest && todo.tasks.length >= 3) {
      LoginPromptDialog.show(
        context,
        featureName: 'To-Do Lists',
        customMessage: 'Guest mode is limited to 3 tasks. Please sign in to create unlimited tasks, set reminders, and sync across devices!',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const AddTaskSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AdaptiveScaffold(
      selectedIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('To-Do', style: AppTextStyles.headlineSmall),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [Tab(text: 'Pending'), Tab(text: 'Done')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddTask,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Task'),
        ),
        body: Consumer<TodoProvider>(
          builder: (context, todo, _) {
            if (todo.isLoading && todo.tasks.isEmpty) return const LoadingWidget(message: 'Loading tasks...');
            if (todo.error != null && todo.tasks.isEmpty) return AppErrorWidget(message: todo.error!, onRetry: todo.loadTasks);

            return Column(
              children: [
                if (auth.isGuest)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Guest Mode: ${todo.tasks.length} of 3 tasks used.',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => LoginPromptDialog.show(
                            context,
                            featureName: 'To-Do Lists',
                            customMessage: 'Sign in to unlock unlimited task management and cloud sync!',
                          ),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      // Pending tasks
                      _TaskList(tasks: todo.pendingTasks, emptyTitle: 'No pending tasks', emptySubtitle: 'Tap + to add your first task 🎉'),
                      // Completed tasks
                      _TaskList(tasks: todo.completedTasks, emptyTitle: 'Nothing completed yet', emptySubtitle: 'Complete a task to see it here'),
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
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final String emptyTitle, emptySubtitle;
  const _TaskList({required this.tasks, required this.emptyTitle, required this.emptySubtitle});

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
          .animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.1, end: 0),
    );
  }
}
