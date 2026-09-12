import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/adaptive_scaffold.dart';
import '../../providers/quiz_provider.dart';

class QuizGeneratorPage extends StatefulWidget {
  const QuizGeneratorPage({super.key});

  @override
  State<QuizGeneratorPage> createState() => _QuizGeneratorPageState();
}

class _QuizGeneratorPageState extends State<QuizGeneratorPage> {
  final TextEditingController _topicController = TextEditingController();

  void _showCreateDialog(BuildContext context) {
    double questionCount = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate AI Quiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic (e.g., World War II)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Questions:'),
                  Text('${questionCount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: questionCount,
                min: 3,
                max: 20,
                divisions: 17,
                label: questionCount.toInt().toString(),
                onChanged: (val) => setDialogState(() => questionCount = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final topic = _topicController.text.trim();
                if (topic.isNotEmpty) {
                  Navigator.pop(ctx);
                  final provider = context.read<QuizProvider>();
                  final quiz = await provider.generateQuiz(topic, count: questionCount.toInt());
                if (quiz != null && mounted) {
                  context.push('/quizzes/take/${quiz.id}');
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to generate quiz.')),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final quizzes = provider.quizzes;

    return AdaptiveScaffold(
      selectedIndex: 7,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/study-tools'),
          ),
          title: const Text('AI Quizzes'),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : quizzes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No Quizzes Generated Yet',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () => _showCreateDialog(context),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Quiz'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(quiz.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${quiz.questions.length} questions • Score: ${quiz.score != null ? '${quiz.score}/${quiz.questions.length}' : 'Not taken'}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (quiz.score == null)
                                IconButton(
                                  icon: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                                  onPressed: () => context.push('/quizzes/take/${quiz.id}'),
                                )
                              else
                                const Icon(Icons.check_circle_rounded, color: Colors.green),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => provider.deleteQuiz(quiz.id),
                              ),
                            ],
                          ),
                          onTap: quiz.score == null ? () => context.push('/quizzes/take/${quiz.id}') : null,
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('AI Quiz'),
        ),
      ),
    );
  }
}
