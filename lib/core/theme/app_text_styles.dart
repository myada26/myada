import 'package:flutter/material.dart';
import 'app_colors.dart';

/// MyADA Typography System
/// Mirrors theme.css h1–h4, label, body, input scale
class AppTextStyles {
  AppTextStyles._();

  // Scale — 6-tier system
  static const double _xs      = 10.0;  // Tier 6: Micro
  static const double _sm      = 12.0;  // Tier 5: Label / Caption
  static const double _base    = 14.0;  // Tier 4: Body
  static const double _lg      = 18.0;  // Tier 3: Title / Subheading
  static const double _heading = 22.0;  // Tier 2: Heading
  static const double _display = 32.0;  // Tier 1: Display / Hero

  // Used only for input/button sizing (not display tiers)
  static const double _md = 16.0;

  // ---------------------------------------------------------------------------
  // Display / Headings
  // ---------------------------------------------------------------------------
  static const TextStyle h1 = TextStyle(
    fontSize: _display,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: _heading,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: _lg,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: _base,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // Body
  // ---------------------------------------------------------------------------
  static const TextStyle bodyLg = TextStyle(
    fontSize: _base,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontSize: _base,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.6,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: _base,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
    height: 1.6,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedForeground,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // Labels / UI text
  // ---------------------------------------------------------------------------
  static const TextStyle label = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.w500,
    color: AppColors.foreground,
    letterSpacing: 0.02,
  );

  static const TextStyle caption = TextStyle(
    fontSize: _xs,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    letterSpacing: 0.04,
  );

  // ---------------------------------------------------------------------------
  // Button text
  // ---------------------------------------------------------------------------
  static const TextStyle button = TextStyle(
    fontSize: _base,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.01,
  );

  static const TextStyle buttonSm = TextStyle(
    fontSize: _sm,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------
  static const TextStyle input = TextStyle(
    fontSize: _md,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle inputHint = TextStyle(
    fontSize: _md,
    fontWeight: FontWeight.w400,
    color: AppColors.subtleForeground,
    height: 1.5,
  );

  // ---------------------------------------------------------------------------
  // Badge / Chip
  // ---------------------------------------------------------------------------
  static const TextStyle badge = TextStyle(
    fontSize: _xs,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.04,
  );

  static const TextStyle labelSmall = labelSm;
  static const TextStyle displayMedium = h1;
  static const TextStyle headingLarge = h1;
  static const TextStyle headingMedium = h2;
  static const TextStyle headingSmall = h3;
  static const TextStyle bodyMedium = body;
  static const TextStyle bodySmall = bodySm;
  static const TextStyle labelMedium = label;
}
