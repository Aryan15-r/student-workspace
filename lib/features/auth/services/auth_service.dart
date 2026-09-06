import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../../../core/errors/app_exception.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthService — Handles all Supabase authentication operations
/// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  final _supabase = Supabase.instance.client;

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
        data: {
          'username': username,
          'full_name': fullName ?? '',
        },
      );
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ── Sign In with Password ──────────────────────────────────────────────────
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
      throw AppException(message: 'Invalid or expired OTP code. Please try again.');
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
    try {
      // Verify OTP (try recovery first, then magiclink, then signup)
      try {
        await _supabase.auth.verifyOTP(
          email: email,
          token: token,
          type: OtpType.recovery,
        );
      } catch (_) {
        try {
          await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.magiclink,
          );
        } catch (_) {
          await _supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: OtpType.signup,
          );
        }
      }

      // Update password once authenticated
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
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
  User? get currentUser => _supabase.auth.currentUser ?? _supabase.auth.currentSession?.user;
  bool get isAuthenticated => currentUser != null || currentSession != null;

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
