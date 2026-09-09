import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';

// ── Feature Providers ─────────────────────────────────────────────────────────
import 'features/auth/providers/auth_provider.dart';
import 'features/todo/providers/todo_provider.dart';
import 'features/ai_assistant/providers/ai_provider.dart';
import 'features/search/providers/search_provider.dart';
import 'features/community/providers/community_provider.dart';
import 'features/calculator/providers/calculator_provider.dart';
import 'features/pdf_tools/providers/pdf_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/dashboard/providers/dashboard_provider.dart';
import 'features/study_tools/providers/study_tools_provider.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// main.dart — Entry point of StudySpace
///
/// Steps:
///   1. Load .env file (Supabase URL, keys, etc.)
///   2. Initialize Supabase client
///   3. Wrap the app in all Providers
///   4. Run the app
/// ─────────────────────────────────────────────────────────────────────────────
Future<void> main() async {
  // Required before using async code in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Step 1: Load environment variables from the .env asset file
  await dotenv.load(fileName: '.env');

  // Step 2: Initialize the Supabase client
  // The URL and key come from .env — never hardcoded!
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // Step 3: Run the app wrapped in all our state providers
  runApp(
    MultiProvider(
      providers: [
        // Auth is first — everything depends on it
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // Feature providers
        ChangeNotifierProvider(create: (_) => TodoProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => CalculatorProvider()),
        ChangeNotifierProvider(create: (_) => PdfProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => StudyToolsProvider()),
      ],
      child: const StudySpaceApp(),
    ),
  );
}
