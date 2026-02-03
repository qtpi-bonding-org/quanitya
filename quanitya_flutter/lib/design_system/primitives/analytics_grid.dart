import 'package:flutter/material.dart';
import 'zen_grid_constants.dart';

/// Analytics-specific grid constants that align with zen paper
/// 
/// **SHARED WITH ZEN PAPER** for perfect dot alignment in analytical diagrams.
/// Creates visual harmony by using the same constants as ZenPaperBackground.
/// Uses 24px base spacing (3 × AppSizes.space) for perfect 8dp grid alignment.
/// 
/// All values reference ZenGridConstants to ensure automatic synchronization.
/// 
/// **CRITICAL ALIGNMENT RULE:**
/// When positioning elements on the zen grid using `Positioned`, you must
/// offset by half the element's size to center it on the grid point:
/// ```dart
/// Positioned(
///   left: (gridColumn * AnalyticsGrid.baseSpacing) - (width / 2),
///   top: (gridRow * AnalyticsGrid.baseSpacing) - (height / 2),
///   child: Container(width: width, height: height, ...),
/// )
/// ```
class AnalyticsGrid {
  AnalyticsGrid._();
  
  /// Base zen paper spacing - SHARED with ZenPaperBackground for perfect alignment
  static double get baseSpacing => ZenGridConstants.dotSpacing;
  
  /// Zen paper dot radius - SHARED with ZenPaperBackground
  static double get dotRadius => ZenGridConstants.dotRadius;
  
  /// Common analytics spacing (multiples of baseSpacing)
  static double get unit1 => baseSpacing;      // ~24px scaled (3 × AppSizes.space)
  static double get unit2 => baseSpacing * 2; // ~48px scaled (6 × AppSizes.space)  
  static double get unit3 => baseSpacing * 3; // ~72px scaled (9 × AppSizes.space)
  static double get unit4 => baseSpacing * 4; // ~96px scaled (12 × AppSizes.space)
  
  /// Pipeline-specific sizes
  static double get connectionHeight => unit2;  // 2 grid units (48px) - dot to dot
  static double get cardMinHeight => unit4;     // 4 grid units (96px)
  static double get cardMinWidth => unit6;      // 6 grid units (144px)
  static double get cardPadding => unit1;       // 1 grid unit (24px)
  
  /// Additional grid units for larger components
  static double get unit5 => baseSpacing * 5;  // 120px
  static double get unit6 => baseSpacing * 6;  // 144px
  static double get unit8 => baseSpacing * 8;  // 192px
  
  /// Calculate the left position to center an element on a grid column
  /// 
  /// Use this when positioning with `Positioned.left`:
  /// ```dart
  /// Positioned(
  ///   left: AnalyticsGrid.centerOnColumn(4, width: 120),
  ///   ...
  /// )
  /// ```
  static double centerOnColumn(int column, {required double width}) {
    return (column * baseSpacing) - (width / 2);
  }
  
  /// Calculate the top position to center an element on a grid row
  /// 
  /// Use this when positioning with `Positioned.top`:
  /// ```dart
  /// Positioned(
  ///   top: AnalyticsGrid.centerOnRow(3, height: 72),
  ///   ...
  /// )
  /// ```
  static double centerOnRow(int row, {required double height}) {
    return (row * baseSpacing) - (height / 2);
  }
  
  /// Calculate the left position for a vertical line centered on a grid column
  /// 
  /// Lines need special handling since they're typically 2px wide
  static double lineOnColumn(int column, {double lineWidth = 2.0}) {
    return (column * baseSpacing) - (lineWidth / 2);
  }
  
  /// Get the Y coordinate for a specific grid row
  static double rowY(int row) => row * baseSpacing;
  
  /// Get the X coordinate for a specific grid column
  static double columnX(int column) => column * baseSpacing;
  
  /// Grid-aligned EdgeInsets helpers for consistent padding
  static EdgeInsets get paddingUnit1 => EdgeInsets.all(unit1);
  static EdgeInsets get paddingUnit2 => EdgeInsets.all(unit2);
  static EdgeInsets get paddingUnit3 => EdgeInsets.all(unit3);
  
  /// Asymmetric grid padding (values must be grid units)
  static EdgeInsets paddingSymmetric({
    double? horizontal,
    double? vertical,
  }) => EdgeInsets.symmetric(
    horizontal: horizontal ?? 0,
    vertical: vertical ?? 0,
  );
  
  /// Custom grid padding (all values should be grid multiples for alignment)
  static EdgeInsets paddingOnly({
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) => EdgeInsets.only(
    left: left ?? 0,
    top: top ?? 0,
    right: right ?? 0,
    bottom: bottom ?? 0,
  );
}