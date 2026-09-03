import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthProvider — Manages authentication state for the whole app
///
/// Uses ChangeNotifier so the UI rebuilds automatically when auth changes.
/// GoRouter listens to this to redirect unauthenticated users.
///
/// FLOW:
///   App starts → AuthProvider listens to Supabase auth stream
///   User logs in → isAuthenticated becomes true → Router goes to /dashboard
///   User logs out → isAuthenticated becomes false → Router goes to /
/// ─────────────────────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  // ── State fields ────────────────────────────────────────────────────────────
  UserProfile? _profile;     // The logged-in user's profile
  bool _isLoading = false;   // True while performing an async operation
  String? _error;            // Error message to show in the UI
  bool _initialized = false; // True after the initial auth check

  // ── Getters (read-only access to state) ────────────────────────────────────
  UserProfile? get profile       => _profile;
  bool         get isLoading     => _isLoading;
  String?      get error         => _error;
  bool         get initialized   => _initialized;
  bool         get isAuthenticated => _authService.isAuthenticated && _profile != null;

  // ── Constructor ────────────────────────────────────────────────────────────
  AuthProvider() {
    _init();
  }

  /// Start listening to auth state changes from Supabase
  void _init() {
    _authService.authStateChanges.listen((authState) async {
      final user = authState.session?.user;
      if (user != null) {
        // User just logged in — fetch their profile
        await _loadProfile(user.id);
      } else {
        // User logged out — clear the profile
        _profile = null;
      }
      _initialized = true;
      notifyListeners(); // Tell the UI to rebuild
    });
  }

  /// Load the user's profile from Supabase
  Future<void> _loadProfile(String userId) async {
    try {
      _profile = await _authService.fetchProfile(userId);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        username: username,
        fullName: fullName,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _profile = null;
      _error = null;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
    } finally {
      _setLoading(false);
    }
  }

  // ── Password Reset ─────────────────────────────────────────────────────────
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update the current user's profile
  Future<bool> updateProfile(UserProfile updated) async {
    _setLoading(true);
    try {
      await _authService.updateProfile(updated);
      _profile = updated;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Clear any displayed error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Private helper ─────────────────────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
