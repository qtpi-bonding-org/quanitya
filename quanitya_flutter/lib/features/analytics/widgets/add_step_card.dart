import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/zen_grid_constants.dart';
import '../../../design_system/widgets/zen_grid_positioned.dart';
import '../../../support/extensions/context_extensions.dart';

/// Add step card with dashed border for adding new pipeline steps
/// 
/// Uses zen grid units for sizing:
/// - Width: 5 grid units (capped)
/// - Height: 2 grid units
class AddStepCard extends StatelessWidget {
  final int column;
  final int row;
  final int widthUnits;
  final int heightUnits;
  final VoidCallback? onTap;
  final String? subtitle;
  
  const AddStepCard({
    super.key,
    required this.column,
    required this.row,
    this.widthUnits = 6, // 6 units wide (even number for perfect centering)
    this.heightUnits = 2, // 2 units tall
    this.onTap,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    final gridSpacing = ZenGridConstants.dotSpacing;
    final cardWidth = widthUnits * gridSpacing;
    final cardHeight = heightUnits * gridSpacing;
    
    return ZenGridPositioned(
      column: column,
      row: row,
      width: cardWidth,
      height: cardHeight,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.5),
            radius: AppSizes.radiusMedium,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent, // Transparent like journal writing
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: gridSpacing,
                    height: gridSpacing,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: QuanityaPalette.primary.interactableColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: gridSpacing * 0.6,
                      color: QuanityaPalette.primary.interactableColor,
                    ),
                  ),
                  SizedBox(width: gridSpacing * 0.3),
                  Text(
                    'Add Step',
                    style: context.text.bodyMedium?.copyWith(
                      color: QuanityaPalette.primary.interactableColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed border
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  }) : dashWidth = 6.0,
       dashSpace = 4.0;
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    
    _drawDashedRRect(canvas, paint, rrect);
  }
  
  void _drawDashedRRect(Canvas canvas, Paint paint, RRect rrect) {
    final path = Path()..addRRect(rrect);
    
    final pathMetrics = path.computeMetrics();
    for (final pathMetric in pathMetrics) {
      double distance = 0.0;
      bool draw = true;
      
      while (distance < pathMetric.length) {
        final length = draw ? dashWidth : dashSpace;
        final nextDistance = (distance + length).clamp(0.0, pathMetric.length);
        
        if (draw) {
          final extractPath = pathMetric.extractPath(distance, nextDistance);
          canvas.drawPath(extractPath, paint);
        }
        
        distance = nextDistance;
        draw = !draw;
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}