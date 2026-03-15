import '../models/dimension.dart';

/// Curated whitelist of measurement dimensions available for template fields.
///
/// Each value carries its SI [Dimension] for mathematical operations.
/// This is a UX gate — it controls which dimensions users can select,
/// while [Dimension] defines what's physically possible.
///
/// To add a new dimension (e.g., temperature):
/// 1. Add enum value here with its SI Dimension
/// 2. Add corresponding units to MeasurementUnit
/// 3. Units and conversion come for free from the math layer
enum MeasurementDimension {
  /// Weight or mass measurements (kg, lbs, grams, etc.)
  mass(Dimension.M),

  /// Distance or length measurements (meters, feet, inches, etc.)
  length(Dimension.L),

  /// Volume or capacity measurements (liters, gallons, etc.)
  volume(Dimension.volume),

  /// Time duration measurements (seconds, minutes, hours, etc.)
  time(Dimension.T);

  const MeasurementDimension(this.dimension);

  /// The SI dimensional analysis representation.
  final Dimension dimension;
}
