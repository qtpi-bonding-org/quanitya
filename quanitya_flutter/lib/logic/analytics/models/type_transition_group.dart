import 'package:freezed_annotation/freezed_annotation.dart';
import 'matrix_vector_scalar/analysis_data_type.dart';
import '../enums/calculation.dart';

part 'type_transition_group.freezed.dart';

/// Operations grouped by their input→output type transition.
/// Single source of truth for both AI schema and UI.
@freezed
class TypeTransitionGroup with _$TypeTransitionGroup {
  const factory TypeTransitionGroup({
    required AnalysisDataType fromType,
    required AnalysisDataType toType,
    required List<Calculation> operations,
  }) = _TypeTransitionGroup;

  const TypeTransitionGroup._();

  /// Unique key for this transition (e.g., "timeSeriesMatrix_to_valueVector")
  String get key => '${fromType.name}_to_${toType.name}';

  /// Human-readable label (e.g., "timeSeriesMatrix → valueVector")
  String get label => '${fromType.name} → ${toType.name}';

  /// Check if this group contains a specific operation
  bool contains(Calculation op) => operations.contains(op);
}
