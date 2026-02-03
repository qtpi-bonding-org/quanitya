import 'package:flutter/material.dart';
import '../../primitives/analytics_grid.dart';
import '../../primitives/zen_grid_constants.dart';
import '../../primitives/quanitya_palette.dart';
import '../../primitives/app_sizes.dart';

/// Horizontal pipeline connection line aligned to zen grid dots
/// 
/// Draws a horizontal line exactly 2 grid units (48px) that starts and ends
/// at zen paper dots. For side-by-side pipeline components or parallel flows.
/// Uses Quanitya design tokens for colors and sizing.
class AnalyticsHorizontalConnectionLine extends StatelessWidget {
  final bool isValid;
  final double? customWidth;
  
  const AnalyticsHorizontalConnectionLine({
    super.key,
    required this.isValid,
    this.customWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    // Always use 2 grid units unless custom width specified
    final width = customWidth ?? AnalyticsGrid.unit2; // 48px
    
    return SizedBox(
      width: width,
      height: AnalyticsGrid.unit1, // 1 grid unit height
      child: CustomPaint(
        painter: _HorizontalConnectionPainter(isValid: isValid, width: width),
      ),
    );
  }
}

class _HorizontalConnectionPainter extends CustomPainter {
  final bool isValid;
  final double width;
  
  const _HorizontalConnectionPainter({required this.isValid, required this.width});
  
  @override
  void paint(Canvas canvas, Size size) {
    final palette = QuanityaPalette.primary;
    final color = isValid 
      ? palette.textSecondary
      : palette.destructiveColor; // Use destructive color for errors
    
    final centerY = size.height / 2;
    final dotSpacing = ZenGridConstants.dotSpacing;
    
    // Main line - starts at first dot (dotSpacing) and ends at last dot
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = AppSizes.borderWidthThick; // Use design token
    
    // For 2 grid units (48px), line goes from dot at 24px to dot at 48px
    final startX = dotSpacing; // First grid dot
    final endX = width;        // Last grid dot (should be at 48px for 2 units)
    
    canvas.drawLine(
      Offset(startX, centerY),
      Offset(endX, centerY),
      linePaint,
    );
    
    // Draw dots at exact grid positions
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Start dot (at 24px) - slightly larger than zen paper dots
    canvas.drawCircle(
      Offset(startX, centerY),
      ZenGridConstants.dotRadius * 2,
      dotPaint,
    );
    
    // End dot (at 48px for 2 units)
    canvas.drawCircle(
      Offset(endX, centerY),
      ZenGridConstants.dotRadius * 2,
      dotPaint,
    );
    
    // Error indicator at center
    if (!isValid) {
      final midX = (startX + endX) / 2;
      
      final errorPaint = Paint()
        ..color = palette.destructiveColor
        ..style = PaintingStyle.fill;
      
      // Error circle size using icon sizing token
      canvas.drawCircle(
        Offset(midX, centerY), 
        AppSizes.iconSmall / 2, // 8px radius from 16px icon size
        errorPaint,
      );
      
      // X mark using semantic colors
      final xPaint = Paint()
        ..color = palette.backgroundPrimary // White/light background color
        ..strokeWidth = AppSizes.borderWidthThick
        ..strokeCap = StrokeCap.round;
      
      final offset = AppSizes.radiusTiny * 2; // 4px using design token
      canvas.drawLine(
        Offset(midX - offset, centerY - offset),
        Offset(midX + offset, centerY + offset),
        xPaint,
      );
      canvas.drawLine(
        Offset(midX + offset, centerY - offset),
        Offset(midX - offset, centerY + offset),
        xPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}