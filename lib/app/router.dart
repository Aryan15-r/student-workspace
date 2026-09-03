import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/presentation/pages/landing_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/otp_verification_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/todo/presentation/pages/todo_page.dart';
import '../features/ai_assistant/presentation/pages/ai_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/community/presentation/pages/community_list_page.dart';
import '../features/community/presentation/pages/channel_list_page.dart';
import '../features/community/presentation/pages/chat_page.dart';
import '../features/calculator/presentation/pages/calculator_page.dart';
import '../features/pdf_tools/presentation/pages/pdf_tools_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';

import '../core/widgets/error_landing_page.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppRouter — Centralized routing for StudySpace
///
/// Uses GoRouter with auth redirect:
///   - Unauthenticated users → /  (landing page)
///   - Authenticated users trying to visit / or /login → /dashboard
/// ─────────────────────────────────────────────────────────────────────────────
class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    redirect: _redirect,
    routes: _routes,
    errorBuilder: (context, state) => ErrorLandingPage(state: state),
  );

  // ── Redirect logic ──────────────────────────────────────────────────────────
  String? _redirect(BuildContext context, GoRouterState state) {
    // Still loading the initial auth state — don't redirect yet
    if (!authProvider.initialized) return null;

    final isAuth      = authProvider.isAuthenticated;
    final location    = state.matchedLocation;

    // Pages that don't require login
    final isPublicPage = location == '/' ||
        location == '/login' ||
        location == '/signup' ||
        location == '/forgot-password' ||
        location.startsWith('/verify-otp');

    // Not logged in and trying to access a protected page → go to landing
    if (!isAuth && !isPublicPage) return '/';

    // Already logged in and trying to visit a public page → go to dashboard
    if (isAuth && isPublicPage) return '/dashboard';

    // No redirect needed
    return null;
  }

  // ── Route definitions ───────────────────────────────────────────────────────
  List<RouteBase> get _routes => [
    // ── Public routes (no auth required) ────────────────────────────────────
    GoRoute(path: '/',                builder: (context, state) => const LandingPage()),
    GoRoute(path: '/login',           builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup',          builder: (context, state) => const SignupPage()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordPage()),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) => OtpVerificationPage(
        email: state.extra as String? ?? (state.uri.queryParameters['email'] ?? ''),
      ),
    ),

    // ── Protected routes (require auth) ─────────────────────────────────────
    GoRoute(path: '/dashboard',   builder: (context, state) => const DashboardPage()),
    GoRoute(path: '/todo',        builder: (context, state) => const TodoPage()),
    GoRoute(path: '/ai',          builder: (context, state) => const AiPage()),
    GoRoute(path: '/search',      builder: (context, state) => const SearchPage()),
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityListPage(),
      routes: [
        GoRoute(
          path: ':communityId',
          builder: (context, state) => ChannelListPage(
            communityId: state.pathParameters['communityId']!,
          ),
          routes: [
            GoRoute(
              path: 'channel/:channelId',
              builder: (context, state) => ChatPage(
                channelId: state.pathParameters['channelId']!,
                communityId: state.pathParameters['communityId']!,
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(path: '/calculator',  builder: (context, state) => const CalculatorPage()),
    GoRoute(path: '/pdf-tools',   builder: (context, state) => const PdfToolsPage()),
    GoRoute(path: '/profile',     builder: (context, state) => const ProfilePage()),
  ];
}
