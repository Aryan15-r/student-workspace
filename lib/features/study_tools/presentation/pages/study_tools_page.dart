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
  final List<TimeOfDay> _alarms = [];

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
        if (_running && _remaining > Duration.zero)
          _remaining -= const Duration(seconds: 1);
      });
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
                      onPressed: () => setState(() {
                        _remaining = const Duration(minutes: 25);
                        _running = false;
                      }),
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                    FilledButton.icon(
                      onPressed: () => setState(() => _running = !_running),
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
                            onDeleted: () => setState(() => _alarms.remove(a)),
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
                const Text(
                  '25 minutes focused',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.35,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.accent,
                  backgroundColor: AppColors.card,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Goal: 75 minutes  •  Keep going, you are building momentum.',
                ),
              ],
            ),
          ),
        ],
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
