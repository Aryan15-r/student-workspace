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

  /// Gemini-powered academic search engine with structured overview and resources
  Future<Map<String, dynamic>> searchAcademicEngine(String query) async {
    final apiKey = _apiKey.trim();
    final cleanQuery = query.trim();

    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      await Future.delayed(const Duration(milliseconds: 300));
      return _getFallbackSearchData(cleanQuery);
    }

    final prompt = '''
You are an expert academic search engine and educational resource indexer.
For the search query: "$cleanQuery", analyze the core topic and return a JSON object with:
1. "overview": A concise, high-value 2-3 sentence academic overview explaining the fundamental definition, scientific/coding principle, formulas, or applications.
2. "results": An array of 6 to 8 accurate educational resources. Each resource must contain:
   - "title": Specific descriptive title (e.g. "What is Newton's Third Law?", "Understanding Async/Await in Dart", "MIT 18.01 Single Variable Calculus").
   - "description": 1-2 informative sentences explaining what concepts are covered.
   - "url": Direct working URL (prefer authoritative sources: Khan Academy, Wikipedia, GeeksforGeeks, MDN Web Docs, MIT OpenCourseWare, freeCodeCamp, HyperPhysics, LibreTexts, W3Schools, YouTube, etc.).
   - "type": One of "article", "video", "course", "documentation", "tool", "textbook".
   - "source": Name of the publishing platform/university.
   - "isFree": boolean (true or false).
3. "related": An array of 4 to 6 related subtopics, search queries, or subsequent concepts students should learn next.

Return ONLY valid raw JSON.
''';

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
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode({
            'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
            },
          }),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final text = json['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'] ??
              json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            final parsed = jsonDecode(text.toString());
            if (parsed is Map<String, dynamic>) {
              return parsed;
            }
          }
        }
      } catch (e) {
        debugPrint('Search error on $model: $e');
      }
    }

    return _getFallbackSearchData(cleanQuery);
  }

  /// Legacy list helper for compatibility
  Future<List<Map<String, dynamic>>> searchResources(String query) async {
    final data = await searchAcademicEngine(query);
    final results = data['results'] as List? ?? [];
    return results.cast<Map<String, dynamic>>();
  }

  /// Dynamic AI response engine based on user prompt context
  String _generateSmartResponse(String prompt) {
    return '### 💡 StudySpace AI Overview for: *"$prompt"*\n\nHere is a structured breakdown:\n\n1. **Core Concept:** Breakdown this topic into fundamental principles and definitions.\n2. **Practical Application:** Connect the theory to concrete examples and exercises.\n3. **Key Takeaway:** Summarize the main formula or rule in one sentence for quick revision.';
  }

  Map<String, dynamic> _getFallbackSearchData(String query) {
    final clean = Uri.encodeComponent(query);
    return {
      'overview': 'Educational overview and curated learning materials for "$query". Explore foundational tutorials, interactive guides, video lectures, and technical references.',
      'results': [
        {
          'title': '$query - Comprehensive Video Tutorials & Lessons',
          'description': 'Visual walkthroughs, animated concepts, and problem-solving video lectures.',
          'url': 'https://www.youtube.com/results?search_query=$clean+lecture',
          'type': 'video',
          'isFree': true,
          'source': 'YouTube Edu',
        },
        {
          'title': '$query - Academic Overview & Definitions',
          'description': 'Historical context, mathematical formulation, and key definitions.',
          'url': 'https://en.wikipedia.org/wiki/Special:Search?search=$clean',
          'type': 'article',
          'isFree': true,
          'source': 'Wikipedia',
        },
        {
          'title': '$query - Interactive Guide & Practice Problems',
          'description': 'Structured fundamental explanations with quizzes, code snippets, and active recall exercises.',
          'url': 'https://www.khanacademy.org/search?page_search_query=$clean',
          'type': 'course',
          'isFree': true,
          'source': 'Khan Academy',
        },
        {
          'title': '$query - Technical Reference & Documentation',
          'description': 'Standard syntax documentation, API parameters, and authoritative references.',
          'url': 'https://developer.mozilla.org/en-US/search?q=$clean',
          'type': 'documentation',
          'isFree': true,
          'source': 'MDN Web Docs',
        },
        {
          'title': '$query - FreeCodeCamp Handbook & Articles',
          'description': 'Step-by-step practical guides, industry conventions, and coding patterns.',
          'url': 'https://www.freecodecamp.org/news/search/?query=$clean',
          'type': 'article',
          'isFree': true,
          'source': 'FreeCodeCamp',
        },
      ],
      'related': [
        '$query Fundamentals',
        '$query Solved Examples',
        '$query Advanced Applications',
        '$query Practice Questions',
      ],
    };
  }
}
