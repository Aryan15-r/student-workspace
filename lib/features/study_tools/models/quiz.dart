import 'dart:convert';
import 'package:uuid/uuid.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex']?.toInt() ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final List<QuizQuestion> questions;
  final int? score;
  final DateTime createdAt;

  Quiz({
    String? id,
    required this.title,
    required this.questions,
    this.score,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Quiz copyWith({
    String? title,
    List<QuizQuestion>? questions,
    int? score,
  }) {
    return Quiz(
      id: id,
      title: title ?? this.title,
      questions: questions ?? this.questions,
      score: score ?? this.score,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'questions': questions.map((x) => x.toMap()).toList(),
      'score': score,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map) {
    return Quiz(
      id: map['id'],
      title: map['title'],
      questions: List<QuizQuestion>.from(map['questions']?.map((x) => QuizQuestion.fromMap(x))),
      score: map['score']?.toInt(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Quiz.fromJson(String source) => Quiz.fromMap(json.decode(source));
}
