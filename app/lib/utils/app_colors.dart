import 'package:flutter/material.dart';
import 'app_color_scheme.dart';
import 'app_themes.dart';

/// Static color accessors — all existing AppColors.xxx calls work unchanged.
/// The active scheme is swapped by AppThemeNotifier; no screen edits needed.
class AppColors {
  AppColors._();

  static AppColorScheme _scheme = AppThemes.yellow;

  // Called by AppThemeNotifier only.
  static void applyScheme(AppColorScheme scheme) => _scheme = scheme;

  static Color get background => _scheme.background;
  static Color get primaryYellow => _scheme.primaryYellow;
  static Color get darkYellow => _scheme.darkYellow;
  static Color get navigationYellow => _scheme.navigationYellow;
  static Color get accentGreen => _scheme.accentGreen;
  static Color get accentPink => _scheme.accentPink;
  static Color get accentPurple => _scheme.accentPurple;
  static Color get accentBlue => _scheme.accentBlue;
  static Color get lightBlue => _scheme.lightBlue;
  static Color get navigationBlue => _scheme.navigationBlue;
  static Color get tagPurple => _scheme.tagPurple;
  static Color get showAllButton => _scheme.showAllButton;
  static Color get textPrimary => _scheme.textPrimary;
  static Color get textSecondary => _scheme.textSecondary;
  static Color get border => _scheme.border;
  static Color get shadow => _scheme.shadow;
}
