import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../todo/models/task.dart';
import '../../todo/data/todo_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _todoRepo = TodoRepository();
  List<Task> _todayTasks = [];
  bool _loading = false;

  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _loading;

  Future<void> load() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      final all = await _todoRepo.fetchTasks(userId);
      final now = DateTime.now();
      _todayTasks = all
          .where((t) {
            if (t.completed || t.dueDate == null) return false;
            return t.dueDate!.year == now.year &&
                t.dueDate!.month == now.month &&
                t.dueDate!.day == now.day;
          })
          .take(3)
          .toList();
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
