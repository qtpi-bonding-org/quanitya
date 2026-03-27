import 'package:freezed_annotation/freezed_annotation.dart';
import 'type_definitions.dart';

part 'stat_scalar.freezed.dart';
part 'stat_scalar.g.dart';

/// Single statistical result value.
///
/// Wraps a numeric value with convenience methods for formatting
/// and type conversion.
@freezed
abstract class StatScalar with _$StatScalar {
  const StatScalar._();
  const factory StatScalar(Scalar value) = _StatScalar;
  
  factory StatScalar.fromJson(Map<String, dynamic> json) => 
      _$StatScalarFromJson(json);
}

/// Extension methods for StatScalar convenience operations.
extension StatScalarExt on StatScalar {
  /// Convert to double
  double get asDouble => value.toDouble();
  
  /// Convert to int
  int get asInt => value.toInt();
  
  /// Format with 2 decimal places
  String get formatted => value.toStringAsFixed(2);
  
  /// Check if value is zero
  bool get isZero => value == 0;
  
  /// Check if value is positive
  bool get isPositive => value > 0;
  
  /// Check if value is negative
  bool get isNegative => value < 0;
}