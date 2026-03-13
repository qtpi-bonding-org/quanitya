import 'package:flutter/material.dart';
import '../../primitives/quanitya_palette.dart';
import '../zen_grid_positioned.dart';
import '../mvs_type_badge.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';

/// Standardized analytics connection line with MVS type label
/// 
/// Always 2 units tall with label at midpoint, following the zen grid pattern.
class AnalyticsConnectionLine extends StatelessWidget {
  final int column;
  final int fromRow;
  final AnalysisDataType type;
  
  const AnalyticsConnectionLine({
    super.key,
    required this.column,
    required this.fromRow,
    required this.type,
  });
  
  @override
  Widget build(BuildContext context) {
    // Standard 2-unit connection line
    final toRow = fromRow + 2;

    return ExcludeSemantics(
      child: ZenGridLine.vertical(
        column: column,
        fromRow: fromRow,
        toRow: toRow,
        color: QuanityaPalette.primary.textSecondary.withValues(alpha: 0.3),
        label: MvsTypeBadge(type: type),
      ),
    );
  }
}