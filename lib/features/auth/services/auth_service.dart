import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../../core/errors/app_exception.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthService — Handles all Supabase authentication operations
///
/// The UI never calls Supabase directly.
/// Instead, it calls AuthService, which calls Supabase.
/// This makes it easy to swap auth providers later.
/// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  // Get the Supabase client — this is the connection to our backend
  final _supabase = Supabase.instance.client;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  /// Creates a new account with email, password, and a username.
  /// The Supabase trigger automatically creates the profile row.
  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName ?? '',
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  /// Logs in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Current User ───────────────────────────────────────────────────────────
  /// Returns the currently logged-in Supabase user, or null if not logged in.
  User? get currentUser => _supabase.auth.currentUser;

  /// True if a user is currently logged in
  bool get isAuthenticated => currentUser != null;

  // ── Auth State Stream ──────────────────────────────────────────────────────
  /// A stream that fires whenever the auth state changes
  /// (login, logout, token refresh).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // ── Fetch Profile ──────────────────────────────────────────────────────────
  /// Loads the profile row from Supabase for the given user ID.
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromMap(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Update Profile ─────────────────────────────────────────────────────────
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toMap())
          .eq('id', profile.id);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
