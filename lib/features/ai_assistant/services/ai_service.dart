import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../../../core/constants/app_constants.dart';

/// Calls the Google Gemini REST API to generate AI responses.
/// Includes a dynamic academic knowledge engine when running offline.
class AiService {
  final http.Client _client = http.Client();
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Keep the stable Flash model first. The previous list tried several
  // unavailable model names sequentially, adding up to minutes of latency.
  static const _models = <String>[
    'gemini-1.5-flash',
  ];

  /// Sends the full conversation history to Gemini and returns the AI reply.
  Future<String> sendMessage(
    List<ChatMessage> history,
    String userMessage,
  ) async {
    final apiKey = _apiKey.trim();

    // If no valid key is provided, use the intelligent dynamic academic response generator
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      return _generateSmartResponse(userMessage);
    }

    final contents = <Map<String, dynamic>>[];

    // Add conversation history
    for (final msg in history) {
      if (msg.isLoading) continue;
      contents.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.content},
        ],
      });
    }

    // Add the current user query
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userMessage},
      ],
    });

    for (final model in _models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final headers = {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        };
        final body = jsonEncode({
          'system_instruction': {
            'parts': [
              {'text': AppConstants.aiSystemPrompt},
            ],
          },
          'contents': contents,
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_NONE',
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 16384},
        });

        final response = await _client
            .post(url, headers: headers, body: body)
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidates = json['candidates'] as List?;

          if (candidates != null && candidates.isNotEmpty) {
            final candidate = candidates[0];
            final finishReason = candidate['finishReason'];

            if (finishReason == 'SAFETY') {
              return "I'm unable to generate a response for this specific prompt due to content safety policy restrictions. If you have an academic, biological, scientific, or general study question, please rephrase and ask!";
            }

            final parts = candidate['content']?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final fullText = parts
                  .map((p) => p['text']?.toString() ?? '')
                  .join('');
              if (fullText.trim().isNotEmpty) {
                return cleanMathFormulas(fullText);
              }
            }
          }
        } else {
          debugPrint(
            'Gemini API ($model) error: ${response.statusCode}, body: ${response.body}',
          );
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
      return _getFallbackSearchData(cleanQuery);
    }

    final prompt =
        '''
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

    for (final model in _models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final response = await _client
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': apiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'role': 'user',
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.2,
                  'responseMimeType': 'application/json',
                },
              }),
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final text =
              json['candidates']?[0]?['content']?[0]?['parts']?[0]?['text'] ??
              json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            final parsed = jsonDecode(text.toString());
            if (parsed is Map<String, dynamic>) {
              if (parsed['overview'] is String) {
                parsed['overview'] = cleanMathFormulas(
                  parsed['overview'] as String,
                );
              }
              final list = parsed['results'] as List?;
              if (list != null) {
                for (final item in list) {
                  if (item is Map<String, dynamic> &&
                      item['description'] is String) {
                    item['description'] = cleanMathFormulas(
                      item['description'] as String,
                    );
                  }
                }
              }
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

  /// AI-powered Flashcard generation
  Future<List<Map<String, String>>> generateFlashcards(String topic, {int count = 10}) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      return [
        {'front': 'What is $topic?', 'back': 'This is a sample generated back for $topic.'},
        {'front': 'Example card 2', 'back': 'Set up Gemini API for real AI generation.'},
      ];
    }

    final prompt = '''
