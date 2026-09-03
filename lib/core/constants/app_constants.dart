/// ─────────────────────────────────────────────────────────────────────────────
/// AppConstants — App-wide constant values
/// ─────────────────────────────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName    = 'StudySpace';
  static const String appTagline = 'One workspace. Less switching. More learning.';
  static const String appVersion = '1.0.0';

  // ── AI ─────────────────────────────────────────────────────────────────────
  /// Google Gemini REST API endpoint
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// System prompt that shapes the AI's personality
  static const String aiSystemPrompt = '''
You are StudySpace AI, an encouraging and intelligent academic assistant for college students.

You assist students with:
- Explaining concepts clearly and simply
- Answering programming, math, physics, and science questions
- Summarizing topics and creating study roadmaps
- Providing revision questions and flashcard concepts

Keep formatting clean with Markdown headers, bullet points, and code snippets when appropriate.
''';

  /// System prompt for the search/resource finder
  static const String searchSystemPrompt = '''
You are a study resource finder for college students. When given a search query, respond with 6 high-quality educational resources in valid JSON format only.

Each resource must have:
- "title": short descriptive title
- "description": 1-2 sentences about what this resource covers
- "url": a real, working URL
- "type": one of "video", "article", "course", "documentation", "tool", "website"
- "isFree": true or false
- "source": the website name (e.g. "YouTube", "MDN", "Khan Academy", "GeeksforGeeks")

Return ONLY a valid JSON array.
''';

  // ── Task Categories ────────────────────────────────────────────────────────
  static const List<String> taskCategories = [
    'assignment',
    'exam',
    'project',
    'personal',
    'college',
  ];

  static const List<String> taskPriorities = ['low', 'medium', 'high'];

  // ── Breakpoints ───────────────────────────────────────────────────────────
  static const double mobileBreakpoint  = 600;
  static const double tabletBreakpoint  = 1024;
}
