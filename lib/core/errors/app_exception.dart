/// ─────────────────────────────────────────────────────────────────────────────
/// AppException — Custom exception class
///
/// Instead of catching raw errors everywhere, we wrap them in this class
/// so we can always show a human-readable message to the student.
/// ─────────────────────────────────────────────────────────────────────────────
class AppException implements Exception {
  final String message;  // Human-readable message (shown to user)
  final String? code;    // Optional error code (for debugging)
  final dynamic original; // The original error/exception

  const AppException({
    required this.message,
    this.code,
    this.original,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';

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
    final message = error?.toString() ?? 'An unexpected error occurred.';
    return AppException(message: _friendlify(message), original: error);
  }

  /// Convert ugly technical error messages to student-friendly ones
  static String _friendlify(String raw) {
    if (raw.contains('SocketException') || raw.contains('NetworkException')) {
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
    if (raw.contains('JWT')) {
      return 'Your session has expired. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