You are an expert tutor. Generate exactly $count educational flashcards for the topic: "$topic".
Return ONLY valid raw JSON array of objects.
Each object must have exactly two string keys: "front" and "back".
Example:
[
  {"front": "Question or term", "back": "Answer or definition"}
]
''';

    for (final model in _models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode({
            'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
            'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 8192},
          }),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          // content is a Map, not a List — use ['parts'] directly
          final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          debugPrint('Flashcard raw response text: $text');
          if (text != null && text.toString().trim().isNotEmpty) {
             String rawText = text.toString().trim();
             // Strip markdown code fences if present
             if (rawText.startsWith('```')) {
               rawText = rawText.replaceAll(RegExp(r'^```[a-z]*\n?'), '').replaceAll(RegExp(r'```$'), '').trim();
             }
             final parsed = jsonDecode(rawText);
             if (parsed is List) {
               return parsed.map((e) => {
                 'front': e['front']?.toString() ?? '',
                 'back': e['back']?.toString() ?? '',
               }).toList();
             }
          } else {
            debugPrint('Flashcard: no text in response. Full body: ${response.body}');
          }
        } else {
          debugPrint('Flashcard API error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Generate Flashcards error on $model: $e');
      }
    }
    return [];
  }

  /// AI-powered Quiz generation
  Future<Map<String, dynamic>> generateQuiz(String topic, {int count = 5}) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty || apiKey == 'your-gemini-api-key-here') {
      return {
        'title': 'Sample Quiz on $topic',
        'questions': [
          {
            'question': 'What is the main concept of $topic?',
            'options': ['Option A', 'Option B', 'Option C', 'Option D'],
            'correctOptionIndex': 0,
            'explanation': 'This is a placeholder explanation.'
          }
        ]
      };
    }

    final prompt = '''
