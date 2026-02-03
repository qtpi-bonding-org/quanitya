import 'package:freezed_annotation/freezed_annotation.dart';

part 'type_transition.freezed.dart';
part 'type_transition.g.dart';

/// Represents an operation as an edge in the type graph.
///
/// Models the transition from one data type to another via a specific operation.
/// Used by MvsGraphSchemaGenerator to build dynamic JSON schemas.
@freezed
class TypeTransition with _$TypeTransition {
  const factory TypeTransition({
    required String operation,
    required String fromType,
    required String toType,
    required List<String> requiredParams,
    required String label,
    required String description,
    required String category,
    required int inputCount,
  }) = _TypeTransition;
  
  factory TypeTransition.fromJson(Map<String, dynamic> json) => 
      _$TypeTransitionFromJson(json);
}

/// Extension methods for TypeTransition operations.
extension TypeTransitionExt on TypeTransition {
  /// Check if this is a serial operation (single input)
  bool get isSerial => inputCount == 1;
  
  /// Check if this is a combiner operation (multiple inputs)
  bool get isCombiner => inputCount > 1;
  
  /// Check if this operation has required parameters
  bool get hasRequiredParams => requiredParams.isNotEmpty;
  
  /// Get parameter schema type for a specific parameter
  Map<String, dynamic> getParameterSchema(String paramName) {
    return switch (paramName) {
      'fieldName' => {'type': 'string', 'minLength': 1},
      'percentile' => {'type': 'number', 'minimum': 0, 'maximum': 100},
      'windowDays' => {'type': 'integer', 'minimum': 1},
      'category' => {'type': 'string', 'minLength': 1},
      'operator' => {'enum': ['equals', 'greaterThan', 'lessThan', 'contains']},
      'value' => {'type': ['string', 'number']},
      'mapping' => {'type': 'object', 'additionalProperties': {'type': 'string'}},
      _ => {'type': ['string', 'number']},
    };
  }
}