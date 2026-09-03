import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// StudySpaceApp — Root widget of the application
///
/// Sets up the router (which needs AuthProvider) and applies the dark theme.
/// ─────────────────────────────────────────────────────────────────────────────
class StudySpaceApp extends StatefulWidget {
  const StudySpaceApp({super.key});

  @override
  State<StudySpaceApp> createState() => _StudySpaceAppState();
}

class _StudySpaceAppState extends State<StudySpaceApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    // Create the router, passing it the AuthProvider so it can redirect
    _appRouter = AppRouter(context.read<AuthProvider>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title:              'StudySpace',
      debugShowCheckedModeBanner: false,
      theme:              AppTheme.dark,
      routerConfig:       _appRouter.router,
    );
  }
}
