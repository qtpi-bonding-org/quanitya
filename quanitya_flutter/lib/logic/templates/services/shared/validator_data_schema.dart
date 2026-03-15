import '../../models/shared/field_validator.dart';

/// Validates that [FieldValidator.validatorData] has the correct structure
/// for its [ValidatorType].
///
/// Call at template save time to catch misconfigured validators early,
/// not on every log entry write.
class ValidatorDataSchema {
  ValidatorDataSchema._();

  /// Returns error message if [data] has wrong structure for [type].
  /// Returns null if valid.
  static String? validate(ValidatorType type, Map<String, dynamic> data) {
    return switch (type) {
      ValidatorType.optional => null,
      ValidatorType.numeric => _validateNumeric(data),
      ValidatorType.text => _validateText(data),
      ValidatorType.enumerated => _validateEnumerated(data),
      ValidatorType.dimension => _validateDimension(data),
      ValidatorType.reference => null,
      ValidatorType.custom => null,
      ValidatorType.list => _validateList(data),
    };
  }

  static String? _validateNumeric(Map<String, dynamic> data) {
    if (data.containsKey('min') && data['min'] is! num) {
      return 'numeric.min must be a number';
    }
    if (data.containsKey('max') && data['max'] is! num) {
      return 'numeric.max must be a number';
    }
    if (data.containsKey('allowDecimals') && data['allowDecimals'] is! bool) {
      return 'numeric.allowDecimals must be a boolean';
    }
    return null;
  }

  static String? _validateText(Map<String, dynamic> data) {
    if (data.containsKey('minLength') && data['minLength'] is! int) {
      return 'text.minLength must be an integer';
    }
    if (data.containsKey('maxLength') && data['maxLength'] is! int) {
      return 'text.maxLength must be an integer';
    }
    if (data.containsKey('pattern') && data['pattern'] is! String) {
      return 'text.pattern must be a string';
    }
    return null;
  }

  static String? _validateEnumerated(Map<String, dynamic> data) {
    if (data.containsKey('options')) {
      final options = data['options'];
      if (options is! List) return 'enumerated.options must be a list';
      if (options.any((o) => o is! String)) {
        return 'enumerated.options must contain only strings';
      }
    }
    return null;
  }

  static String? _validateDimension(Map<String, dynamic> data) {
    if (data.containsKey('minValue') && data['minValue'] is! num) {
      return 'dimension.minValue must be a number';
    }
    if (data.containsKey('maxValue') && data['maxValue'] is! num) {
      return 'dimension.maxValue must be a number';
    }
    return null;
  }

  static String? _validateList(Map<String, dynamic> data) {
    if (data.containsKey('minItems') && data['minItems'] is! int) {
      return 'list.minItems must be an integer';
    }
    if (data.containsKey('maxItems') && data['maxItems'] is! int) {
      return 'list.maxItems must be an integer';
    }
    return null;
  }
}
