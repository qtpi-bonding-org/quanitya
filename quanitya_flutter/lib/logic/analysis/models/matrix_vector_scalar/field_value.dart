import 'package:freezed_annotation/freezed_annotation.dart';
import 'type_definitions.dart';

part 'field_value.freezed.dart';
part 'field_value.g.dart';

/// Generic field value that can be either numeric or categorical.
///
/// This enables TimeSeriesMatrix to handle mixed data types:
/// - Numeric: mood scores, heart rate, temperature
/// - Categorical: mood labels, exercise types, weather conditions
@freezed
abstract class FieldValue with _$FieldValue {
  const FieldValue._();
  const factory FieldValue.numeric(Numeric value) = _NumericFieldValue;
  const factory FieldValue.categorical(String value) = _CategoricalFieldValue;
  
  factory FieldValue.fromJson(Map<String, dynamic> json) =>
      _$FieldValueFromJson(json);
}

/// Extension methods for FieldValue operations.
extension FieldValueExt on FieldValue {
  /// Check if this is a numeric value
  bool get isNumeric => map(
    numeric: (_) => true,
    categorical: (_) => false,
  );
  
  /// Check if this is a categorical value
  bool get isCategorical => map(
    numeric: (_) => false,
    categorical: (_) => true,
  );
  
  /// Get as numeric value (throws if categorical)
  Numeric get asNumeric => map(
    numeric: (n) => n.value,
    categorical: (_) => throw StateError('Cannot convert categorical to numeric'),
  );
  
  /// Get as categorical value (throws if numeric)
  String get asCategorical => map(
    numeric: (_) => throw StateError('Cannot convert numeric to categorical'),
    categorical: (c) => c.value,
  );
  
  /// Get as string representation
  String get asString => map(
    numeric: (n) => n.value.toString(),
    categorical: (c) => c.value,
  );
  
  /// Convert to double for matrix storage (categorical gets encoded)
  /// Note: This requires a category encoder for categorical values
  double toDouble([Map<String, int>? categoryEncoder]) => map(
    numeric: (n) => n.value.toDouble(),
    categorical: (c) {
      if (categoryEncoder == null) {
        throw ArgumentError('Category encoder required for categorical values');
      }
      final encoded = categoryEncoder[c.value];
      if (encoded == null) {
        throw ArgumentError('Category "$value" not found in encoder');
      }
      return encoded.toDouble();
    },
  );
}

/// Type alias for lists of field values
typedef FieldValueList = List<FieldValue>;

/// Helper functions for creating field values
extension FieldValueHelpers on Object {
  /// Convert various types to FieldValue
  FieldValue toFieldValue() {
    if (this is num) {
      return FieldValue.numeric(this as num);
    } else if (this is String) {
      return FieldValue.categorical(this as String);
    } else {
      throw ArgumentError('Cannot convert $runtimeType to FieldValue');
    }
  }
}