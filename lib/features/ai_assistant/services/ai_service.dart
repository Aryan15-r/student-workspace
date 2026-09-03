import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

/// Calls the Google Gemini REST API to generate AI responses.
/// Includes smart fallback when offline or before API key is configured.
class AiService {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Sends the full conversation history to Gemini and returns the AI reply.
  Future<String> sendMessage(List<ChatMessage> history, String userMessage) async {
    if (_apiKey.isEmpty || _apiKey == 'your-gemini-api-key-here') {
      // Smart offline fallback for instant hackathon demo
      await Future.delayed(const Duration(milliseconds: 600));
      return _getDemoAiResponse(userMessage);
    }

    // Build the conversation history in Gemini's format
    final contents = <Map<String, dynamic>>[];

    // Add system prompt as first user + model exchange
    contents.add({'role': 'user',  'parts': [{'text': AppConstants.aiSystemPrompt}]});
    contents.add({'role': 'model', 'parts': [{'text': 'Understood! I am StudySpace AI, ready to help you study smarter. What would you like to know?'}]});

    // Add conversation history
    for (final msg in history) {
      if (msg.isLoading) continue;
      contents.add({'role': msg.isUser ? 'user' : 'model', 'parts': [{'text': msg.content}]});
    }

    // Add the new user message
    contents.add({'role': 'user', 'parts': [{'text': userMessage}]});

    final url = Uri.parse('${AppConstants.geminiBaseUrl}?key=$_apiKey');
    final body = jsonEncode({'contents': contents, 'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024}});

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['candidates'][0]['content']['parts'][0]['text'] as String;
      } else if (response.statusCode == 400) {
        throw AppException(message: 'Invalid API key. Please check your GEMINI_API_KEY in .env');
      } else {
        return _getDemoAiResponse(userMessage);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      return _getDemoAiResponse(userMessage);
    }
  }

  /// Gemini-powered study resource finder with rich fallback (Option A)
  Future<List<Map<String, dynamic>>> searchResources(String query) async {
    if (_apiKey.isEmpty || _apiKey == 'your-gemini-api-key-here') {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getCuratedResources(query);
    }

    final prompt = '${AppConstants.searchSystemPrompt}\n\nSearch query: "$query"';
    final url = Uri.parse('${AppConstants.geminiBaseUrl}?key=$_apiKey');
    final body = jsonEncode({
      'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1024},
    });

    try {
      final response = await http.post(url, headers: {'Content-Type': 'application/json'}, body: body).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'] as String;
        final jsonStart = text.indexOf('[');
        final jsonEnd   = text.lastIndexOf(']') + 1;
        if (jsonStart != -1 && jsonEnd > 0) {
          final results = jsonDecode(text.substring(jsonStart, jsonEnd)) as List;
          return results.cast<Map<String, dynamic>>();
        }
      }
      return _getCuratedResources(query);
    } catch (_) {
      return _getCuratedResources(query);
    }
  }

  String _getDemoAiResponse(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('recursion')) {
      return '### 🔁 What is Recursion?\n\nRecursion is a technique where a function calls itself to solve smaller instances of the same problem.\n\n**Key Components:**\n1. **Base Case:** Stops infinite loops (e.g. `if (n <= 1) return 1;`)\n2. **Recursive Step:** Calls itself with a smaller input (e.g. `return n * factorial(n - 1);`)\n\n*Tip: Always make sure your base case is reached!*';
    } else if (lower.contains('plan') || lower.contains('exam') || lower.contains('study')) {
      return '### 📅 Recommended Study Strategy\n\n1. **Pomodoro Method:** 25 mins focus + 5 mins break\n2. **Active Recall:** Test yourself instead of passive reading\n3. **Feynman Technique:** Teach the concept out loud in simple terms\n4. **Spaced Repetition:** Review notes on Day 1, Day 3, and Day 7.';
    }
    return 'Here is a quick summary to help you:\n\n- **Core Concept:** Breakdown complex topics into smaller sub-problems.\n- **Application:** Practice with hands-on coding or solving exercises.\n- **Review:** Use flashcards and summarize key takeaways in bullet points.\n\n*(Note: Add your free Google Gemini API key to `.env` for full interactive AI capabilities!)*';
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
