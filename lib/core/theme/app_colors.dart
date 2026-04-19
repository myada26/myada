import 'package:flutter/material.dart';

/// MyADA Color System
/// Source: App.jsx + theme.css (Warm cream + Navy + Gold palette)
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Backgrounds
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF4EFEA); // scaffold bg
  static const Color surface = Color(0xFFFAF8F5); // card surface
  static const Color surfaceVariant = Color(0xFFECECF0); // muted surface
  static const Color popover = Color(0xFFFFFFFF); // modals / sheets

  // ---------------------------------------------------------------------------
  // Foreground / Text
  // ---------------------------------------------------------------------------
  static const Color foreground = Color(0xFF1F2937);
  static const Color mutedForeground = Color(0xFF717182);
  static const Color subtleForeground = Color(0xFF9CA3AF);

  // ---------------------------------------------------------------------------
  // Primary — Navy Blue  (#1E3A8A from App.jsx)
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF1E3A8A);
  static const Color primaryHover = Color(0xFF152A65);
  static const Color primaryLight = Color(0xFFDBE4FF);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Accent — Gold  (#E89C1E from App.jsx)
  // ---------------------------------------------------------------------------
  static const Color accent = Color(0xFFE89C1E);
  static const Color accentLight = Color(0xFFFAC775); // badge tint
  static const Color accentSubtle = Color(0xFFFAEEDA); // bg pill
  static const Color accentForeground = Color(0xFF1F2937);

  // ---------------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFCA2B2C); // from App.jsx
  static const Color errorLight = Color(0xFFFCEBEB);
  static const Color success = Color(0xFF1D9E75);
  static const Color successLight = Color(0xFFE1F5EE);
  static const Color warning = Color(0xFFEF9F27);
  static const Color warningLight = Color(0xFFFAEEDA);

  // ---------------------------------------------------------------------------
  // Borders  (rgba(0,0,0,0.1) from theme.css → soft)
  // ---------------------------------------------------------------------------
  static const Color border = Color(0x1A2D2D2D); // 10% opacity
  static const Color borderStrong = Color(0x4D2D2D2D); // 30% — hover/focus
  static const Color borderHeavy = Color(0xFF2D2D2D); // full — App.jsx nav bar

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------
  static const Color inputBackground = Color(0xFFF3F3F5);
  static const Color switchBackground = Color(0xFFCBCED4);

  // ---------------------------------------------------------------------------
  // XP / Gamification badge colors (from App.jsx XP chip)
  // ---------------------------------------------------------------------------
  static const Color xpBackground = Color(0x1AE89C1E); // accent/10
  static const Color xpBorder = Color(0x4DE89C1E);

  static const Color muted = mutedForeground;
  static const Color textPrimary = foreground;
  static const Color surfaceElevated = surface;
  static const Color textMuted = mutedForeground;
  static const Color navBorder = borderHeavy;
  static const Color textSecondary = subtleForeground;
  static const Color locked = switchBackground;
  static const Color primaryDark = primaryHover;
}
