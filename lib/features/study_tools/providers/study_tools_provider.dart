import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/router.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StudyToolsProvider — Global timer & focus state management
///
/// Keeps the focus timer running continuously in memory across tab switching
/// and persists state to SharedPreferences so it survives page reloads.
/// ─────────────────────────────────────────────────────────────────────────────
class StudyToolsProvider extends ChangeNotifier {
  Timer? _ticker;

  DateTime _now = DateTime.now();
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;
  DateTime? _startedAt;
  int _focusedSeconds = 0;
  DateTime _lastInteraction = DateTime.now();
  DateTime? _lastReminder;
  final List<TimeOfDay> _alarms = [];
  bool _isInitialized = false;

  static const int dailyGoalSeconds = 75 * 60;

  // ── Getters ────────────────────────────────────────────────────────────────
  DateTime get now => _now;
  Duration get remaining => _remaining;
  bool get running => _running;
  int get focusedSeconds => _focusedSeconds;
  List<TimeOfDay> get alarms => List.unmodifiable(_alarms);
  bool get isInitialized => _isInitialized;
  DateTime get lastInteraction => _lastInteraction;
  DateTime? get lastReminder => _lastReminder;

  StudyToolsProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadFromStorage();
    _isInitialized = true;
    _startTicker();
    notifyListeners();
  }

  void _showAlarmDialog(String title, String message, {bool isTimer = false, TimeOfDay? alarm}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.alarm_rounded, color: Color(0xFFD66A50)),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (isTimer) {
                setCustomRemaining(const Duration(minutes: 5));
                startTimer();
              } else if (alarm != null) {
                final snoozed = TimeOfDay(
                  hour: (alarm.hour + (alarm.minute + 5) ~/ 60) % 24,
                  minute: (alarm.minute + 5) % 60,
                );
                addAlarm(snoozed);
                removeAlarm(alarm);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Snooze (5m)'),
          ),
          FilledButton(
            onPressed: () {
              if (alarm != null) {
                removeAlarm(alarm);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Turn Off'),
          ),
        ],
      ),
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();

      if (_running) {
        final elapsed = _now.difference(_startedAt ?? _now).inSeconds;
        final tracked = elapsed > _remaining.inSeconds
            ? _remaining.inSeconds
            : elapsed;

        if (tracked > 0) {
          _remaining = _remaining - Duration(seconds: tracked);
          _startedAt = _now;
          _focusedSeconds += tracked;

          if (_remaining <= Duration.zero) {
            _remaining = Duration.zero;
            _running = false;
            _startedAt = null;
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.heavyImpact();
            _showAlarmDialog('Focus Timer', 'Time is up! Take a break.', isTimer: true);
          }
          _saveToStorage();
        }
      }

      if (_now.second == 0) {
        for (final alarm in _alarms.toList()) {
          if (alarm.hour == _now.hour && alarm.minute == _now.minute) {
            SystemSound.play(SystemSoundType.alert);
            HapticFeedback.heavyImpact();
            
            final timeStr = '${alarm.hour.toString().padLeft(2, '0')}:${alarm.minute.toString().padLeft(2, '0')}';
            _showAlarmDialog('Study Alarm', 'It is $timeStr! Time to focus.', alarm: alarm);
          }
        }
      }

      notifyListeners();
    });
  }

  // ── Timer Actions ──────────────────────────────────────────────────────────
  void startTimer() {
    _running = true;
    _startedAt = DateTime.now();
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void pauseTimer() {
    _running = false;
    _startedAt = null;
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void toggleTimer() {
    if (_running) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void resetTimer([Duration defaultDuration = const Duration(minutes: 25)]) {
    _running = false;
    _startedAt = null;
    _remaining = defaultDuration;
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void setCustomRemaining(Duration duration) {
    _remaining = duration;
    _running = false;
    _startedAt = null;
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void addMinutes(int minutes) {
    _remaining += Duration(minutes: minutes);
    _saveToStorage();
    notifyListeners();
  }

  void registerInteraction() {
    _lastInteraction = DateTime.now();
    _lastReminder = null;
  }

  void setLastReminder(DateTime reminder) {
    _lastReminder = reminder;
  }

  // ── Alarm Actions ──────────────────────────────────────────────────────────
  void addAlarm(TimeOfDay time) {
    if (!_alarms.contains(time)) {
      _alarms.add(time);
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeAlarm(TimeOfDay time) {
    _alarms.remove(time);
    _saveToStorage();
    notifyListeners();
  }

  // ── Storage Persistence ────────────────────────────────────────────────────
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('timer_remaining_seconds', _remaining.inSeconds);
      await prefs.setBool('timer_is_running', _running);
      await prefs.setInt('timer_focused_seconds', _focusedSeconds);

      if (_running && _startedAt != null) {
        final targetEnd = _now.add(_remaining);
        await prefs.setInt('timer_target_end_ms', targetEnd.millisecondsSinceEpoch);
      } else {
        await prefs.remove('timer_target_end_ms');
      }

      final alarmStrings = _alarms
          .map((a) => '${a.hour.toString().padLeft(2, '0')}:${a.minute.toString().padLeft(2, '0')}')
          .toList();
      await prefs.setStringList('timer_alarms', alarmStrings);
    } catch (_) {}
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusedSeconds = prefs.getInt('timer_focused_seconds') ?? 0;

      final isRunningSaved = prefs.getBool('timer_is_running') ?? false;
      final targetEndMs = prefs.getInt('timer_target_end_ms');
      final remainingSecs = prefs.getInt('timer_remaining_seconds');

      if (isRunningSaved && targetEndMs != null) {
        final targetEnd = DateTime.fromMillisecondsSinceEpoch(targetEndMs);
        final diff = targetEnd.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          _remaining = Duration(seconds: diff);
          _running = true;
          _startedAt = DateTime.now();
        } else {
          _remaining = Duration.zero;
          _running = false;
          _startedAt = null;
        }
      } else if (remainingSecs != null) {
        _remaining = Duration(seconds: remainingSecs);
        _running = false;
      }

      final alarmStrings = prefs.getStringList('timer_alarms') ?? [];
      _alarms.clear();
      for (final s in alarmStrings) {
        final parts = s.split(':');
        if (parts.length == 2) {
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h != null && m != null) {
            _alarms.add(TimeOfDay(hour: h, minute: m));
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
