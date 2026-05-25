import 'package:flutter/material.dart';

/// All color tokens for a single theme.
/// To add a new theme, create another AppColorScheme instance in AppThemes.
class AppColorScheme {
  final String id;
  final String name;

  // Page / scaffold
  final Color background;

  // Primary palette
  final Color primaryYellow;
  final Color darkYellow;
  final Color navigationYellow;

  // Accent palette (used for stat cards, section colors, etc.)
  final Color accentGreen;
  final Color accentPink;
  final Color accentPurple;
  final Color accentBlue;
  final Color lightBlue;

  // Navigation
  final Color navigationBlue;

  // Misc interactive
  final Color tagPurple;
  final Color showAllButton;

  // Text
  final Color textPrimary;
  final Color textSecondary;

  // Borders & shadows (neo-brutalism outlines)
  final Color border;
  final Color shadow;

  const AppColorScheme({
    required this.id,
    required this.name,
    required this.background,
    required this.primaryYellow,
    required this.darkYellow,
    required this.navigationYellow,
    required this.accentGreen,
    required this.accentPink,
    required this.accentPurple,
    required this.accentBlue,
    required this.lightBlue,
    required this.navigationBlue,
    required this.tagPurple,
    required this.showAllButton,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.shadow,
  });
}
