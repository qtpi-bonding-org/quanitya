import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/zen_grid_constants.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analytics/enums/time_resolution.dart';

/// Source data card showing field selection and time resolution
/// 
/// Uses zen grid units for sizing:
/// - Width: 5 grid units (capped)
/// - Height: 3 grid units (expands by integer increments if needed)
class SourceDataCard extends StatelessWidget {
  final String fieldName;
  final TimeResolution timeResolution;
  final int column;
  final int row;
  final int widthUnits;
  final int heightUnits;
  final ValueChanged<TimeResolution>? onTimeResolutionChanged;
  
  const SourceDataCard({
    super.key,
    required this.fieldName,
    required this.timeResolution,
    required this.column,
    required this.row,
    this.widthUnits = 12, // 12 units wide for better chart visibility
    this.heightUnits = 3, // 3 units tall by default
    this.onTimeResolutionChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    final gridSpacing = ZenGridConstants.dotSpacing;
    
    // Calculate the same horizontal offset as ZenPaperBackground uses for centering
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalOffset = (screenWidth % gridSpacing) / 2;
    
    final cardWidth = widthUnits * gridSpacing;
    final cardHeight = heightUnits * gridSpacing;
    
    // Use Positioned to place on the grid (same as ZenGridPositioned)
    return Positioned(
      left: horizontalOffset + (column * gridSpacing),
      top: row * gridSpacing,
      width: cardWidth,
      height: cardHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent like journal writing
          border: Border.all(
            color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: EdgeInsets.all(gridSpacing * 0.4), // ~10px padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field name header (use actual field name with fallback)
              Text(
                _getDisplayName(fieldName),
                style: context.text.headlineSmall?.copyWith(
                  color: QuanityaPalette.primary.textPrimary,
                ),
              ),
              
              SizedBox(height: gridSpacing * 0.3), // Small gap
              
              // Mini chart - takes all remaining space (transparent like journal)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Transparent like journal writing
                    border: Border.all(
                      color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: CustomPaint(
                    painter: _MiniChartPainter(),
                  ),
                ),
              ),
              
              SizedBox(height: gridSpacing * 0.3), // Small gap
              
              // Time Resolution label and dropdown
              Text(
                'Time Resolution',
                style: context.text.labelSmall?.copyWith(
                  color: QuanityaPalette.primary.textSecondary,
                ),
              ),
              
              SizedBox(height: gridSpacing * 0.1), // Tiny gap
              
              // Time Resolution Dropdown - fixed height
              SizedBox(
                height: gridSpacing * 1.2, // Fixed height ~1.2 grid units
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: gridSpacing * 0.3,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TimeResolution>(
                      value: timeResolution,
                      isDense: true,
                      isExpanded: true,
                      onChanged: (TimeResolution? newResolution) {
                        if (newResolution != null) {
                          onTimeResolutionChanged?.call(newResolution);
                        }
                      },
                      style: context.text.bodySmall?.copyWith(
                        color: QuanityaPalette.primary.textPrimary,
                      ),
                      items: TimeResolution.values.map((resolution) {
                        return DropdownMenuItem<TimeResolution>(
                          value: resolution,
                          child: Text(_getResolutionLabel(resolution)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
  
  String _getResolutionLabel(TimeResolution resolution) {
    return switch (resolution) {
      TimeResolution.second => '1s',
      TimeResolution.minute => '1m',
      TimeResolution.hour => '1h',
      TimeResolution.day => '1d',
      TimeResolution.week => '1w',
    };
  }
  
  /// Convert field ID to display name (fallback for UUIDs)
  String _getDisplayName(String fieldName) {
    // If it looks like a UUID or technical ID, provide a fallback
    if (fieldName.contains('-') && fieldName.length > 20) {
      return 'Data Field'; // Generic fallback
    }
    
    // If it's a technical field name, make it more readable
    if (fieldName.toLowerCase().contains('heart')) {
      return 'Heart Rate';
    } else if (fieldName.toLowerCase().contains('step')) {
      return 'Steps';
    } else if (fieldName.toLowerCase().contains('sleep')) {
      return 'Sleep';
    } else if (fieldName.toLowerCase().contains('weight')) {
      return 'Weight';
    }
    
    // Otherwise use the field name as-is
    return fieldName;
  }
}

/// Simple wave painter for mini chart
class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = QuanityaPalette.primary.textPrimary // Use textPrimary instead of white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    
    // Simple wave pattern
    for (var x = 0.0; x < size.width; x += 2) {
      final progress = x / size.width;
      final y = size.height * 0.5 + 
        (size.height * 0.2 * (0.5 * _sin(progress * 8) + 0.3 * _sin(progress * 5)));
      path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }
  
  double _sin(double x) {
    final normalized = x % (2 * 3.14159);
    return normalized < 3.14159 
        ? (normalized / 1.5708) - 1 
        : 1 - ((normalized - 3.14159) / 1.5708);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}