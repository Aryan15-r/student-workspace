import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppColors — StudySpace Design System
///
/// USAGE: Use AppColors.primary instead of hardcoding Color(0xFFE07A5F).
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
  static const Color background = Color(0xFFFFF1E0); // Warmer page background
  static const Color surface = Color(0xFFFFFCF8); // Cards, dialogs
  static const Color card = Color(0xFFF7EBDD); // Inner cards
  static const Color overlay = Color(0xFFF0DCCB); // Hover / pressed states

  // ── Menu & Side Panel ─────────────────────────────────────────────────────
  static const Color menuBackground = Color(0xFFFFFDF9); // More menu (bottom sheet) background
  static const Color menuPanelBackground = Color(0xFF1A2A3A); // Navy Blue navbar/sidebar
  static const Color menuBorder = Color(0xFF2C3E50); // Darker border for navy blue
  static const Color menuSelectedBackground = Color(0xFF2C3E50); // Selected item on navy blue
  static const Color navBarUnselectedText = Color(0xFF94A3B8); // Light gray for unselected text on dark navbar
  static const Color navBarSelectedText = Color(0xFFF2CC8F); // Honey for selected text on dark navbar

  // ── Borders & Dividers ────────────────────────────────────────────────────
  static const Color border = Color(0xFFDCC4B2); // Defined border color for high contrast
  static const Color divider = Color(0xFFE5D2C2);

  // ── Status Colors ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Green — done / success
  static const Color warning = Color(0xFFF59E0B); // Amber — due soon
  static const Color error = Color(0xFFEF4444); // Red — errors
  static const Color info = Color(0xFF3B82F6); // Blue — informational

  // ── Text Colors (High Contrast) ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1E1012); // Deeper dark text for crisp contrast
  static const Color textSecondary = Color(0xFF57423D); // Strong, readable secondary text
  static const Color textMuted = Color(0xFF7C645C); // High-contrast muted text/placeholders

  // ── Priority Colors (used in To-Do) ───────────────────────────────────────
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // ── Category Colors (used in To-Do) ───────────────────────────────────────
  static const Color categoryAssignment = Color(0xFFE07A5F);
  static const Color categoryExam = Color(0xFFEF4444);
  static const Color categoryProject = Color(0xFFF2CC8F);
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
