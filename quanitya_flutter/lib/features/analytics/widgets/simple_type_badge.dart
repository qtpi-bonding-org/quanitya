import 'package:flutter/material.dart';
import '../../../design_system/primitives/app_sizes.dart';
import '../../../design_system/primitives/quanitya_palette.dart';
import '../../../design_system/primitives/quanitya_fonts.dart';
import '../../../support/extensions/context_extensions.dart';
import '../../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';

/// Simple type badge showing MVS data type notation
/// 
/// Displays mathematical notation for data types:
/// - [{t,x}] for TimeSeriesMatrix
/// - [t] for TimestampVector  
/// - [x] for ValueVector
/// - x for StatScalar
class SimpleTypeBadge extends StatelessWidget {
  final AnalysisDataType type;
  final bool isValid;
  
  const SimpleTypeBadge({
    super.key,
    required this.type,
    this.isValid = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      AnalysisDataType.timeSeriesMatrix => '[{t,x}]',
      AnalysisDataType.timestampVector => '[t]',
      AnalysisDataType.valueVector => '[x]',
      AnalysisDataType.statScalar => 'x',
      AnalysisDataType.categoryVector => '[c]',
    };
    
    final color = isValid 
      ? QuanityaPalette.primary.textPrimary
      : QuanityaPalette.primary.errorColor;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: color,
          fontFamily: QuanityaFonts.bodyFamily,
        ),
      ),
    );
  }
}