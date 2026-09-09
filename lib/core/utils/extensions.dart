import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Extensions — Utility methods added onto existing Dart/Flutter types
///
/// USAGE: Instead of writing DateFormat('d MMM').format(date),
///        you can write date.toDisplayString()
/// ─────────────────────────────────────────────────────────────────────────────

// ── String Extensions ─────────────────────────────────────────────────────────
extension StringExtensions on String {
  /// Capitalizes the first letter: "hello" → "Hello"
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalizes each word: "hello world" → "Hello World"
  String get titleCase {
    return split(' ').map((w) => w.capitalized).join(' ');
  }

  /// Returns true if this looks like a valid email
  bool get isValidEmail {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Truncates to [maxLength] and appends "..." if longer
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

// ── DateTime Extensions ───────────────────────────────────────────────────────
extension DateTimeExtensions on DateTime {
  /// Format: "3 Sep 2026"
  String get toDisplayString => DateFormat('d MMM yyyy').format(this);

  /// Format: "3 Sep" (no year)
  String get toShortDisplay => DateFormat('d MMM').format(this);

  /// Format: "12:30 PM"
  String get toTimeString => DateFormat('h:mm a').format(this);

  /// Format: "3 Sep 2026, 12:30 PM"
  String get toFullDisplay => DateFormat('d MMM yyyy, h:mm a').format(this);

  /// True if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// True if this date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// True if this date is in the past
  bool get isPast => isBefore(DateTime.now());

  /// True if this date is overdue (past and not completed)
  bool get isOverdue => isPast && !isToday;

  /// Human-friendly due date label
  String get dueDateLabel {
    if (isToday) return 'Due Today';
    if (isTomorrow) return 'Due Tomorrow';
    if (isPast) return 'Overdue · $toShortDisplay';
    return 'Due $toShortDisplay';
  }
}

// ── Nullable DateTime Extensions ──────────────────────────────────────────────
extension NullableDateTimeExtensions on DateTime? {
  String get toDisplayOrEmpty {
    if (this == null) return '';
    return this!.toDisplayString;
  }
}

// ── BuildContext Extensions ───────────────────────────────────────────────────
extension ContextExtensions on BuildContext {
  /// Screen width
  double get width => MediaQuery.of(this).size.width;

  /// Screen height
  double get height => MediaQuery.of(this).size.height;

  /// True on mobile (< 600px)
  bool get isMobile => width < 600;

  /// True on tablet (600–1024px)
  bool get isTablet => width >= 600 && width < 1024;

  /// True on desktop/web (> 1024px)
  bool get isDesktop => width >= 1024;

  /// Show a snackbar
  void showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Color Extensions ──────────────────────────────────────────────────────────
extension ColorExtensions on Color {
  /// Returns this color with the given opacity (0.0 to 1.0)
  Color withAlpha(double opacity) => withValues(alpha: opacity);
}
