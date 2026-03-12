import 'package:flutter/material.dart';
import '../primitives/quanitya_palette.dart';
import '../primitives/zen_grid_constants.dart';

/// A positioned widget that automatically centers its child on zen paper grid points.
/// 
/// This widget handles the offset calculation internally, so you just specify
/// the grid column and row, and the child will be centered on that grid point.
/// 
/// **Usage with grid units (recommended):**
/// ```dart
/// Stack(
///   children: [
///     ZenGridPositioned.gridUnits(
///       column: 4,
///       row: 2,
///       widthUnits: 5,  // 5 grid units wide
///       heightUnits: 3, // 3 grid units tall
///       child: Container(...),
///     ),
///   ],
/// )
/// ```
/// 
/// **Usage with explicit pixels:**
/// ```dart
/// Stack(
///   children: [
///     ZenGridPositioned(
///       column: 4,
///       row: 2,
///       width: 120,
///       height: 72,
///       child: Container(...),
///     ),
///   ],
/// )
/// ```
/// 
/// The child will be centered on the grid point at (column * dotSpacing, row * dotSpacing).
class ZenGridPositioned extends StatelessWidget {
  /// Grid column (0-indexed from left edge)
  final int column;
  
  /// Grid row (0-indexed from top edge)
  final int row;
  
  /// Width of the child widget (required for centering calculation)
  final double width;
  
  /// Height of the child widget (required for centering calculation)
  final double height;
  
  /// The widget to position on the grid
  final Widget child;

  const ZenGridPositioned({
    super.key,
    required this.column,
    required this.row,
    required this.width,
    required this.height,
    required this.child,
  });
  
  /// Create a positioned widget using grid units for width and height.
  /// 
  /// This ensures the widget scales properly with the zen paper grid.
  /// Width and height are calculated as `units * ZenGridConstants.dotSpacing`.
  factory ZenGridPositioned.gridUnits({
    Key? key,
    required int column,
    required int row,
    required int widthUnits,
    required int heightUnits,
    required Widget child,
  }) {
    final spacing = ZenGridConstants.dotSpacing;
    return ZenGridPositioned(
      key: key,
      column: column,
      row: row,
      width: widthUnits * spacing,
      height: heightUnits * spacing,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = ZenGridConstants.dotSpacing;
    
    // Calculate the same horizontal offset as ZenPaperBackground uses for centering
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalOffset = (screenWidth % spacing) / 2;
    
    // Position top-left corner at grid point, adjusted for centered grid
    return Positioned(
      left: horizontalOffset + (column * spacing),
      top: row * spacing,
      width: width,
      height: height,
      child: child,
    );
  }
}

/// A vertical line that connects two grid rows, centered on a column.
/// 
/// **Usage:**
/// ```dart
/// Stack(
///   children: [
///     ZenGridLine.vertical(
///       column: 4,
///       fromRow: 2,
///       toRow: 5,
///     ),
///   ],
/// )
/// ```
class ZenGridLine extends StatelessWidget {
  final int column;
  final int fromRow;
  final int toRow;
  final double thickness;
  final Color? color;
  final Widget? label;

  const ZenGridLine.vertical({
    super.key,
    required this.column,
    required this.fromRow,
    required this.toRow,
    this.thickness = 2.0,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ZenGridConstants.dotSpacing;
    final lineHeight = (toRow - fromRow) * spacing;
    final midY = fromRow * spacing + lineHeight / 2;
    
    // Calculate the same horizontal offset as ZenPaperBackground
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalOffset = (screenWidth % spacing) / 2;
    final xPos = horizontalOffset + (column * spacing);
    
    if (label == null) {
      // Simple line without label
      return Positioned(
        left: xPos - (thickness / 2),
        top: fromRow * spacing,
        width: thickness,
        height: lineHeight,
        child: Container(
          color: color ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.4),
        ),
      );
    }
    
    // Line with label at midpoint - draw two half-lines with label in between
    return Stack(
      children: [
        // Top half of line
        Positioned(
          left: xPos - (thickness / 2),
          top: fromRow * spacing,
          width: thickness,
          height: lineHeight / 2 - 10, // Leave space for label
          child: Container(
            color: color ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        // Label at midpoint
        Positioned(
          left: xPos - 30, // Center label (assuming ~60px width)
          top: midY - 10, // Center vertically
          width: 60,
          height: 20,
          child: Center(child: label!),
        ),
        // Bottom half of line
        Positioned(
          left: xPos - (thickness / 2),
          top: midY + 10, // After label
          width: thickness,
          height: lineHeight / 2 - 10, // Leave space for label
          child: Container(
            color: color ?? QuanityaPalette.primary.textSecondary.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

/// A dot marker centered on a grid point (useful for debugging alignment).
/// 
/// **Usage:**
/// ```dart
/// ZenGridDot(column: 4, row: 2)
/// ```
class ZenGridDot extends StatelessWidget {
  final int column;
  final int row;
  final double size;
  final Color color;

  const ZenGridDot({
    super.key,
    required this.column,
    required this.row,
    this.size = 6.0,
    this.color = const Color(0xFFBC4B41),
  });

  @override
  Widget build(BuildContext context) {
    final spacing = ZenGridConstants.dotSpacing;
    
    return Positioned(
      left: (column * spacing) - (size / 2),
      top: (row * spacing) - (size / 2),
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
