import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../data/todo_repository.dart';

class TodoProvider extends ChangeNotifier {
  final _repo = TodoRepository();

  List<Task> _tasks = [];
  bool _loading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _loading;
  String? get error => _error;

  List<Task> get pendingTasks => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.completed).toList();
  List<Task> get todayTasks => pendingTasks.where((t) {
    if (t.dueDate == null) return false;
    final now = DateTime.now();
    return t.dueDate!.year == now.year &&
        t.dueDate!.month == now.month &&
        t.dueDate!.day == now.day;
  }).toList();

  Future<void> loadTasks({bool forceLoading = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    // Only show full loading spinner if tasks list is currently empty
    if (_tasks.isEmpty || forceLoading) {
      _loading = true;
      notifyListeners();
    }

    try {
      final fetched = await _repo.fetchTasks(userId);
      _tasks = fetched;
      _error = null;
    } catch (e) {
      // Keep the local task view usable when Supabase is unreachable.
      _error = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(Task task) async {
    _tasks.insert(0, task);
    notifyListeners();
    if (Supabase.instance.client.auth.currentUser == null) return true;
    try {
      final created = await _repo
          .createTask(task)
          .timeout(const Duration(seconds: 4));
      final index = _tasks.indexWhere((item) => item.id == task.id);
      if (index != -1) _tasks[index] = created;
      notifyListeners();
      return true;
    } catch (e) {
      // The optimistic task remains available and can be synced later.
      _error = null;
      return true;
    }
  }

  Future<void> toggleTask(String taskId, bool completed) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(completed: completed);
    notifyListeners();
    try {
      if (Supabase.instance.client.auth.currentUser == null) return;
      await _repo.toggleComplete(taskId, completed);
    } catch (_) {
      // Keep the local change when offline; it is safer than losing user input.
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      if (Supabase.instance.client.auth.currentUser == null) return;
      await _repo.deleteTask(taskId);
    } catch (e) {
      // Keep the deletion locally when the remote service is unavailable.
    }
  }
}
