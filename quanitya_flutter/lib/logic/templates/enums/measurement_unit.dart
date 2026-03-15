import 'measurement_dimension.dart';

/// Concrete measurement units, each linked to a [MeasurementDimension].
///
/// Full derivation chain:
/// ```
/// MeasurementUnit.kilograms
///   -> .measurementDimension -> MeasurementDimension.mass
///     -> .dimension -> Dimension.M (SI math)
/// ```
///
/// Conversion stubs ([toBase]/[fromBase]) return identity for now.
/// When conversion is needed, implement factors per unit
/// or wire to the `units_converter` package behind [IMeasurementService].
enum MeasurementUnit {
  // -- Mass -------------------------------------------------------------------
  kilograms(MeasurementDimension.mass, 'kg', 'Kilograms'),
  pounds(MeasurementDimension.mass, 'lbs', 'Pounds'),
  grams(MeasurementDimension.mass, 'g', 'Grams'),
  ounces(MeasurementDimension.mass, 'oz', 'Ounces'),
  stones(MeasurementDimension.mass, 'st', 'Stones'),
  tons(MeasurementDimension.mass, 't', 'Tons'),

  // -- Length -----------------------------------------------------------------
  meters(MeasurementDimension.length, 'm', 'Meters'),
  feet(MeasurementDimension.length, 'ft', 'Feet'),
  inches(MeasurementDimension.length, 'in', 'Inches'),
  centimeters(MeasurementDimension.length, 'cm', 'Centimeters'),
  millimeters(MeasurementDimension.length, 'mm', 'Millimeters'),
  kilometers(MeasurementDimension.length, 'km', 'Kilometers'),
  miles(MeasurementDimension.length, 'mi', 'Miles'),
  yards(MeasurementDimension.length, 'yd', 'Yards'),

  // -- Volume -----------------------------------------------------------------
  liters(MeasurementDimension.volume, 'L', 'Liters'),
  gallons(MeasurementDimension.volume, 'gal', 'Gallons'),
  milliliters(MeasurementDimension.volume, 'mL', 'Milliliters'),
  fluidOunces(MeasurementDimension.volume, 'fl oz', 'Fluid Ounces'),
  cups(MeasurementDimension.volume, 'cup', 'Cups'),
  pints(MeasurementDimension.volume, 'pt', 'Pints'),
  quarts(MeasurementDimension.volume, 'qt', 'Quarts'),

  // -- Time -------------------------------------------------------------------
  seconds(MeasurementDimension.time, 's', 'Seconds'),
  minutes(MeasurementDimension.time, 'min', 'Minutes'),
  hours(MeasurementDimension.time, 'h', 'Hours'),
  days(MeasurementDimension.time, 'd', 'Days'),
  weeks(MeasurementDimension.time, 'wk', 'Weeks'),
  months(MeasurementDimension.time, 'mo', 'Months'),
  years(MeasurementDimension.time, 'yr', 'Years');

  const MeasurementUnit(
    this.measurementDimension,
    this.displayName,
    this.fullName,
  );

  /// The measurement dimension this unit belongs to.
  final MeasurementDimension measurementDimension;

  /// Short display symbol (e.g., 'kg', 'lbs', 'm').
  final String displayName;

  /// Full human-readable name (e.g., 'Kilograms', 'Pounds', 'Meters').
  final String fullName;

  /// Converts a value in this unit to the base unit of its dimension.
  /// Stub — returns value unchanged.
  num toBase(num value) => value;

  /// Converts a value from the base unit of its dimension to this unit.
  /// Stub — returns value unchanged.
  num fromBase(num value) => value;

  /// Returns all units belonging to the given [MeasurementDimension].
  static List<MeasurementUnit> unitsFor(MeasurementDimension dimension) {
    return values.where((u) => u.measurementDimension == dimension).toList();
  }
}
