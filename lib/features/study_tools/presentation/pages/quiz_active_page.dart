import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../providers/quiz_provider.dart';
import '../../models/quiz.dart';

class QuizActivePage extends StatefulWidget {
  final String quizId;
  const QuizActivePage({super.key, required this.quizId});

  @override
  State<QuizActivePage> createState() => _QuizActivePageState();
}

class _QuizActivePageState extends State<QuizActivePage> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;

  void _submitAnswer(Quiz quiz) {
    if (_selectedOptionIndex == null) return;
    
    final question = quiz.questions[_currentIndex];
    final isCorrect = _selectedOptionIndex == question.correctOptionIndex;
    
    setState(() {
      _isAnswered = true;
      if (isCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion(Quiz quiz) {
    if (_currentIndex < quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswered = false;
      });
    } else {
      // Finish quiz
      context.read<QuizProvider>().saveQuizScore(quiz.id, _score);
      _showResultDialog(quiz);
    }
  }

  void _showResultDialog(Quiz quiz) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Quiz Completed!'),
        content: Text('You scored $_score out of ${quiz.questions.length}.', style: const TextStyle(fontSize: 18)),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            child: const Text('Return to Quizzes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final quiz = provider.quizzes.firstWhere((q) => q.id == widget.quizId, orElse: () => Quiz(title: 'Not Found', questions: []));

    if (quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(quiz.title)),
        body: const Center(child: Text('This quiz is empty.')),
      );
    }

    final question = quiz.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${quiz.title} (${_currentIndex + 1}/${quiz.questions.length})'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / quiz.questions.length,
              backgroundColor: AppColors.card,
              color: AppColors.primary,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.question,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedOptionIndex == index;
                      final isCorrectOption = index == question.correctOptionIndex;
                      
                      Color getOptionColor() {
                        if (!_isAnswered) {
                          return isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card;
                        }
                        if (isCorrectOption) {
                          return Colors.green.withValues(alpha: 0.2);
                        }
                        if (isSelected && !isCorrectOption) {
                          return Colors.red.withValues(alpha: 0.2);
                        }
                        return AppColors.card;
                      }

                      BorderSide getBorderSide() {
                        if (!_isAnswered) {
                          return BorderSide(color: isSelected ? AppColors.primary : Colors.transparent, width: 2);
                        }
                        if (isCorrectOption) {
                          return const BorderSide(color: Colors.green, width: 2);
                        }
                        if (isSelected && !isCorrectOption) {
                          return const BorderSide(color: Colors.red, width: 2);
                        }
                        return const BorderSide(color: Colors.transparent);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: _isAnswered ? null : () {
                            setState(() {
                              _selectedOptionIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: getOptionColor(),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.fromBorderSide(getBorderSide()),
                            ),
                            child: Row(
                              children: [
                                Expanded(child: Text(question.options[index], style: const TextStyle(fontSize: 16))),
                                if (_isAnswered && isCorrectOption)
                                  const Icon(Icons.check_circle, color: Colors.green)
                                else if (_isAnswered && isSelected && !isCorrectOption)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    if (_isAnswered) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.menuBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(question.explanation, style: const TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedOptionIndex == null
                      ? null
                      : _isAnswered
                          ? () => _nextQuestion(quiz)
                          : () => _submitAnswer(quiz),
                  child: Text(_isAnswered 
                      ? (_currentIndex == quiz.questions.length - 1 ? 'Finish Quiz' : 'Next Question')
                      : 'Submit Answer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
