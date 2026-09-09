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
  static const Color primary = Color(
    0xFFE07A5F,
  ); // Terracotta — warm, optimistic focus
  static const Color secondary = Color(0xFFF2CC8F); // Honey — gentle highlights
  static const Color accent = Color(0xFF81B29A); // Sage — calm progress

  // ── Gradient (used on landing page, cards) ─────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8F0), Color(0xFFF7EBDD)],
  );

  // ── Background Layers ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFF8F0); // Page background
  static const Color surface = Color(0xFFFFFCF8); // Cards, dialogs
  static const Color card = Color(0xFFF7EBDD); // Inner cards
  static const Color overlay = Color(0xFFF0DCCB); // Hover / pressed states

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border = Color(0xFFE8D4C4);
  static const Color divider = Color(0xFFF0E1D4);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Green — done / success
  static const Color warning = Color(0xFFF59E0B); // Amber — due soon
  static const Color error = Color(0xFFEF4444); // Red — errors
  static const Color info = Color(0xFF3B82F6); // Blue — informational

  // ── Text Colors ───────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3D2C2E); // Main readable text
  static const Color textSecondary = Color(0xFF806A63); // Subtitles, hints
  static const Color textMuted = Color(0xFFB39A8F); // Placeholder text

  // ── Priority Colors (used in To-Do) ───────────────────────────────────────
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // ── Category Colors (used in To-Do) ───────────────────────────────────────
  static const Color categoryAssignment = Color(0xFF6366F1);
  static const Color categoryExam = Color(0xFFEF4444);
  static const Color categoryProject = Color(0xFF8B5CF6);
  static const Color categoryPersonal = Color(0xFF06B6D4);
  static const Color categoryCollege = Color(0xFF10B981);

  /// Returns the color for a given priority string.
  static Color forPriority(String priority) {
    switch (priority) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  /// Returns the color for a given category string.
  static Color forCategory(String category) {
    switch (category) {
      case 'assignment':
        return categoryAssignment;
      case 'exam':
        return categoryExam;
      case 'project':
        return categoryProject;
      case 'personal':
        return categoryPersonal;
      case 'college':
        return categoryCollege;
      default:
        return primary;
    }
  }
}
