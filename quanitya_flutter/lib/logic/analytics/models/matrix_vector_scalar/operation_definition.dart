import 'package:freezed_annotation/freezed_annotation.dart';
import 'analysis_data_type.dart';

part 'operation_definition.freezed.dart';
part 'operation_definition.g.dart';

/// Definition of an analysis operation with type constraints.
///
/// Provides metadata for UI builders and validation systems to ensure
/// type-safe pipeline construction.
@freezed
class OperationDefinition with _$OperationDefinition {
  const factory OperationDefinition({
    /// Human-readable label for UI display
    required String label,
    
    /// Expected input data type
    required AnalysisDataType inputType,
    
    /// Produced output data type
    required AnalysisDataType outputType,
    
    /// Number of inputs required (1 for normal, 2+ for combiners)
    @Default(1) int inputCount,
    
    /// Required parameter names for this operation
    @Default([]) List<String> requiredParams,
    
    /// Optional parameter names for this operation
    @Default([]) List<String> optionalParams,
    
    /// Human-readable description of what this operation does
    required String description,
    
    /// Category for grouping operations in UI
    @Default('General') String category,
    
    /// Whether this operation is deprecated
    @Default(false) bool isDeprecated,
  }) = _OperationDefinition;
  
  factory OperationDefinition.fromJson(Map<String, dynamic> json) =>
      _$OperationDefinitionFromJson(json);
}

/// Extension methods for OperationDefinition convenience.
extension OperationDefinitionExt on OperationDefinition {
  /// Get all parameter names (required + optional)
  List<String> get allParams => [...requiredParams, ...optionalParams];
  
  /// Check if operation has any parameters
  bool get hasParams => requiredParams.isNotEmpty || optionalParams.isNotEmpty;
  
  /// Check if operation requires specific parameter
  bool requiresParam(String paramName) => requiredParams.contains(paramName);
  
  /// Check if operation accepts specific parameter
  bool acceptsParam(String paramName) => allParams.contains(paramName);
  
  /// Check if this operation can follow another operation (type compatibility)
  bool canFollow(OperationDefinition other) => inputType == other.outputType;
  
  /// Get type transition description for UI
  String get typeTransition => '${inputType.name} → ${outputType.name}';
  
  /// Check if this is a multi-input combiner operation
  bool get isCombiner => inputCount > 1;
}