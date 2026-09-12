import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ai_assistant/services/ai_service.dart';
import '../models/quiz.dart';

class QuizProvider extends ChangeNotifier {
  static const String _storageKey = 'quizzes';
  List<Quiz> _quizzes = [];
  bool _isLoading = false;
  final AiService _aiService = AiService();

  List<Quiz> get quizzes => _quizzes;
  bool get isLoading => _isLoading;

  QuizProvider() {
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _quizzes = jsonList.map((e) => Quiz.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading quizzes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonStr = json.encode(_quizzes.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('Error saving quizzes: $e');
    }
  }

  Future<void> saveQuizScore(String quizId, int score) async {
    final index = _quizzes.indexWhere((q) => q.id == quizId);
    if (index != -1) {
      _quizzes[index] = _quizzes[index].copyWith(score: score);
      await _saveQuizzes();
      notifyListeners();
    }
  }

  Future<void> deleteQuiz(String id) async {
    _quizzes.removeWhere((quiz) => quiz.id == id);
    await _saveQuizzes();
    notifyListeners();
  }

  /// AI Generation
  Future<Quiz?> generateQuiz(String topic, {int count = 5}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final rawQuiz = await _aiService.generateQuiz(topic, count: count);
      if (rawQuiz.isNotEmpty && rawQuiz.containsKey('questions')) {
        final title = rawQuiz['title'] ?? 'Quiz on $topic';
        final List<dynamic> rawQuestions = rawQuiz['questions'];
        final questions = rawQuestions.map((q) => QuizQuestion.fromMap(q)).toList();
        
        final quiz = Quiz(title: title, questions: questions);
        _quizzes.insert(0, quiz); // Add to top
        await _saveQuizzes();
        return quiz;
      }
    } catch (e) {
      debugPrint('Error generating quiz: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
