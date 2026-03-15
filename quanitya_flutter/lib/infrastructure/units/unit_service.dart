import 'package:injectable/injectable.dart';

import '../../logic/templates/enums/measurement_unit.dart';
import '../../logic/templates/models/dimension.dart';

/// Interface for unit management and dimensional analysis operations.
///
/// This service provides:
/// - Dimensional validation (is this unit compatible with this dimension?)
/// - Unit lookup by dimension
/// - Value formatting with units
///
/// Note: Unit conversion is intentionally NOT implemented in MVP.
/// The focus is on dimensional analysis and validation.
abstract class IUnitService {
  /// Returns all units that are compatible with the specified SI dimension.
  ///
  /// Example: For Dimension.M (mass), returns [kilograms, pounds, grams, ...]
  List<MeasurementUnit> getUnitsForDimension(Dimension dimension);

  /// Validates that a unit belongs to the specified SI dimension.
  ///
  /// Returns true if the unit's dimension matches the expected dimension.
  ///
  /// Example:
  /// ```dart
  /// isValidUnitForDimension(MeasurementUnit.kilograms, Dimension.M) // true
  /// isValidUnitForDimension(MeasurementUnit.meters, Dimension.M)    // false
  /// isValidUnitForDimension(MeasurementUnit.liters, Dimension.volume) // true
  /// ```
  bool isValidUnitForDimension(MeasurementUnit unit, Dimension dimension);

  /// Formats a value with its unit as a human-readable string.
  ///
  /// Example: format(100.5, MeasurementUnit.kilograms) returns "100.5 kg"
  String format(double value, MeasurementUnit unit);

  /// Returns the SI dimension for a given unit.
  ///
  /// Example: getDimension(MeasurementUnit.meters) returns Dimension.L
  Dimension getDimension(MeasurementUnit unit);

  /// Checks if two units are dimensionally compatible (can be converted).
  ///
  /// Example:
  /// ```dart
  /// areCompatible(MeasurementUnit.kilograms, MeasurementUnit.pounds) // true (both M¹)
  /// areCompatible(MeasurementUnit.meters, MeasurementUnit.feet)      // true (both L¹)
  /// areCompatible(MeasurementUnit.kilograms, MeasurementUnit.meters) // false
  /// ```
  bool areCompatible(MeasurementUnit unit1, MeasurementUnit unit2);
}

/// Concrete implementation of IUnitService.
///
/// Provides dimensional analysis and unit validation using the SI-based
/// [Dimension] class. Unit conversion is not implemented in MVP.
@Injectable(as: IUnitService)
class UnitService implements IUnitService {
  @override
  List<MeasurementUnit> getUnitsForDimension(Dimension dimension) {
    return MeasurementUnit.values
        .where((unit) => unit.measurementDimension.dimension == dimension)
        .toList();
  }

  @override
  bool isValidUnitForDimension(MeasurementUnit unit, Dimension dimension) {
    return unit.measurementDimension.dimension == dimension;
  }

  @override
  String format(double value, MeasurementUnit unit) {
    // Format number with appropriate precision
    final String formattedValue;
    if (value == value.roundToDouble()) {
      // Whole number
      formattedValue = value.toInt().toString();
    } else if (value.abs() >= 100) {
      // Large number - no decimals
      formattedValue = value.round().toString();
    } else if (value.abs() >= 10) {
      // Medium number - 1 decimal
      formattedValue = value.toStringAsFixed(1);
    } else if (value.abs() >= 1) {
      // Small number - 2 decimals
      formattedValue = value.toStringAsFixed(2);
    } else {
      // Very small number - 3 decimals
      formattedValue = value.toStringAsFixed(3);
    }

    return '$formattedValue ${unit.displayName}';
  }

  @override
  Dimension getDimension(MeasurementUnit unit) {
    return unit.measurementDimension.dimension;
  }

  @override
  bool areCompatible(MeasurementUnit unit1, MeasurementUnit unit2) {
    return unit1.measurementDimension == unit2.measurementDimension;
  }
}
