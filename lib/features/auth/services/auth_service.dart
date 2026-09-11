import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../../../core/errors/app_exception.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthService — Handles all Supabase authentication operations
/// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final _supabase = Supabase.instance.client;

  // Tracks whether GoogleSignIn.instance.initialize() has been called.
  // It can only be called once per app lifetime.
  static bool _googleSignInInitialized = false;

  // ── Sign Up ────────────────────────────────────────────────────────────────
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
        data: {'username': username, 'full_name': fullName ?? ''},
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Sign In with Password ──────────────────────────────────────────────────
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Sign In with Google ────────────────────────────────────────────────────
  Future<void> signInWithGoogle({
    required String webClientId,
    String? iosClientId,
  }) async {
    try {
      debugPrint('[Google SignIn] Starting — kIsWeb: $kIsWeb');

      if (kIsWeb) {
        // On web: use Supabase OAuth redirect (same as dear-diary React app).
        // No google_sign_in package needed — Supabase handles the Google popup.
        debugPrint('[Google SignIn] Web: using Supabase signInWithOAuth...');
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: '${Uri.base.origin}/',
        );
        // signInWithOAuth redirects the browser; execution stops here on web.
        debugPrint('[Google SignIn] ✅ OAuth redirect initiated.');
        return;
      }

      // Mobile (Android / iOS): native google_sign_in flow
      debugPrint('[Google SignIn] Mobile: using native GoogleSignIn...');
      if (!_googleSignInInitialized) {
        await GoogleSignIn.instance.initialize(
          clientId: iosClientId,
          serverClientId: webClientId,
        );
        _googleSignInInitialized = true;
      }
      debugPrint('[Google SignIn] Initialized. Calling authenticate()...');
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;
      debugPrint('[Google SignIn] idToken present: ${idToken != null}');

      if (idToken == null) {
        throw AppException(message: 'No ID Token found.');
      }

      debugPrint('[Google SignIn] Calling Supabase signInWithIdToken...');
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      debugPrint('[Google SignIn] ✅ Success!');
    } catch (e, st) {
      debugPrint('[Google SignIn] ❌ FAILED: $e');
      debugPrint('[Google SignIn] Stack trace:\n$st');
      if (e is AppException) rethrow;
      throw AppException.from(e, stackTrace: st);
    }
  }

  // ── Send Email OTP ─────────────────────────────────────────────────────────
  Future<void> sendOtp(String email) async {
    try {
      await _supabase.auth.signInWithOtp(email: email);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Verify Email OTP ───────────────────────────────────────────────────────
  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      // First try signup, then recovery, then fallback to magiclink/email type
      try {
        return await _supabase.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.signup,
        );
      } catch (_) {
        try {
          return await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.recovery,
          );
        } catch (_) {
          return await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.magiclink,
          );
        }
      }
    } catch (e) {
      throw AppException(
        message: 'Invalid or expired OTP code. Please try again.',
      );
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
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb ? '${Uri.base.origin}/#/reset-password' : null,
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final cleanEmail = email.trim();
    final cleanToken = token.trim();
    final cleanPassword = newPassword.trim();

    try {
      // 1. Verify OTP code with recovery type first
      try {
        await _supabase.auth.verifyOTP(
          email: cleanEmail,
          token: cleanToken,
          type: OtpType.recovery,
        );
      } catch (e1) {
        try {
          await _supabase.auth.verifyOTP(
            email: cleanEmail,
            token: cleanToken,
            type: OtpType.email,
          );
        } catch (e2) {
          try {
            await _supabase.auth.verifyOTP(
              email: cleanEmail,
              token: cleanToken,
              type: OtpType.magiclink,
            );
          } catch (_) {
            throw e1;
          }
        }
      }

      // 2. Update password once authenticated
      await _supabase.auth.updateUser(UserAttributes(password: cleanPassword));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Current User & Session ────────────────────────────────────────────────
  Session? get currentSession => _supabase.auth.currentSession;
  User? get currentUser =>
      _supabase.auth.currentUser ?? _supabase.auth.currentSession?.user;
  bool get isAuthenticated => currentSession != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

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
