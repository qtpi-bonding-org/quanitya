import 'package:injectable/injectable.dart';

import '../../logic/templates/enums/unit_enum.dart';
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
  List<UnitEnum> getUnitsForDimension(Dimension dimension);

  /// Validates that a unit belongs to the specified SI dimension.
  ///
  /// Returns true if the unit's dimension matches the expected dimension.
  ///
  /// Example:
  /// ```dart
  /// isValidUnitForDimension(UnitEnum.kilograms, Dimension.M) // true
  /// isValidUnitForDimension(UnitEnum.meters, Dimension.M)    // false
  /// isValidUnitForDimension(UnitEnum.liters, Dimension.volume) // true
  /// ```
  bool isValidUnitForDimension(UnitEnum unit, Dimension dimension);

  /// Formats a value with its unit as a human-readable string.
  ///
  /// Example: format(100.5, UnitEnum.kilograms) returns "100.5 kg"
  String format(double value, UnitEnum unit);

  /// Returns the SI dimension for a given unit.
  ///
  /// Example: getDimension(UnitEnum.meters) returns Dimension.L
  Dimension getDimension(UnitEnum unit);

  /// Checks if two units are dimensionally compatible (can be converted).
  ///
  /// Example:
  /// ```dart
  /// areCompatible(UnitEnum.kilograms, UnitEnum.pounds) // true (both M¹)
  /// areCompatible(UnitEnum.meters, UnitEnum.feet)      // true (both L¹)
  /// areCompatible(UnitEnum.kilograms, UnitEnum.meters) // false
  /// ```
  bool areCompatible(UnitEnum unit1, UnitEnum unit2);
}

/// Concrete implementation of IUnitService.
///
/// Provides dimensional analysis and unit validation using the SI-based
/// [Dimension] class. Unit conversion is not implemented in MVP.
@Injectable(as: IUnitService)
class UnitService implements IUnitService {
  @override
  List<UnitEnum> getUnitsForDimension(Dimension dimension) {
    return UnitEnum.values
        .where((unit) => unit.siDimension == dimension)
        .toList();
  }

  @override
  bool isValidUnitForDimension(UnitEnum unit, Dimension dimension) {
    return unit.siDimension == dimension;
  }

  @override
  String format(double value, UnitEnum unit) {
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
  Dimension getDimension(UnitEnum unit) {
    return unit.siDimension;
  }

  @override
  bool areCompatible(UnitEnum unit1, UnitEnum unit2) {
    return unit1.siDimension == unit2.siDimension;
  }
}