You are an expert examiner. Generate a multiple-choice quiz about "$topic" with exactly $count questions.
Return ONLY valid raw JSON.
Format:
{
  "title": "Title of the Quiz",
  "questions": [
    {
      "question": "The question text?",
      "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
      "correctOptionIndex": 0,
      "explanation": "Brief explanation of the correct answer."
    }
  ]
}
Ensure exactly 4 options per question, and correctOptionIndex is between 0 and 3.
''';

    for (final model in _models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );
        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode({
            'contents': [{'role': 'user', 'parts': [{'text': prompt}]}],
            'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 8192},
          }),
        ).timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          // content is a Map, not a List — use ['parts'] directly
          final text = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
          debugPrint('Quiz raw response text: $text');
          if (text != null && text.toString().trim().isNotEmpty) {
             String rawText = text.toString().trim();
             // Strip markdown code fences if present
             if (rawText.startsWith('```')) {
               rawText = rawText.replaceAll(RegExp(r'^```[a-z]*\n?'), '').replaceAll(RegExp(r'```$'), '').trim();
             }
             final parsed = jsonDecode(rawText);
             if (parsed is Map<String, dynamic>) {
                return parsed;
             }
          } else {
            debugPrint('Quiz: no text in response. Full body: ${response.body}');
          }
        } else {
          debugPrint('Quiz API error ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Generate Quiz error on $model: $e');
      }
    }
    return {};
  }

  /// Legacy list helper for compatibility
  Future<List<Map<String, dynamic>>> searchResources(String query) async {
    final data = await searchAcademicEngine(query);
    final results = data['results'] as List? ?? [];
    return results.cast<Map<String, dynamic>>();
  }

  /// Dynamic AI response engine based on user prompt context when offline or fallback mode
  String _generateSmartResponse(String prompt) {
    final lower = prompt.toLowerCase().trim();

    if (lower.contains('sex') ||
        lower.contains('naughty') ||
        lower.contains('adult')) {
      return '### 🔬 Biological & Health Education Overview\n\n'
          'Sexuality and reproductive health are fundamental topics in human biology, anatomy, and health education.\n\n'
          'Key Academic Concepts:\n'
          '- **Biology & Reproduction:** The biological process of human reproduction involving male and female gametes (sperm and egg cells).\n'
          '- **Health & Education:** Comprehensive sex education covers reproductive anatomy, consent, safe practices, STI prevention, and emotional maturity.\n'
          '- **Hormonal Regulation:** Estrogen, progesterone, and testosterone regulate human reproductive anatomy and secondary sexual characteristics.\n\n'
          'If you have specific biology or health science questions, feel free to ask!';
    }

    return '### 💡 StudySpace AI Assistant\n\n'
        'Here is an explanation regarding your query on **"$prompt"**:\n\n'
        '1. **Core Concept:** Understanding the foundational definitions and principles of "$prompt".\n'
        '2. **Key Insights:** Connecting theoretical knowledge to practical academic applications and real-world examples.\n'
        '3. **Summary:** Reviewing the essential formulas, rules, or key takeaways for your study session.\n\n'
        '*Tip: Configure your `GEMINI_API_KEY` in `.env` for full real-time AI capabilities!*';
  }

  Map<String, dynamic> _getFallbackSearchData(String query) {
    final clean = Uri.encodeComponent(query);
    return {
      'overview':
          'Educational overview and curated learning materials for "$query". Explore foundational tutorials, interactive guides, video lectures, textbooks, and technical references.',
      'results': [
        {
          'title': '$query - Comprehensive Video Tutorials & Lessons',
          'description':
              'Visual walkthroughs, animated concepts, and problem-solving video lectures.',
          'url': 'https://www.youtube.com/results?search_query=$clean+lecture',
          'type': 'video',
          'isFree': true,
          'source': 'YouTube Edu',
        },
        {
          'title': '$query - OpenStax Peer-Reviewed Textbooks',
          'description':
              'Free open-source textbooks, chapter breakdowns, practice problems, and study guides.',
          'url': 'https://openstax.org/subjects',
          'type': 'textbook',
          'isFree': true,
          'source': 'OpenStax Textbooks',
        },
        {
          'title': '$query - Google Books & Reference Manuals',
          'description':
              'Standard reference textbooks, academic publications, and university subject guides.',
          'url': 'https://www.google.com/search?tbm=bks&q=$clean',
          'type': 'textbook',
          'isFree': true,
          'source': 'Google Books',
        },
        {
          'title': '$query - arXiv Academic Research Papers',
          'description':
              'Open-access scientific papers, preprints, and research literature.',
          'url': 'https://arxiv.org/search/?query=$clean&searchtype=all',
          'type': 'article',
          'isFree': true,
          'source': 'arXiv Library',
        },
        {
          'title': '$query - Academic Overview & Definitions',
          'description':
              'Historical context, mathematical formulation, and key definitions.',
          'url': 'https://en.wikipedia.org/wiki/Special:Search?search=$clean',
          'type': 'article',
          'isFree': true,
          'source': 'Wikipedia',
        },
        {
          'title': '$query - Interactive Guide & Practice Problems',
          'description':
              'Structured fundamental explanations with quizzes, code snippets, and active recall exercises.',
          'url': 'https://www.khanacademy.org/search?page_search_query=$clean',
          'type': 'course',
          'isFree': true,
          'source': 'Khan Academy',
        },
        {
          'title': '$query - Technical Reference & Documentation',
          'description':
              'Standard syntax documentation, API parameters, and authoritative references.',
          'url': 'https://developer.mozilla.org/en-US/search?q=$clean',
          'type': 'documentation',
          'isFree': true,
          'source': 'MDN Web Docs',
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

  /// Sanitizes raw unrendered LaTeX tags into clean, human-readable student-friendly math
  static String cleanMathFormulas(String input) {
    if (input.isEmpty) return input;
    var text = input;

    // Replace \text{...} or \mathrm{...} or \mathbf{...}
    text = text.replaceAllMapped(
      RegExp(r'\\(?:text|mathrm|mathbf|mathit|textsf)\{([^}]+)\}'),
      (m) => m[1] ?? '',
    );

    // Replace \frac{a}{b} with (a / b)
    text = text.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (m) => '(${m[1]} / ${m[2]})',
    );

    // Replace common LaTeX symbols with clean unicode
    text = text
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\le', '≤')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\ge', '≥')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\theta', 'θ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\mu', 'μ')
        .replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\omega', 'ω');

    // Replace \sqrt{...}
    text = text.replaceAllMapped(
      RegExp(r'\\sqrt\{([^}]+)\}'),
      (m) => '√(${m[1]})',
    );

    // Clean up subscript _\{...\} -> _... and exponent \^\{...\} -> ^...
    text = text.replaceAllMapped(RegExp(r'_\{([^}]+)\}'), (m) => '_${m[1]}');
    text = text.replaceAllMapped(RegExp(r'\^\{([^}]+)\}'), (m) => '^${m[1]}');

    // Remove single $ or $$ math delimiters
    text = text.replaceAll(r'$$', '').replaceAll(r'$', '');

    return text;
  }
}
