import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthProvider — Manages authentication state for the whole app
/// ─────────────────────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserProfile? _profile;     // The logged-in user's profile
  bool _isLoading = false;   // True while performing an async operation
  String? _error;            // Error message to show in the UI
  bool _initialized = false; // True after the initial auth check

  UserProfile? get profile         => _profile;
  bool         get isLoading       => _isLoading;
  String?      get error           => _error;
  bool         get initialized     => _initialized;
  // User is authenticated as long as Supabase has an active session
  bool         get isAuthenticated => _authService.isAuthenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((authState) async {
      final user = authState.session?.user;
      if (user != null) {
        await _loadProfile(user.id);
      } else {
        _profile = null;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      _profile = await _authService.fetchProfile(userId);
      if (_profile == null) {
        final user = _authService.currentUser;
        if (user != null) {
          _profile = UserProfile(
            id: user.id,
            username: user.userMetadata?['username'] as String? ?? (user.email?.split('@').first ?? 'student'),
            fullName: user.userMetadata?['full_name'] as String? ?? 'Student',
            avatarUrl: '',
            bio: '',
            college: '',
            branch: '',
            createdAt: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      final user = _authService.currentUser;
      if (user != null) {
        _profile = UserProfile(
          id: user.id,
          username: user.userMetadata?['username'] as String? ?? (user.email?.split('@').first ?? 'student'),
          fullName: user.userMetadata?['full_name'] as String? ?? 'Student',
          avatarUrl: '',
          bio: '',
          college: '',
          branch: '',
          createdAt: DateTime.now(),
        );
      }
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

  // ── Send Email OTP ─────────────────────────────────────────────────────────
  Future<bool> sendOtp(String email) async {
    _setLoading(true);
    try {
      await _authService.sendOtp(email);
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('AppException: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Verify Email OTP ───────────────────────────────────────────────────────
  Future<bool> verifyOtp({
    required String email,
    required String token,
  }) async {
    _setLoading(true);
    try {
      final response = await _authService.verifyOtp(email: email, token: token);
      final user = response.user;
      if (user != null) {
        await _loadProfile(user.id);
      }
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

  // ── Sign In with Password ──────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _authService.signIn(email: email, password: password);
      final user = _authService.currentUser;
      if (user != null) {
        await _loadProfile(user.id);
      }
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
