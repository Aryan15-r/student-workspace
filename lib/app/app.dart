import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
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
  Timer? _attendanceTimer;

  @override
  void initState() {
    super.initState();
    // Create the router, passing it the AuthProvider so it can redirect
    _appRouter = AppRouter(context.read<AuthProvider>());

    // Mark attendance if user stays for 10 minutes
    _attendanceTimer = Timer(const Duration(minutes: 10), () {
      if (mounted) {
        context.read<DashboardProvider>().markAttendance(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _attendanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudySpace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: _appRouter.router,
    );
  }
}
