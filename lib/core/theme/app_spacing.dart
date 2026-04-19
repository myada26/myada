/// MyADA Spacing System — 8pt grid
/// Usage: SizedBox(height: AppSpacing.lg)
class AppSpacing {
  AppSpacing._();

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double xl2  = 32.0;
  static const double xl3  = 48.0;
  static const double xl4  = 64.0;

  /// Screen horizontal padding
  static const double screenPadding = 24.0;

  /// Card internal padding
  static const double cardPadding = 16.0;

  /// Bottom nav height (safe area excluded)
  static const double bottomNavHeight = 64.0;
}

/// Radius tokens — from theme.css --radius: 0.625rem = 10px
class AppRadius {
  AppRadius._();

  static const double sm   = 6.0;
  static const double md   = 8.0;
  static const double lg   = 10.0;
  static const double xl   = 14.0;
  static const double xl2  = 20.0;
  static const double full = 999.0;
}
