import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';

class StudyToolsPage extends StatefulWidget {
  const StudyToolsPage({super.key});
  @override
  State<StudyToolsPage> createState() => _StudyToolsPageState();
}

class _StudyToolsPageState extends State<StudyToolsPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();
  Duration _remaining = const Duration(minutes: 25);
  bool _running = false;
  DateTime? _startedAt;
  int _focusedSeconds = 0;
  DateTime _lastInteraction = DateTime.now();
  DateTime? _lastReminder;
  static const int _dailyGoalSeconds = 75 * 60;
  final List<TimeOfDay> _alarms = [];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        if (_running) {
          final elapsed = _now.difference(_startedAt ?? _now).inSeconds;
          _remaining = _remaining - Duration(seconds: elapsed);
          _startedAt = _now;
          _focusedSeconds += elapsed;
          if (_remaining <= Duration.zero) {
            _remaining = Duration.zero;
            _running = false;
          }
        }
      });
      _checkInactivity();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _duration(Duration d) =>
      '${_two(d.inMinutes)}:${_two(d.inSeconds % 60)}';

  void _checkInactivity() {
    if (!mounted || !_running) return;
    final inactive = DateTime.now().difference(_lastInteraction);
    if (inactive.inMinutes >= 5 &&
        (_lastReminder == null ||
            DateTime.now().difference(_lastReminder!).inMinutes >= 5)) {
      _lastReminder = DateTime.now();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Still studying? Take a breath or interact to keep your focus session active.',
          ),
        ),
      );
    }
  }

  void _interacted() {
    _lastInteraction = DateTime.now();
    _lastReminder = null;
  }

  Future<void> _editTimer() async {
    final minutes = TextEditingController(
      text: _remaining.inMinutes.toString(),
    );
    final seconds = TextEditingController(
      text: (_remaining.inSeconds % 60).toString().padLeft(2, '0'),
    );
    final result = await showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set focus time'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: minutes,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minutes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: seconds,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Seconds'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(minutes.text) ?? 0;
              final s = int.tryParse(seconds.text) ?? 0;
              if (m == 0 && s == 0) return;
              Navigator.pop(context, Duration(minutes: m, seconds: s));
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
    minutes.dispose();
    seconds.dispose();
    if (result != null && mounted)
      setState(() {
        _remaining = result;
        _running = false;
        _startedAt = null;
        _interacted();
      });
  }

  Future<void> _addAlarm() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) setState(() => _alarms.add(picked));
  }

  @override
  Widget build(BuildContext context) => AdaptiveScaffold(
    selectedIndex: 8,
    child: Listener(
      onPointerDown: (_) => _interacted(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus & Rhythm'),
          actions: [
            IconButton(
              onPressed: _addAlarm,
              icon: const Icon(Icons.alarm_add_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Make time for what matters.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'A gentle command centre for your study day.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _Panel(
              icon: Icons.schedule_rounded,
              title: 'Local time',
              child: Text(
                '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}',
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              icon: Icons.timer_rounded,
              title: 'Focus timer',
              child: Column(
                children: [
                  Text(
                    _duration(_remaining),
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _editTimer,
                        icon: const Icon(Icons.edit_rounded),
                        tooltip: 'Set custom time',
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _remaining = const Duration(minutes: 25);
                          _running = false;
                          _startedAt = null;
                        }),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                      FilledButton.icon(
                        onPressed: () => setState(() {
                          _running = !_running;
                          _startedAt = _running ? DateTime.now() : null;
                          _interacted();
                        }),
                        icon: Icon(
                          _running
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(_running ? 'Pause' : 'Start'),
                      ),
                      IconButton(
                        onPressed: () => setState(
                          () => _remaining += const Duration(minutes: 5),
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Panel(
              icon: Icons.alarm_rounded,
              title: 'Study alarms',
              child: _alarms.isEmpty
                  ? const Text(
                      'No alarms yet. Add one for your next study block.',
                    )
                  : Wrap(
                      spacing: 8,
                      children: _alarms
                          .map(
                            (a) => Chip(
                              label: Text(a.format(context)),
                              onDeleted: () =>
                                  setState(() => _alarms.remove(a)),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _Panel(
              icon: Icons.insights_rounded,
              title: 'Today\'s study tracker',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_focusedSeconds ~/ 60}m ${_focusedSeconds % 60}s focused',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (_focusedSeconds / _dailyGoalSeconds).clamp(
                      0.0,
                      1.0,
                    ),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.accent,
                    backgroundColor: AppColors.card,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goal: 75 minutes  •  ${(_focusedSeconds / _dailyGoalSeconds * 100).clamp(0, 100).toStringAsFixed(0)}% complete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Panel({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );
}
