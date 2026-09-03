import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppColors — StudySpace Design System
///
/// USAGE: Use AppColors.primary instead of hardcoding Color(0xFF6366F1).
/// This makes it easy to change the theme in one place.
/// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  // Private constructor — this class should never be instantiated
  AppColors._();

  // ── Brand Colors ───────────────────────────────────────────────────────────
  static const Color primary   = Color(0xFF6366F1); // Indigo — main brand color
  static const Color secondary = Color(0xFF8B5CF6); // Violet — accents
  static const Color accent    = Color(0xFF06B6D4); // Cyan — highlights/links

  // ── Gradient (used on landing page, cards) ─────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A0A1A), Color(0xFF0D0D22)],
  );

  // ── Background Layers ──────────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0A1A); // Page background
  static const Color surface    = Color(0xFF13132A); // Cards, dialogs
  static const Color card       = Color(0xFF1E1E3A); // Inner cards
  static const Color overlay    = Color(0xFF252545); // Hover / pressed states

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border     = Color(0xFF2D2D5A);
  static const Color divider    = Color(0xFF1F1F40);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success    = Color(0xFF10B981); // Green — done / success
  static const Color warning    = Color(0xFFF59E0B); // Amber — due soon
  static const Color error      = Color(0xFFEF4444); // Red — errors
  static const Color info       = Color(0xFF3B82F6); // Blue — informational

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF8FAFC); // Main readable text
  static const Color textSecondary = Color(0xFF94A3B8); // Subtitles, hints
  static const Color textMuted     = Color(0xFF475569); // Placeholder text

  // ── Priority Colors (used in To-Do) ───────────────────────────────────────
  static const Color priorityHigh   = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow    = Color(0xFF10B981);

  // ── Category Colors (used in To-Do) ───────────────────────────────────────
  static const Color categoryAssignment = Color(0xFF6366F1);
  static const Color categoryExam       = Color(0xFFEF4444);
  static const Color categoryProject    = Color(0xFF8B5CF6);
  static const Color categoryPersonal   = Color(0xFF06B6D4);
  static const Color categoryCollege    = Color(0xFF10B981);

  /// Returns the color for a given priority string.
  static Color forPriority(String priority) {
    switch (priority) {
      case 'high':   return priorityHigh;
      case 'medium': return priorityMedium;
      case 'low':    return priorityLow;
      default:       return priorityMedium;
    }
  }

  /// Returns the color for a given category string.
  static Color forCategory(String category) {
    switch (category) {
      case 'assignment': return categoryAssignment;
      case 'exam':       return categoryExam;
      case 'project':    return categoryProject;
      case 'personal':   return categoryPersonal;
      case 'college':    return categoryCollege;
      default:           return primary;
    }
  }
}
