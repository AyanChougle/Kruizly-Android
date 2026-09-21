import '''package:flutter/material.dart''';

class AppColors {
  static const Color primary = Color(0xFF0071E3);
  static const Color primaryLight = Color(0xFF0071E3);
  static const Color primaryDark = Color(0xFF0071E3);
  static const Color accent = Color(0xFF0071E3);

  static const Color background = Color(0xFF080B10);
  static const Color surface = Color(0xFF121721);
  static const Color surfaceElevated = Color(0xFF1A2230);
  static const Color surfaceGlass = Color(0xCC121721);

  static const Color border = Color(0xFF222D3E);
  static const Color borderLight = Color(0xFF2E3B52);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Light Mode colors (White & Blue)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1F5F9);
  static const Color lightSurfaceGlass = Color(0xFAF8FAFC);

  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderLight = Color(0xFFCBD5E1);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0071E3);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0071E3), Color(0xFF0071E3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF141C28), Color(0xFF0F1622)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

extension AppThemeContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
  Color get themeBackground =>
      isDarkMode ? AppColors.background : AppColors.lightBackground;
  Color get themeSurface =>
      isDarkMode ? AppColors.surface : AppColors.lightSurface;
  Color get themeSurfaceElevated =>
      isDarkMode ? AppColors.surfaceElevated : AppColors.lightSurfaceElevated;
  Color get themeBorder =>
      isDarkMode ? AppColors.border : AppColors.lightBorder;
  Color get themeBorderLight =>
      isDarkMode ? AppColors.borderLight : AppColors.lightBorderLight;
  Color get themeTextPrimary =>
      isDarkMode ? AppColors.textPrimary : AppColors.lightTextPrimary;
  Color get themeTextSecondary =>
      isDarkMode ? AppColors.textSecondary : AppColors.lightTextSecondary;
  Color get themeTextMuted =>
      isDarkMode ? AppColors.textMuted : AppColors.lightTextMuted;
  LinearGradient get themeCardGradient =>
      isDarkMode ? AppColors.cardGradient : AppColors.lightCardGradient;
}
