import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../../../core/errors/app_exception.dart';

/// Handles all Supabase database operations for tasks.
class TodoRepository {
  final _db = Supabase.instance.client;

  Future<List<Task>> fetchTasks(String userId) async {
    try {
      final data = await _db
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((m) => Task.fromMap(m)).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Task> createTask(Task task) async {
    try {
      final data = await _db
          .from('tasks')
          .insert(task.toInsertMap())
          .select()
          .single();
      return Task.fromMap(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _db.from('tasks').update(updates).eq('id', taskId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _db.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> toggleComplete(String taskId, bool completed) async {
    await updateTask(taskId, {'completed': completed});
  }
}
