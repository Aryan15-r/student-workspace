import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../data/todo_repository.dart';

class TodoProvider extends ChangeNotifier {
  final _repo = TodoRepository();

  List<Task> _tasks    = [];
  bool       _loading  = false;
  String?    _error;

  List<Task> get tasks          => _tasks;
  bool       get isLoading      => _loading;
  String?    get error          => _error;

  List<Task> get pendingTasks   => _tasks.where((t) => !t.completed).toList();
  List<Task> get completedTasks => _tasks.where((t) =>  t.completed).toList();
  List<Task> get todayTasks     => pendingTasks.where((t) {
    if (t.dueDate == null) return false;
    final now = DateTime.now();
    return t.dueDate!.year == now.year && t.dueDate!.month == now.month && t.dueDate!.day == now.day;
  }).toList();

  Future<void> loadTasks({bool forceLoading = false}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
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
      _error = e.toString().replaceAll('AppException: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      final created = await _repo.createTask(task);
      _tasks.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleTask(String taskId, bool completed) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    _tasks[idx] = _tasks[idx].copyWith(completed: completed);
    notifyListeners();
    try {
      await _repo.toggleComplete(taskId, completed);
    } catch (_) {
      // Revert on failure
      _tasks[idx] = _tasks[idx].copyWith(completed: !completed);
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    try {
      await _repo.deleteTask(taskId);
    } catch (e) {
      await loadTasks(); // reload on failure
    }
  }
}
