import 'package:flutter/material.dart';
import '../primitives/quanitya_palette.dart';
import '../primitives/quanitya_fonts.dart';
import '../../support/extensions/context_extensions.dart';
import '../../logic/analytics/models/matrix_vector_scalar/analysis_data_type.dart';

/// Minimal MVS type notation badge - no container, just typography.
/// 
/// Displays the mathematical notation for data types:
/// - `[{t,x}]` = Time Series Matrix
/// - `[x]` = Value Vector  
/// - `[t]` = Timestamp Vector
/// - `x` = Scalar
/// - `[c]` = Category Vector
/// 
/// **Usage:**
/// ```dart
/// MvsTypeBadge(type: AnalysisDataType.timeSeriesMatrix)
/// MvsTypeBadge(type: AnalysisDataType.valueVector)
/// ```
class MvsTypeBadge extends StatelessWidget {
  final AnalysisDataType type;
  final bool showLabel;
  
  const MvsTypeBadge({
    super.key,
    required this.type,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final notation = _getNotation(type);
    final color = _getColor(type);
    final label = showLabel ? _getLabel(type) : null;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          notation,
          style: context.text.bodySmall?.copyWith(
            color: color,
            fontFamily: QuanityaFonts.bodyFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
  
  String _getNotation(AnalysisDataType type) {
    return switch (type) {
      AnalysisDataType.timeSeriesMatrix => '[{t,x}]',
      AnalysisDataType.valueVector => '[x]',
      AnalysisDataType.timestampVector => '[t]',
      AnalysisDataType.statScalar => 'x',
      AnalysisDataType.categoryVector => '[c]',
    };
  }
  
  String _getLabel(AnalysisDataType type) {
    return switch (type) {
      AnalysisDataType.timeSeriesMatrix => 'matrix',
      AnalysisDataType.valueVector => 'values',
      AnalysisDataType.timestampVector => 'times',
      AnalysisDataType.statScalar => 'scalar',
      AnalysisDataType.categoryVector => 'categories',
    };
  }
  
  Color _getColor(AnalysisDataType type) {
    return switch (type) {
      AnalysisDataType.timeSeriesMatrix => QuanityaPalette.primary.interactableColor,
      AnalysisDataType.valueVector => QuanityaPalette.primary.interactableColor,
      AnalysisDataType.timestampVector => QuanityaPalette.primary.textSecondary,
      AnalysisDataType.statScalar => QuanityaPalette.primary.errorColor,
      AnalysisDataType.categoryVector => QuanityaPalette.primary.successColor,
    };
  }
}

/// Inline MVS type indicator for use in text or between elements.
/// 
/// Shows notation in a subtle, non-intrusive way that fits the zen paper aesthetic.
class MvsTypeIndicator extends StatelessWidget {
  final AnalysisDataType type;
  
  const MvsTypeIndicator({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final notation = _getNotation(type);
    final color = _getColor(type);
    
    return Text(
      notation,
      style: context.text.labelSmall?.copyWith(
        color: color.withValues(alpha: 0.6),
        fontFamily: QuanityaFonts.bodyFamily,
        letterSpacing: 1,
      ),
    );
  }
  
  String _getNotation(AnalysisDataType type) {
    return switch (type) {
      AnalysisDataType.timeSeriesMatrix => '[{t,x}]',
      AnalysisDataType.valueVector => '[x]',
      AnalysisDataType.timestampVector => '[t]',
      AnalysisDataType.statScalar => 'x',
      AnalysisDataType.categoryVector => '[c]',
    };
  }
  
  Color _getColor(AnalysisDataType type) {
    return switch (type) {
      AnalysisDataType.timeSeriesMatrix => QuanityaPalette.primary.interactableColor,
      AnalysisDataType.valueVector => QuanityaPalette.primary.interactableColor,
      AnalysisDataType.timestampVector => QuanityaPalette.primary.textSecondary,
      AnalysisDataType.statScalar => QuanityaPalette.primary.errorColor,
      AnalysisDataType.categoryVector => QuanityaPalette.primary.successColor,
    };
  }
}
