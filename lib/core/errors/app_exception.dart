import 'package:supabase_flutter/supabase_flutter.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppException — Custom exception class
///
/// Converts technical errors into human-readable messages for students.
/// ─────────────────────────────────────────────────────────────────────────────
class AppException implements Exception {
  final String message;   // Human-readable message (shown to user)
  final String? code;     // Optional error code (for debugging)
  final dynamic original; // The original error/exception

  const AppException({
    required this.message,
    this.code,
    this.original,
  });

  @override
  String toString() => message;

  // ── Common Exceptions ──────────────────────────────────────────────────────

  factory AppException.networkError() => const AppException(
    message: 'No internet connection. Please check your network and try again.',
    code: 'network_error',
  );

  factory AppException.authError([String? detail]) => AppException(
    message: detail ?? 'Authentication failed. Please try again.',
    code: 'auth_error',
  );

  factory AppException.notFound(String item) => AppException(
    message: '$item not found.',
    code: 'not_found',
  );

  factory AppException.permissionDenied() => const AppException(
    message: 'You do not have permission to do that.',
    code: 'permission_denied',
  );

  factory AppException.serverError() => const AppException(
    message: 'Server error. Please try again in a moment.',
    code: 'server_error',
  );

  factory AppException.aiError() => const AppException(
    message: 'Could not connect to AI. Please check your API key and try again.',
    code: 'ai_error',
  );

  factory AppException.fileError() => const AppException(
    message: 'Could not read or process the file.',
    code: 'file_error',
  );

  /// Convert any exception/error to an AppException
  static AppException from(dynamic error) {
    if (error is AppException) return error;

    if (error is AuthException) {
      return AppException(
        message: _friendlifyAuth(error.message),
        code: error.statusCode,
        original: error,
      );
    }

    final message = error?.toString() ?? 'An unexpected error occurred.';
    return AppException(message: _friendlify(message), original: error);
  }

  static String _friendlifyAuth(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('token has expired') || lower.contains('otp_expired') || lower.contains('expired')) {
      return 'The verification code has expired. Please request a new OTP.';
    }
    if (lower.contains('invalid token') || lower.contains('invalid otp') || lower.contains('bad jwt') || lower.contains('otp')) {
      return 'Invalid verification code. Please check your 6-digit OTP code.';
    }
    if (lower.contains('rate limit') || lower.contains('over_email_send_rate_limit')) {
      return 'Too many email requests. Please wait a minute before requesting another OTP.';
    }
    if (lower.contains('invalid login credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists. Please log in.';
    }
    if (lower.contains('password') && lower.contains('characters')) {
      return 'Password must be at least 6 characters long.';
    }
    if (lower.contains('network') || lower.contains('socket') || lower.contains('failed to host')) {
      return 'Network error. Please check your internet connection.';
    }
    return raw;
  }

  /// Convert ugly technical error messages to student-friendly ones
  static String _friendlify(String raw) {
    if (raw.contains('SocketException') || raw.contains('NetworkException') || raw.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Wrong email or password. Please try again.';
    }
    if (raw.contains('User already registered')) {
      return 'An account with this email already exists. Please log in instead.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account first.';
    }
    if (raw.contains('JWT') || raw.contains('session')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
