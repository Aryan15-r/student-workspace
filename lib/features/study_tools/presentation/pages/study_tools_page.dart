import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../providers/study_tools_provider.dart';

class StudyToolsPage extends StatelessWidget {
  const StudyToolsPage({super.key});

  String _two(int n) => n.toString().padLeft(2, '0');
  String _duration(Duration d) =>
      '${_two(d.inMinutes)}:${_two(d.inSeconds % 60)}';

  Future<void> _editTimer(BuildContext context, StudyToolsProvider provider) async {
    final remaining = provider.remaining;
    final minutes = TextEditingController(
      text: remaining.inMinutes.toString(),
    );
    final seconds = TextEditingController(
      text: (remaining.inSeconds % 60).toString().padLeft(2, '0'),
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
    if (result != null) {
      provider.setCustomRemaining(result);
    }
  }

  Future<void> _addAlarm(BuildContext context, StudyToolsProvider provider) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      provider.addAlarm(picked);
    }
  }

  void _checkInactivity(BuildContext context, StudyToolsProvider provider) {
    if (!provider.running) return;
    final inactive = DateTime.now().difference(provider.lastInteraction);
    if (inactive.inMinutes >= 5 &&
        (provider.lastReminder == null ||
            DateTime.now().difference(provider.lastReminder!).inMinutes >= 5)) {
      provider.setLastReminder(DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Still studying? Take a breath or interact to keep your focus session active.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudyToolsProvider>();
    final now = provider.now;
    final remaining = provider.remaining;
    final running = provider.running;
    final focusedSeconds = provider.focusedSeconds;
    final alarms = provider.alarms;

    _checkInactivity(context, provider);

    return AdaptiveScaffold(
      selectedIndex: 8,
      child: Listener(
        onPointerDown: (_) => provider.registerInteraction(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Focus & Rhythm'),
            actions: [
              IconButton(
                onPressed: () => _addAlarm(context, provider),
                icon: const Icon(Icons.alarm_add_rounded),
                tooltip: 'Add alarm',
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
                  '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}',
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
                      _duration(remaining),
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
                          onPressed: () => _editTimer(context, provider),
                          icon: const Icon(Icons.edit_rounded),
                          tooltip: 'Set custom time',
                        ),
                        IconButton(
                          onPressed: () => provider.resetTimer(),
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Reset to 25m',
                        ),
                        FilledButton.icon(
                          onPressed: () => provider.toggleTimer(),
                          icon: Icon(
                            running
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(running ? 'Pause' : 'Start'),
                        ),
                        IconButton(
                          onPressed: () => provider.addMinutes(5),
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Add 5 minutes',
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
                child: alarms.isEmpty
                    ? const Text(
                        'No alarms yet. Add one for your next study block.',
                      )
                    : Wrap(
                        spacing: 8,
                        children: alarms
                            .map(
                              (a) => Chip(
                                label: Text(a.format(context)),
                                onDeleted: () => provider.removeAlarm(a),
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
                      '${focusedSeconds ~/ 60}m ${focusedSeconds % 60}s focused',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (focusedSeconds / StudyToolsProvider.dailyGoalSeconds).clamp(
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
                      'Goal: 75 minutes  •  ${(focusedSeconds / StudyToolsProvider.dailyGoalSeconds * 100).clamp(0, 100).toStringAsFixed(0)}% complete',
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
}

class _Panel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Panel({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
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
}
