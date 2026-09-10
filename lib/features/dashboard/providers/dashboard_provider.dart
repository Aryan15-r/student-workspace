import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../todo/models/task.dart';
import '../../todo/data/todo_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _todoRepo = TodoRepository();
  List<Task> _todayTasks = [];
  bool _loading = false;

  // Attendance tracking
  Map<DateTime, bool> _attendance = {};

  List<Task> get todayTasks => _todayTasks;
  bool get isLoading => _loading;
  Map<DateTime, bool> get attendance => _attendance;

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
          
      // Load attendance
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('attendance_'));
      final newAttendance = <DateTime, bool>{};
      for (final key in keys) {
        final dateStr = key.replaceFirst('attendance_', '');
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          newAttendance[date] = prefs.getBool(key) ?? false;
        }
      }
      _attendance = newAttendance;
    } catch (_) {
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
  
  Future<void> toggleAttendance(DateTime date) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final key = 'attendance_${normalizedDate.year}-${normalizedDate.month}-${normalizedDate.day}';
    final prefs = await SharedPreferences.getInstance();
    
    final currentStatus = _attendance[normalizedDate] ?? false;
    final newStatus = !currentStatus;
    
    await prefs.setBool(key, newStatus);
    _attendance[normalizedDate] = newStatus;
    notifyListeners();
  }
}

