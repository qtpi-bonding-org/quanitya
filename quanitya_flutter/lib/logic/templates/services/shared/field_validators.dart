import '../../models/shared/field_validator.dart';

/// Function signature for field validators.
/// Returns error message if invalid, null if valid.
typedef ValidatorFn = String? Function(dynamic value);

/// Centralized field validation with composable validators.
///
/// Provides reusable validator functions that can be composed together
/// and built from [FieldValidator] models stored in templates.
///
/// Usage:
/// ```dart
/// final validator = FieldValidators.compose([
///   FieldValidators.required('Weight'),
///   FieldValidators.numeric(min: 0, max: 500, label: 'Weight'),
/// ]);
/// final error = validator(userInput); // null if valid
/// ```
class FieldValidators {
  FieldValidators._();

  // ─────────────────────────────────────────────────────────────────────────
  // Composition
  // ─────────────────────────────────────────────────────────────────────────

  /// Compose multiple validators into one.
  /// Returns first error encountered, or null if all pass.
  static ValidatorFn compose(List<ValidatorFn> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Build a composed validator from [FieldValidator] models.
  /// Validators are sorted by [validatorOrder] before composition.
  static ValidatorFn fromFieldValidators(
    List<FieldValidator> validators,
    String label,
  ) {
    if (validators.isEmpty) return (_) => null;

    final sorted = [...validators]
      ..sort((a, b) => a.validatorOrder.compareTo(b.validatorOrder));

    return compose(
      sorted.map((v) => _fromModel(v, label)).toList(),
    );
  }

  /// Build validator for a field, including required check.
  static ValidatorFn forField({
    required String label,
    required List<FieldValidator> validators,
    bool isRequired = true,
  }) {
    final fns = <ValidatorFn>[];

    if (isRequired) {
      fns.add(required(label));
    }

    if (validators.isNotEmpty) {
      fns.add(fromFieldValidators(validators, label));
    }

    return compose(fns);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Individual Validators
  // ─────────────────────────────────────────────────────────────────────────

  /// Validates that value is not null or empty.
  static ValidatorFn required(String label) {
    return (value) {
      if (value == null) return '$label is required';
      if (value is String && value.isEmpty) return '$label is required';
      return null;
    };
  }

  /// Validates numeric values with optional min/max bounds.
  static ValidatorFn numeric({
    num? min,
    num? max,
    bool allowDecimals = true,
    required String label,
  }) {
    return (value) {
      if (value == null) return null; // Let required() handle null

      if (value is! num) return '$label must be a number';

      if (!allowDecimals && value is double && value != value.roundToDouble()) {
        return '$label must be a whole number';
      }

      if (min != null && value < min) {
        return '$label must be at least $min';
      }
      if (max != null && value > max) {
        return '$label must be at most $max';
      }

      return null;
    };
  }

  /// Validates text values with optional length constraints and pattern.
  static ValidatorFn text({
    int? minLength,
    int? maxLength,
    String? pattern,
    required String label,
  }) {
    return (value) {
      if (value == null) return null; // Let required() handle null

      if (value is! String) return '$label must be text';

      if (minLength != null && value.length < minLength) {
        return '$label must be at least $minLength characters';
      }
      if (maxLength != null && value.length > maxLength) {
        return '$label must be at most $maxLength characters';
      }

      if (pattern != null) {
        final regex = RegExp(pattern);
        if (!regex.hasMatch(value)) {
          return '$label has invalid format';
        }
      }

      return null;
    };
  }

  /// Validates that value is one of the allowed options.
  static ValidatorFn enumerated({
    required List<String> options,
    required String label,
  }) {
    return (value) {
      if (value == null) return null; // Let required() handle null

      if (!options.contains(value)) {
        return '$label must be one of: ${options.join(', ')}';
      }

      return null;
    };
  }

  /// Validates dimension values (numeric with optional bounds).
  static ValidatorFn dimension({
    num? minValue,
    num? maxValue,
    required String label,
  }) {
    return (value) {
      if (value == null) return null;
      if (value is! num) return '$label must be a number';

      if (minValue != null && value < minValue) {
        return '$label must be at least $minValue';
      }
      if (maxValue != null && value > maxValue) {
        return '$label must be at most $maxValue';
      }

      return null;
    };
  }

  /// Validates reference field (must be a non-empty string ID).
  static ValidatorFn reference({required String label}) {
    return (value) {
      if (value == null) return null;
      if (value is! String) return '$label must be a reference ID';
      if (value.isEmpty) return '$label reference cannot be empty';
      return null;
    };
  }

  /// Validates list field length constraints.
  static ValidatorFn list({
    int? minItems,
    int? maxItems,
    required String label,
  }) {
    return (value) {
      if (value == null) return null; // Let required() handle null

      if (value is! List) {
        return '$label must be a list';
      }

      final length = value.length;

      if (minItems != null && length < minItems) {
        return '$label must have at least $minItems item${minItems == 1 ? '' : 's'}';
      }

      if (maxItems != null && length > maxItems) {
        return '$label must have at most $maxItems item${maxItems == 1 ? '' : 's'}';
      }

      return null;
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Model Conversion
  // ─────────────────────────────────────────────────────────────────────────

  static ValidatorFn _fromModel(FieldValidator v, String label) {
    final data = v.validatorData;
    final customMsg = v.customMessage;

    // Wrap with custom message if provided
    ValidatorFn wrap(ValidatorFn fn) {
      if (customMsg == null) return fn;
      return (value) {
        final error = fn(value);
        return error != null ? customMsg : null;
      };
    }

    return switch (v.validatorType) {
      ValidatorType.optional => (_) => null,
      ValidatorType.numeric => wrap(numeric(
          min: data['min'] as num?,
          max: data['max'] as num?,
          allowDecimals: data['allowDecimals'] as bool? ?? true,
          label: label,
        )),
      ValidatorType.text => wrap(text(
          minLength: data['minLength'] as int?,
          maxLength: data['maxLength'] as int?,
          pattern: data['pattern'] as String?,
          label: label,
        )),
      ValidatorType.enumerated => wrap(enumerated(
          options: (data['options'] as List<dynamic>?)?.cast<String>() ?? [],
          label: label,
        )),
      ValidatorType.dimension => wrap(dimension(
          minValue: data['minValue'] as num?,
          maxValue: data['maxValue'] as num?,
          label: label,
        )),
      ValidatorType.reference => wrap(reference(label: label)),
      ValidatorType.custom => (_) => throw UnimplementedError(
        'Custom validator "${data['name'] ?? 'unnamed'}" is not implemented.',
      ),
      ValidatorType.list => wrap(list(
          minItems: data['minItems'] as int?,
          maxItems: data['maxItems'] as int?,
          label: label,
        )),
    };
  }
}
