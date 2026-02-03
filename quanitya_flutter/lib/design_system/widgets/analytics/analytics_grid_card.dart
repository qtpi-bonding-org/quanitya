import 'package:flutter/material.dart';
import '../../primitives/app_sizes.dart';
import '../../primitives/quanitya_palette.dart';
import '../zen_grid_positioned.dart';
import '../../../support/extensions/context_extensions.dart';

/// Grid-positioned analytics card that follows the standardized pattern
/// 
/// Always uses 2×5 unit size for consistency across the analytics pipeline.
/// Automatically handles zen grid positioning and Quanitya styling.
class AnalyticsGridCard extends StatelessWidget {
  final String label;
  final int column;
  final int row;
  final bool isResult;
  
  const AnalyticsGridCard({
    super.key,
    required this.label,
    required this.column,
    required this.row,
    this.isResult = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return ZenGridPositioned.gridUnits(
      column: column,
      row: row,
      widthUnits: 5,  // Standard width
      heightUnits: 2, // Standard height
      child: Container(
        decoration: BoxDecoration(
          color: QuanityaPalette.primary.backgroundPrimary,
          border: Border.all(
            color: isResult 
                ? QuanityaPalette.primary.interactableColor.withValues(alpha: 0.4)
                : QuanityaPalette.primary.textSecondary.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: context.text.bodyMedium?.copyWith(
            color: isResult
                ? QuanityaPalette.primary.interactableColor
                : QuanityaPalette.primary.textPrimary,
          ),
        ),
      ),
    );
  }
}