import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AuthProvider — Manages authentication state for the whole app
/// ─────────────────────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserProfile? _profile; // The logged-in user's profile
  bool _isLoading = false; // True while performing an async operation
  String? _error; // Error message to show in the UI
  bool _initialized = false; // True after the initial auth check
  bool _isGuest = false; // True when user browses without signing in
  bool _isPasswordRecovery =
      false; // True when user is in recovery mode to reset password

  // Guest usage limits
  int _guestAiQueries = 0;
  static const int maxGuestAiQueries = 3;
  static const int maxGuestTodos = 3;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get initialized => _initialized;
  bool get isGuest => _isGuest;
  bool get isPasswordRecovery => _isPasswordRecovery;
  int get guestAiQueries => _guestAiQueries;

  bool get canAskGuestAi => !_isGuest || _guestAiQueries < maxGuestAiQueries;

  // User is authenticated as long as Supabase has an active session or profile
  bool get isAuthenticated => _authService.isAuthenticated || _profile != null;

  void continueAsGuest() {
    _isGuest = true;
    _error = null;
    notifyListeners();
  }

  void exitGuestMode() {
    _isGuest = false;
    notifyListeners();
  }

  void setPasswordRecovery(bool value) {
    _isPasswordRecovery = value;
    notifyListeners();
  }

  void clearPasswordRecovery() {
    _isPasswordRecovery = false;
    notifyListeners();
  }

  bool incrementGuestAiQuery() {
    if (!_isGuest) return true;
    if (_guestAiQueries < maxGuestAiQueries) {
      _guestAiQueries++;
      notifyListeners();
      return true;
    }
    return false;
  }

  AuthProvider() {
    _init();
  }

  void _init() {
    // 1. Immediately evaluate local/cached Supabase session
    final initialUser = _authService.currentUser;
    if (initialUser != null) {
      // Routing must not wait for a profile request when the device is offline.
      _initialized = true;
      notifyListeners();
      _loadProfile(initialUser.id);
    } else {
      // Do not make the first screen depend on Supabase's network handshake.
      // Guest mode keeps offline tools usable while auth settles in the background.
      _isGuest = true;
      _initialized = true;
      notifyListeners();
    }

    // 2. Listen for auth changes (token refresh, sign in, sign out, password recovery)
    _authService.authStateChanges.listen((authState) async {
      final event = authState.event;
      final user = authState.session?.user ?? _authService.currentUser;

      if (event == AuthChangeEvent.signedOut) {
        _profile = null;
        _isPasswordRecovery = false;
        _initialized = true;
        notifyListeners();
        return;
      }

      if (event == AuthChangeEvent.passwordRecovery) {
        _isPasswordRecovery = true;
        _initialized = true;
        notifyListeners();
        return;
      }

      if (user != null) {
        await _loadProfile(user.id);
      } else if (event == AuthChangeEvent.initialSession) {
        _profile = null;
      }

      _initialized = true;
      notifyListeners();
    });
  }

  Future<void> _loadProfile(String userId) async {
    try {
      _profile = await _authService
          .fetchProfile(userId)
          .timeout(const Duration(seconds: 4));
      if (_profile == null) {
        final user = _authService.currentUser;
        if (user != null) {
          _profile = UserProfile(
            id: user.id,
            username:
                user.userMetadata?['username'] as String? ??
                (user.email?.split('@').first ?? 'student'),
            fullName: user.userMetadata?['full_name'] as String? ?? 'Student',
            avatarUrl: '',
            bio: '',
            college: '',
            branch: '',
            createdAt: DateTime.now(),
          );
        }
      }
      if (_profile != null) {
        _isGuest = false; // Signed in successfully — exit guest mode!
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      final user = _authService.currentUser;
      if (user != null) {
        _profile = UserProfile(
          id: user.id,
          username:
              user.userMetadata?['username'] as String? ??
              (user.email?.split('@').first ?? 'student'),
          fullName: user.userMetadata?['full_name'] as String? ?? 'Student',
          avatarUrl: '',
          bio: '',
          college: '',
          branch: '',
          createdAt: DateTime.now(),
        );
        _isGuest = false;
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
  Future<bool> verifyOtp({required String email, required String token}) async {
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
  Future<bool> signIn({required String email, required String password}) async {
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

  // ── Sign In with Google ────────────────────────────────────────────────────
  Future<bool> signInWithGoogle({
    required String webClientId,
    String? iosClientId,
  }) async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle(
        webClientId: webClientId,
        iosClientId: iosClientId,
      );
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

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    try {
      await _authService.resetPasswordWithOtp(
        email: email,
        token: token,
        newPassword: newPassword,
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

  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    try {
      await _authService.updatePassword(newPassword);
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
