/// ─────────────────────────────────────────────────────────────────────────────
/// AppConstants — App-wide constant values
///
/// Put any magic strings, numbers, or configuration here.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  // ── App Info ───────────────────────────────────────────────────────────────
  static const String appName    = 'StudySpace';
  static const String appTagline = 'One workspace. Less switching. More learning.';
  static const String appVersion = '1.0.0';

  // ── AI ─────────────────────────────────────────────────────────────────────
  /// Google Gemini REST API base URL
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';

  /// System prompt that shapes the AI's personality
  static const String aiSystemPrompt = '''
You are StudySpace AI, a friendly and intelligent study assistant for college students.

You help students with:
- Explaining concepts clearly and simply
- Summarizing long texts
- Creating study plans and schedules
- Answering academic questions across subjects
- Explaining programming concepts with examples
- Helping brainstorm project and presentation ideas
- Generating revision questions for any topic
- Helping organize notes

Guidelines:
- Be encouraging and supportive
- Use simple, clear language — avoid unnecessary jargon
- Give concrete examples when explaining concepts
- If asked to do homework *for* a student (not explain it), gently redirect to explaining the concept instead
- Keep responses concise unless the student asks for more detail
- Use bullet points and numbered lists for clarity
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
- "source": the website name (e.g. "YouTube", "MDN", "Khan Academy")

Prioritize: free resources, beginner-friendly explanations, trusted sources (YouTube, MDN, W3Schools, Khan Academy, GeeksForGeeks, Coursera free, FreeCodeCamp, Wikipedia).

Return ONLY a valid JSON array. No extra text, no markdown, just the JSON array.
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

  // ── Breakpoints (for responsive layout) ───────────────────────────────────
  static const double mobileBreakpoint  = 600;   // below = mobile → bottom nav
  static const double tabletBreakpoint  = 1024;  // below = tablet → nav rail
  // above tabletBreakpoint = desktop/web → sidebar

  // ── Search History ─────────────────────────────────────────────────────────
  static const int maxSearchHistory = 20; // Keep last 20 searches

  // ── Community ─────────────────────────────────────────────────────────────
  static const int messagesPageSize = 50; // Load 50 messages at a time

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast   = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow   = Duration(milliseconds: 500);
}
