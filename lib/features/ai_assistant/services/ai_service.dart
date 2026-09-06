import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../../../core/constants/app_constants.dart';

/// Calls the Google Gemini REST API to generate AI responses.
/// Includes a dynamic academic knowledge engine when running offline.
class AiService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Sends the full conversation history to Gemini and returns the AI reply.
  Future<String> sendMessage(List<ChatMessage> history, String userMessage) async {
    final apiKey = _apiKey.trim();

    // If no valid key is provided, use the intelligent dynamic academic response generator
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      await Future.delayed(const Duration(milliseconds: 500));
      return _generateSmartResponse(userMessage);
    }

    final contents = <Map<String, dynamic>>[];

    // Add conversation history
    for (final msg in history) {
      if (msg.isLoading) continue;
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [{'text': msg.content}],
      });
    }

    // Add the current user query
    contents.add({
      'role': 'user',
      'parts': [{'text': userMessage}],
    });

    final modelsToTry = [
      'gemini-3.6-flash',
      'gemini-3.7-flash',
      'gemini-3.5-flash',
      'gemini-3.1-flash-lite',
      'gemini-flash-latest',
    ];

    for (final model in modelsToTry) {
      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
        final headers = {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        };
        final body = jsonEncode({
          'system_instruction': {
            'parts': [{'text': AppConstants.aiSystemPrompt}],
          },
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
        });

        final response = await http
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidate = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            return candidate.toString();
          }
        } else {
          debugPrint('Gemini API ($model) error: ${response.statusCode}, body: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini exception ($model): $e');
      }
    }

    return _generateSmartResponse(userMessage);
  }

  /// Gemini-powered study resource finder
  Future<List<Map<String, dynamic>>> searchResources(String query) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      await Future.delayed(const Duration(milliseconds: 400));
      return _getCuratedResources(query);
    }

    final prompt = '${AppConstants.searchSystemPrompt}\n\nSearch query: "$query"';
    final url = Uri.parse('${AppConstants.geminiBaseUrl}?key=$apiKey');
    final body = jsonEncode({
      'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1024},
    });

    try {
      final response = await http
          .post(url, headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey}, body: body)
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          final jsonStart = text.indexOf('[');
          final jsonEnd   = text.lastIndexOf(']') + 1;
          if (jsonStart != -1 && jsonEnd > 0) {
            final results = jsonDecode(text.substring(jsonStart, jsonEnd)) as List;
            return results.cast<Map<String, dynamic>>();
          }
        }
      }
      return _getCuratedResources(query);
    } catch (_) {
      return _getCuratedResources(query);
    }
  }

  /// Dynamic AI response engine based on user prompt context
  String _generateSmartResponse(String prompt) {
    final query = prompt.toLowerCase().trim();

    // ── Greetings ─────────────────────────────────────────────────────────────
    if (RegExp(r'^(hi|hello|hey|greetings|howdy|sup|hola)\b').hasMatch(query)) {
      return '### 👋 Hello! Welcome to StudySpace AI\n\nI am your 24/7 student assistant. I can help you with:\n\n- 📝 **Explaining Concepts:** Coding, Math, Physics, Engineering\n- 📅 **Study Planning:** Exam schedules and daily routines\n- 💡 **Assignment Help:** Breaking down complex problems step-by-step\n- 🔍 **Summarizing:** Turning long articles into concise notes\n\nWhat are you studying today?';
    }

    // ── Recursion & Algorithms ────────────────────────────────────────────────
    if (query.contains('recursion') || query.contains('recursive')) {
      return '### 🔁 Understanding Recursion\n\n**Definition:** Recursion is when a function calls itself to solve smaller sub-problems until reaching a stopping condition.\n\n#### The Two Vital Rules:\n1. **Base Case:** The condition where the function stops (prevents infinite loop/stack overflow).\n2. **Recursive Step:** Modifies the input and calls itself again.\n\n```python\ndef factorial(n):\n    if n <= 1:          # Base Case\n        return 1\n    return n * factorial(n - 1)  # Recursive Step\n```\n\n💡 *Tip: Think of it like Russian nesting dolls — you open each doll until you reach the smallest solid doll!*';
    }

    // ── Object Oriented Programming ──────────────────────────────────────────
    if (query.contains('oop') || query.contains('object oriented') || query.contains('class') || query.contains('inheritance')) {
      return '### 🏛️ The 4 Pillars of OOP\n\n1. **Encapsulation:** Bundling data and methods that operate on that data within a single class.\n2. **Abstraction:** Hiding complex implementation details and showing only the essential interface.\n3. **Inheritance:** Creating new classes that reuse, extend, and modify properties of a parent class.\n4. **Polymorphism:** Allowing different classes to be treated through the same interface (e.g., method overriding).\n\n*Would you like a code example in Python, Java, or C++?*';
    }

    // ── Study Methods & Time Management ──────────────────────────────────────
    if (query.contains('study') || query.contains('exam') || query.contains('focus') || query.contains('routine') || query.contains('plan')) {
      return '### 🎯 High-Yield Study Techniques for College\n\n1. **The Feynman Technique:**\n   - Pick a concept and explain it aloud in plain English as if teaching a 10-year-old.\n   - Identify where your explanation breaks down and review those exact notes.\n\n2. **Active Recall & Spaced Repetition:**\n   - Test yourself before reading the answer. Review intervals: Day 1 → Day 3 → Day 7 → Day 14.\n\n3. **The 50/10 Rule:**\n   - 50 minutes of hyper-focused study (no phone/distractions) + 10 minutes physical break.\n\nWhich subject do you want to create a study plan for?';
    }

    // ── Physics / Math ───────────────────────────────────────────────────────
    if (query.contains('physics') || query.contains('newton') || query.contains('derivative') || query.contains('integral') || query.contains('math')) {
      return '### 📐 Academic Breakdown\n\n- **Formula / Law:** Understand the physical intuition before memorizing formulas.\n- **Units & Dimensional Analysis:** Always check units (kg·m/s² = N) to verify your derivations.\n- **Practice Strategy:** Solve at least 3 solved examples before attempting unassisted homework questions.\n\nFeel free to type the exact equation or problem statement, and we will solve it step by step!';
    }

    // ── General Dynamic Academic Fallback ────────────────────────────────────
    return '### 💡 StudySpace AI Overview for: *"$prompt"*\n\nHere is a structured breakdown:\n\n1. **Core Concept:** Breakdown this topic into fundamental principles and definitions.\n2. **Practical Application:** Connect the theory to concrete examples and exercises.\n3. **Key Takeaway:** Summarize the main formula or rule in one sentence for quick revision.\n\n*(Connect your Google Gemini API Key in `.env` for customized deep explanations!)*';
  }

  List<Map<String, dynamic>> _getCuratedResources(String query) {
    final clean = Uri.encodeComponent(query);
    return [
      {
        'title': '$query - YouTube Tutorials & Video Lectures',
        'description': 'Top-rated video lessons, visual walkthroughs, and crash courses.',
        'url': 'https://www.youtube.com/results?search_query=$clean+tutorial',
        'type': 'video',
        'isFree': true,
        'source': 'YouTube',
      },
      {
        'title': '$query - GeeksforGeeks Explanation & Code',
        'description': 'Detailed article with definitions, diagrams, time complexity, and code examples.',
        'url': 'https://www.geeksforgeeks.org/search/?q=$clean',
        'type': 'article',
        'isFree': true,
        'source': 'GeeksforGeeks',
      },
      {
        'title': '$query - FreeCodeCamp Interactive Guide',
        'description': 'Comprehensive student-friendly handbook and projects.',
        'url': 'https://www.freecodecamp.org/news/search/?query=$clean',
        'type': 'course',
        'isFree': true,
        'source': 'FreeCodeCamp',
      },
      {
        'title': '$query - Khan Academy & MIT OpenCourseWare',
        'description': 'Structured fundamental courses with quizzes and practice exercises.',
        'url': 'https://www.khanacademy.org/search?page_search_query=$clean',
        'type': 'course',
        'isFree': true,
        'source': 'Khan Academy',
      },
      {
        'title': '$query - MDN / Official Documentation',
        'description': 'Authoritative reference documentation, syntax standards, and specifications.',
        'url': 'https://developer.mozilla.org/en-US/search?q=$clean',
        'type': 'documentation',
        'isFree': true,
        'source': 'MDN Web Docs',
      },
      {
        'title': '$query - Wikipedia Academic Overview',
        'description': 'High-level conceptual summary, history, and mathematical foundations.',
        'url': 'https://en.wikipedia.org/wiki/Special:Search?search=$clean',
        'type': 'article',
        'isFree': true,
        'source': 'Wikipedia',
      },
    ];
  }
}
