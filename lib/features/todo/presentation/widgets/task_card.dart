import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task.dart';
import '../../providers/todo_provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/extensions.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final todo = context.read<TodoProvider>();
    final catColor = AppColors.forCategory(task.category);
    final priColor = AppColors.forPriority(task.priority);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
      ),
      onDismissed: (_) => todo.deleteTask(task.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: GestureDetector(
            onTap: () => todo.toggleTask(task.id, !task.completed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.completed
                    ? AppColors.success.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: task.completed ? AppColors.success : AppColors.border,
                  width: 2,
                ),
              ),
              child: task.completed
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 14,
                    )
                  : null,
            ),
          ),
          title: Text(
            task.title,
            style: AppTextStyles.titleMedium.copyWith(
              decoration: task.completed ? TextDecoration.lineThrough : null,
              color: task.completed
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Chip(label: task.category.titleCase, color: catColor),
                  _Chip(label: task.priority.capitalized, color: priColor),
                  if (task.dueDate != null)
                    _Chip(
                      label: task.dueDate!.dueDateLabel,
                      color: task.dueDate!.isOverdue
                          ? AppColors.error
                          : AppColors.textMuted,
                      icon: Icons.calendar_today_outlined,
                    ),
                  if (task.dueTime != null)
                    _Chip(
                      label: task.dueTime!,
                      color: AppColors.primary,
                      icon: Icons.access_time_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Chip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
