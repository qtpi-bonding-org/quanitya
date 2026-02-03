import '../models/dimension.dart';
import 'dimension_enum.dart';

/// Defines all available measurement units organized by dimension type.
///
/// Each unit belongs to a specific dimension and can be used for conversion
/// and validation within that dimension category.
enum UnitEnum {
  // Mass/Weight Units
  /// Kilograms (metric base unit for mass)
  kilograms,

  /// Pounds (imperial weight unit)
  pounds,

  /// Grams (metric small mass unit)
  grams,

  /// Ounces (imperial small weight unit)
  ounces,

  /// Stones (imperial weight unit, primarily UK)
  stones,

  /// Tons (metric large mass unit)
  tons,

  // Length/Distance Units
  /// Meters (metric base unit for length)
  meters,

  /// Feet (imperial length unit)
  feet,

  /// Inches (imperial small length unit)
  inches,

  /// Centimeters (metric small length unit)
  centimeters,

  /// Millimeters (metric very small length unit)
  millimeters,

  /// Kilometers (metric large distance unit)
  kilometers,

  /// Miles (imperial large distance unit)
  miles,

  /// Yards (imperial medium length unit)
  yards,

  // Volume/Capacity Units
  /// Liters (metric base unit for volume)
  liters,

  /// Gallons (imperial volume unit)
  gallons,

  /// Milliliters (metric small volume unit)
  milliliters,

  /// Fluid ounces (imperial small volume unit)
  fluidOunces,

  /// Cups (cooking measurement unit)
  cups,

  /// Pints (imperial medium volume unit)
  pints,

  /// Quarts (imperial medium volume unit)
  quarts,

  // Time/Duration Units
  /// Seconds (base unit for time)
  seconds,

  /// Minutes (60 seconds)
  minutes,

  /// Hours (60 minutes)
  hours,

  /// Days (24 hours)
  days,

  /// Weeks (7 days)
  weeks,

  /// Months (approximate 30 days)
  months,

  /// Years (365 days)
  years,
}

/// Extension to get the dimension category for each unit
extension UnitEnumExtension on UnitEnum {
  /// Returns the SI dimension for this unit.
  ///
  /// This is the proper dimensional analysis representation using
  /// SI base dimensions (L, M, T, etc.).
  Dimension get siDimension {
    switch (this) {
      // Mass units → M¹
      case UnitEnum.kilograms:
      case UnitEnum.pounds:
      case UnitEnum.grams:
      case UnitEnum.ounces:
      case UnitEnum.stones:
      case UnitEnum.tons:
        return Dimension.M;

      // Length units → L¹
      case UnitEnum.meters:
      case UnitEnum.feet:
      case UnitEnum.inches:
      case UnitEnum.centimeters:
      case UnitEnum.millimeters:
      case UnitEnum.kilometers:
      case UnitEnum.miles:
      case UnitEnum.yards:
        return Dimension.L;

      // Volume units → L³
      case UnitEnum.liters:
      case UnitEnum.gallons:
      case UnitEnum.milliliters:
      case UnitEnum.fluidOunces:
      case UnitEnum.cups:
      case UnitEnum.pints:
      case UnitEnum.quarts:
        return Dimension.volume;

      // Time units → T¹
      case UnitEnum.seconds:
      case UnitEnum.minutes:
      case UnitEnum.hours:
      case UnitEnum.days:
      case UnitEnum.weeks:
      case UnitEnum.months:
      case UnitEnum.years:
        return Dimension.T;
    }
  }

