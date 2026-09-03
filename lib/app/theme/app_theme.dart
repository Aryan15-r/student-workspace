import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTheme — Builds the ThemeData for StudySpace
///
/// We use a dark theme by default (looks premium, great for hackathon demos).
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // ── Color Scheme ────────────────────────────────────────────────────────
      colorScheme: ColorScheme.dark(
        primary:          AppColors.primary,
        secondary:        AppColors.secondary,
        tertiary:         AppColors.accent,
        surface:          AppColors.surface,
        error:            AppColors.error,
        onPrimary:        Colors.white,
        onSecondary:      Colors.white,
        onSurface:        AppColors.textPrimary,
        onError:          Colors.white,
        surfaceContainerHighest: AppColors.card,
      ),

      // ── Scaffold & Background ───────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.background,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:  AppColors.background,
        foregroundColor:  AppColors.textPrimary,
        elevation:        0,
        scrolledUnderElevation: 0,
        centerTitle:      false,
        titleTextStyle:   GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Cards ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:     AppColors.surface,
        elevation: 0,
        shape:     RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // ── Elevated Button ──────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation:       0,
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Outlined Button ──────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side:            const BorderSide(color: AppColors.primary, width: 1.5),
          padding:         const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Text Button ──────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Input Fields ─────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:           true,
        fillColor:        AppColors.surface,
        contentPadding:   const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle:        GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        labelStyle:       GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
        enabledBorder:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder:    OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder:      OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:    AppColors.card,
        labelStyle:         GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        shape:              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side:               const BorderSide(color: AppColors.border),
        padding:            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      // ── Bottom Navigation Bar ─────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:    AppColors.surface,
        selectedItemColor:  AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type:               BottomNavigationBarType.fixed,
        elevation:          0,
      ),

      // ── Navigation Rail ───────────────────────────────────────────────────
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor:    AppColors.surface,
        selectedIconTheme:  IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textMuted),
        selectedLabelTextStyle: TextStyle(color: AppColors.primary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textMuted),
        indicatorColor:     Color(0x336366F1), // primary with 20% opacity
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:   AppColors.divider,
        space:   1,
        thickness: 1,
      ),

      // ── Floating Action Button ────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation:       4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:  AppColors.card,
        contentTextStyle: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // ── List Tile ────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        iconColor:       AppColors.textSecondary,
        textColor:       AppColors.textPrimary,
        tileColor:       Colors.transparent,
        contentPadding:  EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Text Theme (fallback) ─────────────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:   GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        headlineLarge:  GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        bodyLarge:      GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary),
        bodyMedium:     GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
        bodySmall:      GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
  }
}
