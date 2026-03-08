import 'package:injectable/injectable.dart';

import '../../enums/field_enum.dart';
import '../../models/shared/template_field.dart';
import 'field_validators.dart';

/// Single source of truth for all default value logic.
///
/// Handles:
/// - Type-safe fallback defaults
/// - Resolution priority: field.defaultValue → type default → first option
/// - Validation against field type and validators
/// - Parsing from JSON (AI responses)
/// - Schema generation for AI (subset of types)
@injectable
class DefaultValueHandler {
  /// Field types that support defaults in AI schema.
  /// Manual editor supports all types except reference.
  static const aiSupportedTypes = {
    FieldEnum.integer,
    FieldEnum.float,
    FieldEnum.text,
  };

  /// Field types that support defaults in manual editor.
  static const manualSupportedTypes = {
    FieldEnum.integer,
    FieldEnum.float,
    FieldEnum.text,
    FieldEnum.boolean,
    FieldEnum.datetime,
    FieldEnum.enumerated,
    FieldEnum.dimension,
  };

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  /// Get type-safe fallback default when no explicit default is set.
  dynamic getTypeDefault(FieldEnum type) {
    return switch (type) {
      FieldEnum.integer => 0,
      FieldEnum.float => 0.0,
      FieldEnum.boolean => false,
      FieldEnum.text => '',
      FieldEnum.datetime => null,
      FieldEnum.enumerated => null, // First option handled at resolve time
      FieldEnum.dimension => 0.0,
      FieldEnum.reference => null,
      FieldEnum.location => null,
    };
  }

  /// Resolve actual default value for a field.
  ///
  /// Priority:
  /// 1. field.defaultValue (if set)
  /// 2. First option (for enumerated fields)
  /// 3. Type default
  ///
  /// List fields always return empty list.
  dynamic resolveDefault(TemplateField field) {
    if (field.isList) return <dynamic>[];
    if (field.defaultValue != null) return field.defaultValue;
    if (field.type == FieldEnum.enumerated) return field.options?.firstOrNull;
    return getTypeDefault(field.type);
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Validate a default value against field type and validators.
  ///
  /// Returns error message if invalid, null if valid.
  /// Null value is always valid (means "no default").
  String? validateDefault(dynamic value, TemplateField field) {
    if (value == null) return null;

    // Type check first
    final typeError = _validateType(value, field.type);
    if (typeError != null) return typeError;

    // Enumerated: must be in options
    if (field.type == FieldEnum.enumerated) {
      if (field.options == null || !field.options!.contains(value)) {
        return 'Must be one of: ${field.options?.join(", ") ?? "no options"}';
      }
      return null;
    }

    // Run through field validators
    final validator = FieldValidators.forField(
      label: 'Default value',
      validators: field.validators,
      isRequired: false,
    );
    return validator(value);
  }

  /// Validate value matches expected type.
  String? _validateType(dynamic value, FieldEnum type) {
    return switch (type) {
      FieldEnum.integer => value is int ? null : 'Must be an integer',
      FieldEnum.float => value is num ? null : 'Must be a number',
      FieldEnum.boolean => value is bool ? null : 'Must be true or false',
      FieldEnum.text => value is String ? null : 'Must be text',
      FieldEnum.datetime => value is String ? null : 'Must be ISO date string',
      FieldEnum.enumerated => value is String ? null : 'Must be text',
      FieldEnum.dimension => value is num ? null : 'Must be a number',
      FieldEnum.reference => 'References cannot have defaults',
      FieldEnum.location => 'Locations cannot have defaults',
    };
  }

  // ---------------------------------------------------------------------------
  // Parsing (from AI JSON)
  // ---------------------------------------------------------------------------

  /// Parse raw JSON value into typed default.
  ///
  /// Returns null if parsing fails or type unsupported.
  dynamic parseDefault(dynamic raw, FieldEnum type) {
    if (raw == null) return null;

    return switch (type) {
      FieldEnum.integer => _parseInt(raw),
      FieldEnum.float => _parseDouble(raw),
      FieldEnum.boolean => _parseBool(raw),
      FieldEnum.text => '$raw',
      FieldEnum.datetime => raw is String ? raw : null,
      FieldEnum.enumerated => '$raw',
      FieldEnum.dimension => _parseDouble(raw),
      FieldEnum.reference => null,
      FieldEnum.location => null,
    };
  }

  int? _parseInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse('$raw');
  }

  double? _parseDouble(dynamic raw) {
    if (raw is double) return raw;
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw');
  }

  bool? _parseBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return null;
  }

  // ---------------------------------------------------------------------------
  // Schema Generation (for AI)
  // ---------------------------------------------------------------------------

  /// Check if field type supports defaults in AI schema.
  bool supportsAiDefault(FieldEnum type) => aiSupportedTypes.contains(type);

  /// Check if field type supports defaults in manual editor.
  bool supportsManualDefault(FieldEnum type) =>
      manualSupportedTypes.contains(type);

  /// Generate JSON schema for defaultValue based on field type.
  ///
  /// Only generates for AI-supported types (integer, float, text).
  /// Returns null for unsupported types.
  Map<String, dynamic>? buildAiSchema(FieldEnum type, Map<String, dynamic>? args) {
    if (!supportsAiDefault(type)) return null;

    final minVal = args?['min'];
    final maxVal = args?['max'];
    final maxLength = args?['maxLength'];

    return switch (type) {
      FieldEnum.integer => {
        'type': 'integer',
        if (minVal != null) 'minimum': minVal,
        if (maxVal != null) 'maximum': maxVal,
        'description': 'Optional pre-filled value for quicklog',
      },
      FieldEnum.float => {
        'type': 'number',
        if (minVal != null) 'minimum': minVal,
        if (maxVal != null) 'maximum': maxVal,
        'description': 'Optional pre-filled value for quicklog',
      },
      FieldEnum.text => {
        'type': 'string',
        if (maxLength != null) 'maxLength': maxLength,
        'description': 'Optional pre-filled value for quicklog',
      },
      _ => null,
    };
  }
}