  /// Returns a human-readable display name for the unit
  String get displayName {
    switch (this) {
      // Mass units
      case UnitEnum.kilograms:
        return 'kg';
      case UnitEnum.pounds:
        return 'lbs';
      case UnitEnum.grams:
        return 'g';
      case UnitEnum.ounces:
        return 'oz';
      case UnitEnum.stones:
        return 'st';
      case UnitEnum.tons:
        return 't';

      // Length units
      case UnitEnum.meters:
        return 'm';
      case UnitEnum.feet:
        return 'ft';
      case UnitEnum.inches:
        return 'in';
      case UnitEnum.centimeters:
        return 'cm';
      case UnitEnum.millimeters:
        return 'mm';
      case UnitEnum.kilometers:
        return 'km';
      case UnitEnum.miles:
        return 'mi';
      case UnitEnum.yards:
        return 'yd';

      // Volume units
      case UnitEnum.liters:
        return 'L';
      case UnitEnum.gallons:
        return 'gal';
      case UnitEnum.milliliters:
        return 'mL';
      case UnitEnum.fluidOunces:
        return 'fl oz';
      case UnitEnum.cups:
        return 'cup';
      case UnitEnum.pints:
        return 'pt';
      case UnitEnum.quarts:
        return 'qt';

      // Time units
      case UnitEnum.seconds:
        return 's';
      case UnitEnum.minutes:
        return 'min';
      case UnitEnum.hours:
        return 'h';
      case UnitEnum.days:
        return 'd';
      case UnitEnum.weeks:
        return 'wk';
      case UnitEnum.months:
        return 'mo';
      case UnitEnum.years:
        return 'yr';
    }
  }

  /// Returns the full name of the unit
  String get fullName {
    switch (this) {
      // Mass units
      case UnitEnum.kilograms:
        return 'Kilograms';
      case UnitEnum.pounds:
        return 'Pounds';
      case UnitEnum.grams:
        return 'Grams';
      case UnitEnum.ounces:
        return 'Ounces';
      case UnitEnum.stones:
        return 'Stones';
      case UnitEnum.tons:
        return 'Tons';

      // Length units
      case UnitEnum.meters:
        return 'Meters';
      case UnitEnum.feet:
        return 'Feet';
      case UnitEnum.inches:
        return 'Inches';
      case UnitEnum.centimeters:
        return 'Centimeters';
      case UnitEnum.millimeters:
        return 'Millimeters';
      case UnitEnum.kilometers:
        return 'Kilometers';
      case UnitEnum.miles:
        return 'Miles';
      case UnitEnum.yards:
        return 'Yards';

      // Volume units
      case UnitEnum.liters:
        return 'Liters';
      case UnitEnum.gallons:
        return 'Gallons';
      case UnitEnum.milliliters:
        return 'Milliliters';
      case UnitEnum.fluidOunces:
        return 'Fluid Ounces';
      case UnitEnum.cups:
        return 'Cups';
      case UnitEnum.pints:
        return 'Pints';
      case UnitEnum.quarts:
        return 'Quarts';

      // Time units
      case UnitEnum.seconds:
        return 'Seconds';
      case UnitEnum.minutes:
        return 'Minutes';
      case UnitEnum.hours:
        return 'Hours';
      case UnitEnum.days:
        return 'Days';
      case UnitEnum.weeks:
        return 'Weeks';
      case UnitEnum.months:
        return 'Months';
      case UnitEnum.years:
        return 'Years';
    }
  }
}

/// Utility class to get units by dimension
class UnitsByDimension {
  /// Returns all units that belong to the specified dimension
  static List<UnitEnum> getUnitsForDimension(DimensionEnum dimension) {
    return UnitEnum.values
        .where((unit) => _dimensionEnumFor(unit) == dimension)
        .toList();
  }

  /// Maps a unit's siDimension to the legacy DimensionEnum
  static DimensionEnum _dimensionEnumFor(UnitEnum unit) {
    final siDim = unit.siDimension;
    if (siDim == Dimension.M) return DimensionEnum.mass;
    if (siDim == Dimension.L) return DimensionEnum.length;
    if (siDim == Dimension.volume) return DimensionEnum.volume;
    if (siDim == Dimension.T) return DimensionEnum.time;
    // Default fallback (shouldn't happen with current units)
    return DimensionEnum.mass;
  }

  /// Returns all mass units
  static List<UnitEnum> get massUnits =>
      getUnitsForDimension(DimensionEnum.mass);

  /// Returns all length units
  static List<UnitEnum> get lengthUnits =>
      getUnitsForDimension(DimensionEnum.length);

  /// Returns all volume units
  static List<UnitEnum> get volumeUnits =>
      getUnitsForDimension(DimensionEnum.volume);

  /// Returns all time units
  static List<UnitEnum> get timeUnits =>
      getUnitsForDimension(DimensionEnum.time);
}
