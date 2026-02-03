/// Defines the physical measurement concepts available for dimension fields.
/// 
/// Each dimension type restricts which units can be used for that field.
enum DimensionEnum {
  /// Weight or mass measurements (kg, lbs, grams, etc.)
  mass,
  
  /// Distance or length measurements (meters, feet, inches, etc.)
  length,
  
  /// Volume or capacity measurements (liters, gallons, etc.)
  volume,
  
  /// Time duration measurements (seconds, minutes, hours, etc.)
  time,
}