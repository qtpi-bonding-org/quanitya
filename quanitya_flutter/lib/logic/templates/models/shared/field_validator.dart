import 'package:freezed_annotation/freezed_annotation.dart';

part 'field_validator.freezed.dart';
part 'field_validator.g.dart';

/// Represents a validation rule for a TemplateField.
/// 
/// FieldValidator defines constraints and validation logic that should be
/// applied to user input. This is nested within TemplateField, so no ID or
/// field reference is needed.
@freezed
class FieldValidator with _$FieldValidator {
  const factory FieldValidator({
    /// Type of validation rule (required, numeric, text, etc.)
    required ValidatorType validatorType,
    
    /// Configuration data for the validator (JSON format)
    /// Structure varies by validatorType:
    /// - required: {"message": "This field is required"}
    /// - numeric: {"min": 0, "max": 100, "allowDecimals": true}
    /// - text: {"minLength": 1, "maxLength": 255, "pattern": "^[a-zA-Z]+$"}
    /// - dimension: {"minValue": 0, "maxValue": 500}
    required Map<String, dynamic> validatorData,
    
    /// Custom error message to display when validation fails (optional)
    String? customMessage,
    
    /// Execution order for multiple validators on same field (0 = first)
    @Default(0) int validatorOrder,
  }) = _FieldValidator;
  
  /// Creates a FieldValidator from JSON map
  factory FieldValidator.fromJson(Map<String, dynamic> json) => 
      _$FieldValidatorFromJson(json);
  
  /// Creates a FieldValidator with the specified type and data
  factory FieldValidator.create({
    required ValidatorType validatorType,
    required Map<String, dynamic> validatorData,
    String? customMessage,
    int validatorOrder = 0,
  }) => FieldValidator(
    validatorType: validatorType,
    validatorData: validatorData,
    customMessage: customMessage,
    validatorOrder: validatorOrder,
  );
}

/// Enumeration of available validator types
enum ValidatorType {
  /// Field is optional and can be empty or null
  optional,
  
  /// Numeric validation (min/max, decimal constraints)
  numeric,
  
  /// Text validation (length, pattern matching)
  text,
  
  /// Enumerated field validation (selection constraints)
  enumerated,
  
  /// Dimension field validation (unit and value constraints)
  dimension,
  
  /// Reference field validation (target template constraints)
  reference,
  
  /// Custom validation using registered validator functions
  custom,
  
  /// List field validation (minItems/maxItems constraints)
  /// Used when TemplateField.isList is true
  /// validatorData: {"minItems": int?, "maxItems": int?}
  list,
}