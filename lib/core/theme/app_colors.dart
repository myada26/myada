import 'package:flutter/material.dart';

/// MyADA Strict UI Color System
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Base Strict Palette (No magic hex codes outside these 10)
  // Deep Blue    — #0A5DE8 (Primary)
  // Bright Blue  — #1E63D2 (Primary Hover)
  // Sky Blue     — #5EB9E1 (Primary Light)
  // Orange       — #FF6A1A (Accent)
  // Coral/Peach  — #FF8A5B (Error)
  // Pink         — #F48FB1 (Tertiary)
  // Yellow       — #FFD233 (Success)
  // White        — #FFFFFF (Surface)
  // Light Gray   — #F5F5F5 (Background)
  // Dark Gray    — #333333 (Foreground)
  // ---------------------------------------------------------------------------

  // Primary
  static const Color primary = Color(0xFF0A5DE8);
  static const Color primaryHover = Color(0xFF1E63D2);
  static const Color primaryLight = Color(0xFF5EB9E1);
  static const Color primaryDark = Color(0xFF1E63D2);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color popover = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Text
  static const Color foreground = Color(0xFF333333);
  static const Color textPrimary = Color(0xFF333333);
  // Using alpha for muted effects while keeping the base color exact.
  static const Color mutedForeground = Color(0x99333333); // 60% black
  static const Color subtleForeground = Color(0x66333333); // 40% black
  static const Color textMuted = Color(0x99333333);
  static const Color textSecondary = Color(0x66333333);
  static const Color muted = Color(0x99333333);

  // Semantics & Accents
  static const Color accent = Color(0xFFFF6A1A);
  static const Color accentLight = Color(0xFFFF6A1A); // using base accent
  static const Color accentSubtle = Color(0x33FF6A1A); 
  static const Color accentForeground = Color(0xFF333333);
  
  static const Color error = Color(0xFFFF8A5B); // Coral
  static const Color errorLight = Color(0x33FF8A5B);
  
  static const Color success = Color(0xFFFFD233); // Yellow
  static const Color successLight = Color(0x33FFD233);
  
  static const Color warning = Color(0xFFFF6A1A); // Orange
  static const Color warningLight = Color(0x33FF6A1A);

  // Borders
  static const Color border = Color(0x1A333333); // 10% dark
  static const Color borderStrong = Color(0x4D333333); // 30% dark
  static const Color borderHeavy = Color(0xFF333333); 
  static const Color navBorder = Color(0xFF333333);

  // Input
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color switchBackground = Color(0x4D333333);
  static const Color locked = Color(0x4D333333);

  // Gamification
  static const Color xpBackground = Color(0x1AFF6A1A);
  static const Color xpBorder = Color(0x4DFF6A1A);

  // Legacy mappings for Progress Screen / Challenge Center
  // Previously utilized a disjointed color palette; now alias to strict system
  static const Color challengeAmber       = Color(0xFFFFD233); // Yellow
  static const Color challengeAmberLight  = Color(0x33FFD233);
  static const Color challengeCoral       = Color(0xFFFF8A5B); // Coral
  static const Color challengeCoralLight  = Color(0x33FF8A5B);
  static const Color challengePurple      = Color(0xFF0A5DE8); // Deep Blue
  static const Color challengePurpleLight = Color(0x330A5DE8);
  static const Color challengePurpleFill  = Color(0xFF5EB9E1); // Sky Blue
  static const Color challengeTeal        = Color(0xFF0A5DE8); // Fallback to primary
  static const Color challengeTealLight   = Color(0x330A5DE8); 
  static const Color challengeGreenLight  = Color(0x33FFD233); // Yellow light
  static const Color challengeGreen       = Color(0xFFFFD233); // Yellow
}
