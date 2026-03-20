/// Defines the master list of input types available when building tracker templates.
/// 
/// Each enum value corresponds to a specific input widget type and validation rules.
enum FieldEnum {
  /// Whole number input (e.g., 1, 2, 3)
  integer,
  
  /// Decimal number input (e.g., 1.5, 2.7, 3.14)
  float,
  
  /// Text string input (e.g., notes, descriptions)
  text,
  
  /// True/false checkbox or toggle input
  boolean,
  
  /// Date and time picker input
  datetime,
  
  /// Selection from predefined options (dropdown/radio buttons)
  enumerated,
  
  /// Physical measurement with units (requires MeasurementUnit)
  dimension,
  
  /// Reference to another tracker template entry
  reference,

  /// GPS location (latitude/longitude captured on tap)
  location,

  /// Structured group of sub-fields (JSON object)
  group,
}