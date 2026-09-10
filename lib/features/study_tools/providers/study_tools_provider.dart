import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
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

  StreamSubscription<AuthState>? _authSub;

  Future<void> _init() async {
    Permission.scheduleExactAlarm.request();
    Permission.notification.request();
    
    await _loadFromStorage();
    _isInitialized = true;
    
    // Listen to native alarms
    // ignore: deprecated_member_use
    Alarm.ringStream.stream.listen((alarmSettings) {
      if (alarmSettings.id == 1) {
        _showAlarmDialog('Focus Timer', 'Time is up! Take a break.', isTimer: true);
      } else {
        final h = (alarmSettings.id ~/ 100).toString().padLeft(2, '0');
        final m = (alarmSettings.id % 100).toString().padLeft(2, '0');
        _showAlarmDialog('Study Alarm', 'It is $h:$m! Time to focus.');
      }
    });

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadFromStorage().then((_) {
          if (hasListeners) notifyListeners();
        });
      }
    });
    
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
    
    final targetEnd = _now.add(_remaining);
    final alarmSettings = AlarmSettings(
      id: 1, // Focus timer ID
      dateTime: targetEnd,
      assetAudioPath: 'assets/alarm.mp3',
      volumeSettings: const VolumeSettings.fixed(volume: 0.8),
      notificationSettings: NotificationSettings(
        title: 'Focus Timer',
        body: 'Time is up! Take a break.',
      ),
      loopAudio: true,
      vibrate: true,
    );
    Alarm.set(alarmSettings: alarmSettings);
    
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void pauseTimer() {
    _running = false;
    _startedAt = null;
    Alarm.stop(1); // Stop native focus timer
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
    Alarm.stop(1);
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void setCustomRemaining(Duration duration) {
    _remaining = duration;
    _running = false;
    _startedAt = null;
    Alarm.stop(1);
    registerInteraction();
    _saveToStorage();
    notifyListeners();
  }

  void addMinutes(int minutes) {
    _remaining += Duration(minutes: minutes);
    if (_running) {
       Alarm.stop(1);
       final targetEnd = DateTime.now().add(_remaining);
       final alarmSettings = AlarmSettings(
         id: 1,
         dateTime: targetEnd,
         assetAudioPath: 'assets/alarm.mp3',
         volumeSettings: const VolumeSettings.fixed(volume: 0.8),
         notificationSettings: NotificationSettings(
           title: 'Focus Timer',
           body: 'Time is up! Take a break.',
         ),
         loopAudio: true,
         vibrate: true,
       );
       Alarm.set(alarmSettings: alarmSettings);
    }
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
      
      final now = DateTime.now();
      var alarmTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      if (alarmTime.isBefore(now)) alarmTime = alarmTime.add(const Duration(days: 1));
      
      final id = time.hour * 100 + time.minute;
      final alarmSettings = AlarmSettings(
        id: id,
        dateTime: alarmTime,
        assetAudioPath: 'assets/alarm.mp3',
        volumeSettings: const VolumeSettings.fixed(volume: 0.8),
        notificationSettings: NotificationSettings(
          title: 'Study Alarm',
          body: 'Time to focus!',
        ),
        loopAudio: true,
        vibrate: true,
      );
      Alarm.set(alarmSettings: alarmSettings);
      
      _saveToStorage();
      notifyListeners();
    }
  }

  void removeAlarm(TimeOfDay time) {
    _alarms.remove(time);
    final id = time.hour * 100 + time.minute;
    Alarm.stop(id);
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
      
      // Sync to Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final date = DateTime.now();
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        try {
          await Supabase.instance.client.from('user_daily_stats').upsert({
            'user_id': user.id,
            'date': dateStr,
            'focused_seconds': _focusedSeconds,
          }, onConflict: 'user_id, date');
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _focusedSeconds = prefs.getInt('timer_focused_seconds') ?? 0;
      
      // Sync from Supabase if available
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final date = DateTime.now();
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        try {
          final data = await Supabase.instance.client.from('user_daily_stats')
              .select('focused_seconds').eq('user_id', user.id).eq('date', dateStr).maybeSingle();
          if (data != null && data['focused_seconds'] != null) {
            final remoteSeconds = data['focused_seconds'] as int;
            if (remoteSeconds > _focusedSeconds) {
              _focusedSeconds = remoteSeconds;
            }
          }
        } catch (_) {}
      }

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
    _authSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }
}
