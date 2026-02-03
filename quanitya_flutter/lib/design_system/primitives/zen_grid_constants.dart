import 'ui_scaler.dart';

/// **SINGLE SOURCE OF TRUTH** for zen paper and analytics grid alignment
/// 
/// Used by both ZenPaperBackground and AnalyticsGrid to ensure perfect alignment.
/// Any changes here automatically sync both systems.
/// 
/// **CRITICAL:** These values are used by zen paper background for dot rendering.
/// Changes affect both visual alignment and performance-optimized chunk rendering.
class ZenGridConstants {
  ZenGridConstants._();
  
  /// Base zen paper dot spacing - scaled for device and aligned with 8dp grid
  /// 
  /// Used by:
  /// - ZenPaperBackground for dot grid rendering
  /// - AnalyticsGrid for component spacing
  /// - All analytics widgets for perfect alignment
  static double get dotSpacing => UiScaler.instance.px(24.0);
  
  /// Zen paper dot radius - scaled for device
  /// 
  /// Used by:
  /// - ZenPaperBackground for dot rendering
  /// - AnalyticsConnectionLine for connection dots
  static double get dotRadius => UiScaler.instance.px(1.2);
  
  /// Dot color opacity for zen paper background
  /// 
  /// Consistent across all grid-related visual elements
  static double get dotOpacity => 0.25;
}